# Git annex

The biggest limitation of git compared to some older centralized version control systems has been the maximum size of the repositories.
The general recommendation is to not have git repositories larger than 1GB to preserve performance.
Although GitLab has no limit (some repositories in GitLab are over 50GB!) we subscribe to the advise to keep repositories as small as you can.

Not being able to version control large binaries is a big problem for many larger organizations.
Video, photo's, audio, compiled binaries and many other types of files are too large.
As a workaround, people keep artwork-in-progress in a Dropbox folder and only check in the final result.
This results in using outdated files, not having a complete history and the risk of losing work.

This problem is solved by integrating the awesome [git-annex](https://git-annex.branchable.com/).
Git-annex allows managing large binaries with git, without checking the contents into git.
You check in only a symlink that contains the SHA-1 of the large binary.
If you need the large binary you can sync it from the GitLab server over rsync, a very fast file copying tool.

<!-- more -->

## Using GitLab Annex

For example, if you want to upload a very large file and check it into your Git repository:

```bash
git clone git@gitlab.example.com:group/project.git
git annex init 'My Laptop'            # initialize the annex project
cp ~/tmp/debian.iso ./                # copy a large file into the current directory
git annex add .                       # add the large file to git annex
git commit -am"Added Debian iso"      # commit the file meta data
git annex sync --content              # sync the git repo and large file to the GitLab server
```

Downloading a single large file is also very simple:

```bash
git clone git@gitlab.example.com:group/project.git
git annex sync                        # sync git branches but not the large file
git annex get debian.iso              # download the large file
```

To download all files:

```bash
git clone git@gitlab.example.com:group/project.git
git annex sync --content              # sync git branches and download all the large files
```

You don't have to setup git-annex on a separate server or add annex remotes to the repository.
Git-annex without GitLab gives everyone that can access the server access to the files of all projects.
GitLab annex ensures you can only acces files of projects you work on (developer, master or owner role).

## How it works

Internally GitLab uses [GitLab Shell](https://gitlab.com/gitlab-org/gitlab-shell) to handle ssh access and this was a great integration point for git-annex.
We've added a setting to GitLab Shell so you can disable GitLab Annex support if you don't want it.

You'll have to use ssh style links for to git remote to your GitLab server instead of https style links.
