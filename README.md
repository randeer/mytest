
## 1. Git Overview

<p>Git is a distributed version control system used to track changes in source code and enable multiple developers to collaborate on the same project safely.
Instead of storing files directly, Git records snapshots of changes over time. This allows developers to review history, revert changes, and work on new features without affecting the main project.</p>

#### Key Concepts
**Repository (Repo)**
A repository is a project tracked by Git. It contains the project files and the full history of changes.

**Local Repository**
The copy of the repository stored on a developer’s computer. Developers make changes, commits, and branches locally before sharing them.

**Remote Repository**
A repository hosted on a server (such as Bitbucket or GitHub) that allows teams to share and collaborate on code.

**Commit**
A commit records a snapshot of changes in the repository. Each commit has a unique ID and includes information about what was changed.

**Branch**
A branch is an independent line of development. Developers create branches to work on features or bug fixes without affecting the main branch.

**Clone**
Cloning creates a copy of a remote repository on a local machine so developers can start working on the project.

**Pull**
Pulling retrieves the latest changes from the remote repository and updates the local repository.

**Push**
Pushing sends local commits to the remote repository so other team members can access them.

## 2. Git Workflow
This section describes the standard workflow developers should follow when working with Git.
The example below uses a sample repository called sample-app.

**1. Clone the Repository**
Cloning creates a local copy of the remote repository.

*Command:*
```bash
`git clone https://github.com/example/sample-app.git`
```

*Example Output:*
```bash
Cloning into 'sample-app'...
remote: Enumerating objects: 25, done.
remote: Counting objects: 100% (25/25), done.
Receiving objects: 100% (25/25), done.
Resolving deltas: 100% (8/8), done.
```
