#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# CONFIG
GROUP_NAME="nfs-hr"
GROUP_GID="1050"
USERS=("hr1" "hr2" "hr3")
SHARE_DB="/srv/db"
SHARE_HR="/srv/hr"
CLIENT_NET="192.168.4.0/22"
EXPORTS_FILE="/etc/exports"
BACKUP_DIR="/root/nfs-setup-backups"
DATESTAMP="$(date +%Y%m%d-%H%M%S)"
NFS_SERVICE="nfs-server"

# Ensure running as root
if [ "$EUID" -ne 0 ]; then
  echo "ERROR: This script must be run as root."
  exit 1
fi

mkdir -p "$BACKUP_DIR"

# 1) Create group if missing
if getent group "$GROUP_NAME" >/dev/null; then
  echo "Group $GROUP_NAME already exists: $(getent group "$GROUP_NAME")"
else
  echo "Creating group $GROUP_NAME with GID $GROUP_GID..."
  groupadd -g "$GROUP_GID" "$GROUP_NAME"
  echo "Created group $GROUP_NAME."
fi

# 2) Create users and add to group
for u in "${USERS[@]}"; do
  if id -u "$u" >/dev/null 2>&1; then
    echo "User $u exists — adding to group $GROUP_NAME if not already a member..."
    usermod -a -G "$GROUP_NAME" "$u" || true
  else
    echo "Creating user $u and adding to group $GROUP_NAME..."
    # create home dir (-m) and primary group defaults to user's own group; we add to nfs group as supplementary
    useradd -m -G "$GROUP_NAME" "$u"
    # set a locked password by default (admin can set actual password)
    passwd -l "$u" >/dev/null 2>&1 || true
  fi
  echo "Members of $u: $(id -nG "$u")"
done

# 3) Create share directories
for d in "$SHARE_DB" "$SHARE_HR"; do
  if [ -d "$d" ]; then
    echo "Directory $d already exists."
  else
    echo "Creating directory $d..."
    mkdir -p "$d"
  fi
done

# 4) Set ownership & perms for share1 (/srv/db) to root:nfs-hr and chmod 2775
echo "Setting ownership and permissions for $SHARE_DB..."
chown root:"$GROUP_NAME" "$SHARE_DB"
chmod 2775 "$SHARE_DB"
echo " -> $(stat -c '%U:%G %a' "$SHARE_DB")"

# For /srv/hr we will leave as root:root with default perms 0755 unless you want otherwise
if [ ! -e "${SHARE_HR}" ]; then
  # already created above, but ensure perms:
  chmod 0755 "$SHARE_HR"
  chown root:root "$SHARE_HR"
fi
echo " -> $(stat -c '%U:%G %a' "$SHARE_HR")"

# 5) Backup /etc/exports then ensure export lines exist (idempotent)
EXPORT_LINE_DB="$SHARE_DB $CLIENT_NET(rw,sync,no_subtree_check)"
EXPORT_LINE_HR="$SHARE_HR $CLIENT_NET(rw,sync,no_subtree_check)"
BACKUP_FILE="$BACKUP_DIR/exports.bak.$DATESTAMP"

if [ -f "$EXPORTS_FILE" ]; then
  echo "Backing up $EXPORTS_FILE -> $BACKUP_FILE"
  cp -a "$EXPORTS_FILE" "$BACKUP_FILE"
else
  echo "No existing $EXPORTS_FILE file found — will create a new one."
  touch "$EXPORTS_FILE"
  chmod 0644 "$EXPORTS_FILE"
fi

# Append lines only if they don't already exist (exact string match)
if grep -Fxq "$EXPORT_LINE_DB" "$EXPORTS_FILE"; then
  echo "Export entry for $SHARE_DB already present in $EXPORTS_FILE"
else
  echo "Adding export entry for $SHARE_DB"
  echo "$EXPORT_LINE_DB" >> "$EXPORTS_FILE"
fi

if grep -Fxq "$EXPORT_LINE_HR" "$EXPORTS_FILE"; then
  echo "Export entry for $SHARE_HR already present in $EXPORTS_FILE"
else
  echo "Adding export entry for $SHARE_HR"
  echo "$EXPORT_LINE_HR" >> "$EXPORTS_FILE"
fi

echo "Current $EXPORTS_FILE contents:"
cat "$EXPORTS_FILE"

# 6) If SELinux is enabled, try to set correct file context (best-effort)
if command -v getenforce >/dev/null 2>&1 && [ "$(getenforce)" != "Disabled" ]; then
  echo "SELinux is enabled ($(getenforce)). Attempting to label exports for NFS (best-effort)..."
  if command -v semanage >/dev/null 2>&1; then
    semanage fcontext -a -t nfsd_anon_t "$SHARE_DB(/.*)?" || true
    semanage fcontext -a -t nfsd_anon_t "$SHARE_HR(/.*)?" || true
    restorecon -Rv "$SHARE_DB" "$SHARE_HR" || true
    echo "SELinux file contexts updated for NFS shares."
  else
    echo "semanage not installed — skipping semanage steps. If SELinux is enforced, consider installing policycoreutils-python-utils and using semanage to set nfs contexts, or run: semanage fcontext -a -t nfsd_anon_t '/srv/db(/.*)?' ; restorecon -Rv /srv/db"
  fi
else
  echo "SELinux disabled or not present; skipping SELinux labeling."
fi

# 7) Ensure required services are running & enabled
echo "Enabling and starting NFS services..."
# enable & start rpcbind (if present) and nfs-server
if systemctl list-unit-files | grep -q '^rpcbind'; then
  systemctl enable --now rpcbind || true
fi

systemctl enable --now "$NFS_SERVICE" || {
  echo "Failed to enable/start $NFS_SERVICE — check your system's NFS service name and logs."
  exit 1
}

# Export the shares immediately
echo "Exporting and refreshing NFS exports..."
exportfs -rav

echo "NFS export list:"
exportfs -v

# Optional: suggest firewall commands (uncomment to execute)
# echo "If running firewalld, you may need to allow NFS traffic. Example commands (uncomment to run):"
# firewall-cmd --permanent --add-service=nfs
# firewall-cmd --permanent --add-service=rpc-bind
# firewall-cmd --permanent --add-service=mountd
# firewall-cmd --reload

echo "Done. /srv/db and /srv/hr are exported to ${CLIENT_NET}."
echo "Check client(s) by running on a client: showmount -e <server1-ip> or mount the share."
