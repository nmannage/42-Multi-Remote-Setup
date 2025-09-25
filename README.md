# 42-Multi-Remote-Setup
    ======================================== __  4   __      
       42-Multi-Remote-Setup                ( _\    /_ )     
             nmannage                        \ _\  /_ /      
    ========================================  \ _\/_ /_ _   
      TLDR: Push to both 42 vogsphere         |____/_/ /|     
      and Github retaining 	  	             (  (_)__)J-)    
      authorship of each one.                (  /`.,   /      
                                              \/  ;   /        
    ========================================    | === | 

----

This setup lets you push the same code to two different git repositories with different commit authors. Your original commits stay unchanged while GitHub gets commits with your GitHub identity.
What it does

    Keeps your original repository completely untouched
    Creates a separate copy for GitHub with rewritten commit authors
    Provides simple scripts to push to both remotes

## Setup

Download file
```
curl -o fix-and-setup.sh https://raw.githubusercontent.com/nmannage/42-Multi-Remote-Setup/refs/heads/main/fix-and-setup.sh
```

1. Configure your details

Edit fix-and-setup.sh and update these three lines at the top:

```bash

GITHUB_USER_NAME="Your GitHub Name"
GITHUB_USER_EMAIL="your-github@email.com"
GITHUB_REPO_URL="git@github.com:yourusername/yourrepo.git" 
```
> [!IMPORTANT]  
> The repo URL here uses SSH. You might need to setup your machine as seen [here](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/adding-a-new-ssh-key-to-your-github-account).

Also edit `sync-to-github-safe.sh` and update the same values:

```bash

GITHUB_USER_NAME="Your GitHub Name"
GITHUB_USER_EMAIL="your-github@email.com"
```

2. Run the setup

In your original repository folder, run:

```bash

chmod +x fix-and-setup.sh
./fix-and-setup.sh
```

This creates a GitHub copy of your repo in a folder next to your current one (named yourrepo-github).

----

### Daily usage

After making commits in your original repo:

```bash

git add .
git commit -m "your message"
./push-all.sh
```

This pushes to both remotes automatically.
How it works

Your folder structure will look like this:

```
parent-folder/
├── your-repo/          (original, unchanged)
│   ├── fix-and-setup.sh
│   ├── sync-to-github-safe.sh
│   ├── push-all.sh
│   └── your code files
└── your-repo-github/   (GitHub copy with rewritten authors)
    └── your code files
```

The original repo keeps your original commit history. The GitHub copy has the same code but with GitHub user as the author of all commits.
Troubleshooting

If sync fails, just run the setup script again:

```bash

./fix-and-setup.sh
```

This will recreate everything from scratch and force sync both repositories.
Files included


    fix-and-setup.sh - Initial setup and fix script
    sync-to-github-safe.sh - Syncs changes to GitHub copy
    push-all.sh - Created by setup, pushes to both remotes


> [!WARNING]  
> These scripts are provided as-is, with no guarantees.
> The author isn't responsible for any problems, damage, or issues that may happen if you use it.
