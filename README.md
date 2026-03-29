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
