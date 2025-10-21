#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# ---- CONFIG ----
SERVER="${1:-}"                   # e.g. "server1" or "192.168.4.10" (required)
SHARE_PATH="/srv/hr"              # remote path on server1
LOCAL_MOUNT="/mnt/hr-data"        # autofs-mounted path on client
AUTO_MASTER="/etc/auto.master"
AUTO_MAP="/etc/auto.hr"           # direct map file
GROUP_NAME="nfs-hr"
GROUP_GID="1050"
USERS=("hr1" "hr2" "hr3")
# NFS mount options (tweak if you use nfs v3 or want different options)
NFS_OPTS="-fstype=nfs4,rw,soft,intr,vers=4"
BACKUP_DIR="/root/autofs-setup-backups"
DATESTAMP="$(date +%Y%m%d-%H%M%S)"

# ---- sanity ----
if [ -z "$SERVER" ]; then
  echo "Usage: $0 <nfs-server-ip-or-hostname>"
  exit 2
fi

if [ "$EUID" -ne 0 ]; then
  echo "This script must be run as root."
  exit 1
fi

mkdir -p "$BACKUP_DIR"

echo "== Client setup starting for NFS server: $SERVER =="

# ---- 1) Install autofs if missing ----
if ! rpm -q autofs >/dev/null 2>&1; then
  echo "Installing autofs..."
  dnf -y install autofs
else
  echo "autofs already installed."
fi

# ---- 2) Ensure group exists (idempotent) ----
if getent group "$GROUP_NAME" >/dev/null; then
  echo "Group $GROUP_NAME exists: $(getent group "$GROUP_NAME")"
else
  echo "Creating group $GROUP_NAME with GID $GROUP_GID..."
  groupadd -g "$GROUP_GID" "$GROUP_NAME"
fi

# ---- 3) Create users and add hr1,hr2 to group; leave hr3 out ----
for u in "${USERS[@]}"; do
  if id -u "$u" >/dev/null 2>&1; then
    echo "User $u exists."
  else
    echo "Creating user $u..."
    useradd -m -s /bin/bash "$u"
    passwd -l "$u" >/dev/null 2>&1 || true
  fi
done

# add hr1 & hr2 to group (idempotent)
for u in hr1 hr2; do
  if id -nG "$u" | grep -qw "$GROUP_NAME"; then
    echo "$u already in $GROUP_NAME."
  else
    usermod -a -G "$GROUP_NAME" "$u"
    echo "Added $u to $GROUP_NAME"
  fi
done

# ensure hr3 is NOT in group (remove if exists)
if id -nG hr3 | grep -qw "$GROUP_NAME"; then
  gpasswd -d hr3 "$GROUP_NAME" || true
  echo "Removed hr3 from $GROUP_NAME to simulate permission problem."
else
  echo "hr3 is not a member of $GROUP_NAME (as requested)."
fi

# ---- 4) Prepare autofs direct map for /mnt/hr-data ----
# backup auto.master
cp -a "$AUTO_MASTER" "$BACKUP_DIR/auto.master.bak.$DATESTAMP" || true

# Ensure /- entry exists in /etc/auto.master (for direct mounts)
if grep -E "^[[:space:]]*/-([[:space:]]|$)" "$AUTO_MASTER" >/dev/null 2>&1; then
  echo "/- already referenced in $AUTO_MASTER"
else
  echo "Adding direct map '/ - $AUTO_MAP' to $AUTO_MASTER"
  echo "" >> "$AUTO_MASTER"
  echo "# Direct mounts for NFS shares (added by setup-client-autofs.sh $DATESTAMP)" >> "$AUTO_MASTER"
  echo "/-    $AUTO_MAP" >> "$AUTO_MASTER"
fi

# Backup any existing map and create our map
if [ -f "$AUTO_MAP" ]; then
  cp -a "$AUTO_MAP" "$BACKUP_DIR/auto.hr.bak.$DATESTAMP"
fi

# Create/replace auto.hr map (idempotent)
cat > "$AUTO_MAP" <<EOF
# direct map: localpath   mount-options    server:/remote/path
${LOCAL_MOUNT}    ${NFS_OPTS}    ${SERVER}:${SHARE_PATH}
EOF

chmod 0644 "$AUTO_MAP"
echo "Created autofs map $AUTO_MAP -> ${SERVER}:${SHARE_PATH}"

# ensure local dir exists (autofs will manage mount)
mkdir -p "$LOCAL_MOUNT"
chown root:root "$LOCAL_MOUNT"
chmod 0755 "$LOCAL_MOUNT"

# ---- 5) Enable & start autofs ----
systemctl enable --now autofs
echo "autofs enabled and started."

# Give autofs a moment to mount on access (we'll trigger access below)
sleep 1

# ---- 6) Trigger the automount by accessing the path and show mount info ----
echo "Triggering automount of ${LOCAL_MOUNT} (will happen on first access)..."
ls -ld "$LOCAL_MOUNT" || true
# Access to cause autofs to mount:
if [ -e "$LOCAL_MOUNT" ]; then
  # list to cause mount
  ls "$LOCAL_MOUNT" >/dev/null 2>&1 || true
