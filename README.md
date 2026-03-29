2. 🔑 Setting Up GitHub Access
2.1 Generate SSH Key
Run the following command in Git Bash / Terminal:
ssh-keygen -t ed25519 -C "your_email@example.com"
👉 When prompted:
Press Enter to accept default file location
Optionally set a passphrase (recommended)

2.2 Add SSH Key to SSH Agent
Start the SSH agent:
eval "$(ssh-agent -s)"
Add your SSH private key:
ssh-add ~/.ssh/id_ed25519

2.3 Add SSH Key to GitHub
Copy your public key:
cat ~/.ssh/id_ed25519.pub
Go to GitHub:
Click your profile → Settings
Navigate to SSH and GPG keys
Click New SSH key
Fill in:
Title: (e.g., Work Laptop)
Key: Paste the copied key
Click Add SSH key

2.4 Test SSH Connection
Run:
ssh -T git@github.com
👉 Expected output:
Hi username! You've successfully authenticated...

2.5 Configure Git (Required)
Set your identity:
git config --global user.name "Your Name"
git config --global user.email "your_email@example.com"
Check config:
git config --list

----------------------------------------------------------
🔐 Clone a Repository

Option 1: Clone using SSH (Recommended)
What this does:
Uses your SSH key to securely connect without entering credentials every time.

Command:
git clone git@github.com:intcx/ICELOGS-LOGSMOVER.logsmover.git


Option 2: Clone using HTTPS
What this does:
Downloads the repo using a URL. You will need to authenticate.

GitHub requires secure login when using HTTPS.
Enter your GitHub username
Use a Personal Access Token (PAT) instead of password

Command:
git clone https://github.com/intcx/ICELOGS-LOGSMOVER.logsmover.git


🔑 How to Create a Personal Access Token (PAT)

1) Go to GitHub Settings
Log in to GitHub
Click your profile icon (top right)
Select Settings

2) Open Developer Settings
Scroll down (left sidebar)
Click Developer settings

3) Select Personal Access Tokens
Click Personal access tokens
Choose:
Tokens (classic) (most commonly used)

4) Generate New Token
Click Generate new token (classic)
5) Configure the Token

Fill in:
Note → e.g. Git access token
Expiration → choose (e.g. 30 or 90 days)
Scopes → select:
✅ repo (for private repositories)
✅ read:org (optional, if needed)

6) Generate & Copy Token
Click Generate token
⚠️ IMPORTANT: Copy it immediately
(You won’t see it again!)

If you don’t want to enter PAT every time:
git config --global credential.helper store


📂 After Cloning
Navigate into the repository

What this does:
Moves you into the project folder so you can start working.
cd ICELOGS-LOGSMOVER.logsmover

✅ Verify Repository
Check remote connection

What this does:
Confirms your local repo is linked to the correct remote repository.
git remote -v
--------------------------------------------------------

🔄 4. Working with Repositories (ICELOGS-LOGSMOVER)

This section explains how to create branches, make changes, and merge code using our standard workflow.

Repository: intcx/ICELOGS-LOGSMOVER.logsmover

🌿 4.1 Branch Creation and Naming

👉 Always create a new branch before making changes
❌ Do NOT work directly on master/main

Step 1: Get Latest Code
What this does: Ensures your branch is based on the latest version

git checkout master
git pull origin master

Step 2: Create a New Branch
What this does: Creates an isolated workspace for your changes

git checkout -b TKT12345678

✅ Naming Convention;
Ticket number is mandatory
Description is optional but recommended for clarity
Use ticket-based naming:

TKT12345678_log_cleanup_update
TKT59198868_fix_auth_issue
TKT62660039_env_changes

✏️ 4.2 Making Changes and Commits
Step 1: Check Changes
What this does: Shows modified and new files
git status

Step 2: Stage Files
What this does: Prepares files for commit
git add .

Step 3: Commit Changes
What this does: Saves a snapshot of your changes
git commit -m "Update log cleanup script for environment handling"

🚀 4.3 Push Code to Remote
What this does: Uploads your branch to remote repository
git push origin TKT12345678

👉 First time only:
git push -u origin TKT12345678

🔁 4.4 Create Pull Request (PR)
👉 All changes must go through PR (no direct push to master)

Steps:
Go to GitHub or Bitbucket
Click Create Pull Request

Select:
Source branch: TKT12345678 (Ticket No)
Target branch: master

Optional
Add:
Title: Short summary
Description: What was changed and why
Reviewers: Team lead / peers

🔐 4.5 Pull Request (PR) Review Process
What this does: Ensures all changes are reviewed and approved before merging into master

👥 Step 1: Assign Reviewers
Add reviewers in GitHub or Bitbucket
Typically: Team lead or peers
💬 Step 2: Address Review Comments

If reviewers request changes:

What this does: Updates your existing branch with fixes

git status
git add .
git commit -m "Fix review comments for log cleanup script"
git push

👉 No need to create a new PR
👉 PR updates automatically after push

🔄 (Optional but Recommended) Sync with Latest Master
What this does: Reduces chances of merge conflicts

git fetch origin
git pull origin master

🔀 4.6 Merge Changes
What this does: Merges your approved changes into master

✅ Recommended: Squash and Merge (UI)
Combines all commits into one clean commit
Keeps history simple
👉 Done via GitHub / Bitbucket UI

🖥️ (Optional) Merge via Command Line
If needed (advanced / fallback):

Step 1: Switch to master
git checkout master

Step 2: Pull latest changes
git pull origin master

Step 3: Merge your branch
git merge TKT12345678

Other Merge Options
Rebase
git checkout TKT12345678
git rebase master

🧹 After Merge (Clean Up)
Delete Local Branch

What this does: Removes branch from your machine
git branch -d TKT12345678

👉 If not merged (force delete):
git branch -D TKT12345678

Delete Remote Branch
What this does: Removes branch from remote repository

git push origin --delete TKT12345678

Clean Up Local References
What this does: Removes deleted remote branches from local list
git fetch --prune

🔄 4.7 Sync Local Repository After Merge
What this does: Updates your local repo with latest changes

Step 1: Switch to Master
git checkout master

Step 2: Pull Latest Changes
git pull origin master
-------------------------------------------------------------

5. 🛠️ Common Issues
5.1 SSH key errors (permission denied)
Happens when your SSH key is missing or not added to your account.
Add the key to your Git hosting account, then test

5.2 Authentication issues (HTTPS/token)
Happens when your credentials or token are wrong or expired.
git config --global credential.helper store
Then try pushing again and enter your username + token.

or reset credentials
git credential reject https://github.com

or use SSH instead
git remote set-url origin git@github.com:username/repo.git

5.3 Merge conflicts
Happens when Git can’t automatically combine changes.
🔁 Using Rebase for Merge Conflicts
git pull --rebase origin main

⚠️ If Conflicts Happen During Rebase
Git will pause and ask you to fix them.
Then Fix the conflicted files manually like below;
git add .
git rebase --continue
If more conflicts appear, repeat the steps

If You Want to Cancel Rebase
git rebase --abort

5.4 Branch issues
Happens when switching, creating, or tracking branches incorrectly.


5.5 Sync issues (pull/push errors)
Happens when your local repo is behind or out of sync.
git pull origin main --rebase
Then push:
git push origin main
If push is rejected:
git push --force
⚠️ Use force push carefully (can overwrite history).
-------------------------------------------------------------

6. 📏 Best Practices & Policies
Branching rules (no direct commits to main)
Commit message standards
Pull request guidelines
Security practices (no secrets in code)
Repository naming conventions