fi

sleep 1
echo ""
echo "Mounts containing ${LOCAL_MOUNT}:"
mount | grep -E "${LOCAL_MOUNT}|${SHARE_PATH}" || echo "(not mounted yet — autofs mounts on access)"

# ---- 7) Diagnostics before tests ----
echo ""
echo "=== Quick diagnostics ==="
echo "showmount -e ${SERVER}:"
if command -v showmount >/dev/null 2>&1; then
  showmount -e "$SERVER" || true
else
  echo "showmount not available on client."
fi

echo ""
echo "rpcinfo -p ${SERVER}:"
rpcinfo -p "$SERVER" 2>/dev/null || true

echo ""
echo "nfsstat -m (client mount info):"
nfsstat -m 2>/dev/null || true

echo ""
echo "ls -ld ${LOCAL_MOUNT}:"
ls -ld "$LOCAL_MOUNT" || true

echo ""
echo "stat of ${LOCAL_MOUNT}:"
stat -c '%n -> %U:%G %a' "$LOCAL_MOUNT" || true

# ---- 8) Automated tests as users ----
echo ""
echo "=== Automated file create/read tests (as hr1, hr2, hr3) ==="

TESTFILE_BASE="autofs_test_${DATESTAMP}"
RESULTS="/tmp/autofs_test_results.${DATESTAMP}.log"
: > "$RESULTS"

# make a file as hr1 (should succeed)
echo "Running tests and logging to $RESULTS"
for u in hr1 hr2 hr3; do
  echo "---- testing as $u ----" | tee -a "$RESULTS"
  # whoami
  su - "$u" -c "id" 2>&1 | tee -a "$RESULTS"
  # attempt to create file
  su - "$u" -c "touch ${LOCAL_MOUNT}/${TESTFILE_BASE}.${u}.txt 2>&1 && echo 'CREATE_OK' || echo 'CREATE_FAIL'" 2>&1 | tee -a "$RESULTS"
  # attempt to list files in mount
  su - "$u" -c "ls -l ${LOCAL_MOUNT} 2>&1 || true" 2>&1 | tee -a "$RESULTS"
  # attempt to read file created by hr1 (if exists)
  if [ -f "${LOCAL_MOUNT}/${TESTFILE_BASE}.hr1.txt" ]; then
    su - "$u" -c "cat ${LOCAL_MOUNT}/${TESTFILE_BASE}.hr1.txt 2>&1 || echo 'CAT_FAIL'" 2>&1 | tee -a "$RESULTS"
  else
    echo "Reference file by hr1 not present yet." | tee -a "$RESULTS"
  fi
  echo "" | tee -a "$RESULTS"
done

echo ""
echo "Tests completed. Result log: $RESULTS"
cat "$RESULTS"

# ---- 9) Post-test checks & common troubleshooting hints (printed for engineer) ----
cat <<'EOF'

================================================================================
COMMON CAUSES & NEXT STEPS (diagnostic guidance printed for engineer)
================================================================================

1) PERMISSIONS on server-side directory:
   - If /srv/hr on server1 is owned root:nfs-hr with mode 2775 (rwxrwsr-x),
     then only owner (root) and members of nfs-hr can write. Non-group users (others)
     will not be able to create files. This is the intended behaviour we simulated.
   - Fix options:
     a) Add hr3 to group:     usermod -a -G nfs-hr hr3
     b) Change permissions:   chmod 2777 /srv/hr   (gives 'others' write - not recommended)
     c) Use ACL to give hr3 write: setfacl -m u:hr3:rwx /srv/hr

2) UID/GID MISMATCH (very common):
   - If hr1/hr2/hr3 have different UID/GIDs between server and client, file ownership may not map as expected.
   - Check server user IDs and client user IDs: on both sides run: id hr1; id hr2; id hr3
   - For NFSv4 ensure idmapd is configured and running (rpc.idmapd) and domain matches.

3) NFS export options:
   - server's /etc/exports may have options that restrict writes (ro) or root-squash behaviors.
   - On server, check /etc/exports and the export options for /srv/hr.

4) SELINUX:
   - If SELinux Enforcing on server or client, wrong file context may block operations.
   - On server: getenforce ; restorecon -Rv /srv/hr ; semanage fcontext ... (as needed)

5) autofs behavior:
   - autofs mounts on access. If a process holds stale handles or permission deny occurs, umount and retry.
   - To force unmount & remount: systemctl restart autofs OR automount -f -v (for debug)

6) Useful commands to run on client/server:
   - On client:
       id hr3
       sudo -u hr3 touch /mnt/hr-data/testfile
       mount | grep hr-data
       showmount -e <server>
       rpcinfo -p <server>
       journalctl -u autofs -f
   - On server:
       ls -ld /srv/hr
       stat -c '%U:%G %a' /srv/hr
       getenforce
       exportfs -v
       journalctl -u nfs-server -f

================================================================================
EOF

echo "Done. If hr3 cannot create/read files the most-likely immediate reason is: hr3 is NOT a member of group 'nfs-hr' while the share allows writes only to owner/group (2775). See the 'COMMON CAUSES' section above for fixes."
