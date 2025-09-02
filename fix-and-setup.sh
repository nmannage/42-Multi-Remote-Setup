#!/bin/bash

# ===== CONFIGURATION - UPDATE THESE =====
GITHUB_USER_NAME="Your GitHub Name"
GITHUB_USER_EMAIL="your-github@email.com"
GITHUB_REPO_URL="git@github.com:yourusername/yourrepo.git"  # Your actual GitHub repo

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Get current info
ORIGINAL_DIR=$(pwd)
REPO_NAME=$(basename "$ORIGINAL_DIR")
GITHUB_COPY_DIR="../${REPO_NAME}-github"
CURRENT_BRANCH=$(git branch --show-current)

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Complete GitHub Sync Setup & Fix${NC}"
echo -e "${BLUE}========================================${NC}\n"

# Step 1: Check/Create GitHub copy
if [ ! -d "$GITHUB_COPY_DIR" ]; then
    echo -e "${YELLOW}GitHub copy not found. Creating it...${NC}"
    
    # Clone current repo to GitHub copy
    echo -e "${GREEN}→ Cloning to $GITHUB_COPY_DIR${NC}"
    cd ..
    git clone "$ORIGINAL_DIR" "${REPO_NAME}-github"
    cd "${REPO_NAME}-github"
    
    # Remove original remote and add GitHub
    git remote remove origin
    git remote add github "$GITHUB_REPO_URL"
    
    # Rewrite all commits on all branches
    echo -e "${GREEN}→ Rewriting commits with GitHub author...${NC}"
    FILTER_BRANCH_SQUELCH_WARNING=1 git filter-branch -f --env-filter "
        export GIT_AUTHOR_NAME='${GITHUB_USER_NAME}'
        export GIT_AUTHOR_EMAIL='${GITHUB_USER_EMAIL}'
        export GIT_COMMITTER_NAME='${GITHUB_USER_NAME}'
        export GIT_COMMITTER_EMAIL='${GITHUB_USER_EMAIL}'
    " -- --all
    
    # Push current branch to GitHub
    echo -e "${GREEN}→ Force pushing to GitHub...${NC}"
    git push github ${CURRENT_BRANCH} --force
    
    cd "$ORIGINAL_DIR"
else
    echo -e "${GREEN}✓ GitHub copy exists at $GITHUB_COPY_DIR${NC}"
    
    # Sync current branch using reset method
    echo -e "${YELLOW}Syncing branch '${CURRENT_BRANCH}'...${NC}"
    
    cd "$GITHUB_COPY_DIR"
    
    # Fetch and reset to original state (no merge/pull)
    echo -e "${GREEN}→ Fetching branch from original...${NC}"
    git fetch "$ORIGINAL_DIR" ${CURRENT_BRANCH}:temp-branch --force
    
    # Check if current branch exists
    if git show-ref --verify --quiet "refs/heads/${CURRENT_BRANCH}"; then
        git checkout temp-branch
        git branch -D ${CURRENT_BRANCH}
    fi
    
    # Create/recreate branch
    git checkout -b ${CURRENT_BRANCH} temp-branch
    git branch -D temp-branch 2>/dev/null
    
    # Rewrite commits
    echo -e "${GREEN}→ Rewriting commits...${NC}"
    FILTER_BRANCH_SQUELCH_WARNING=1 git filter-branch -f --env-filter "
        export GIT_AUTHOR_NAME='${GITHUB_USER_NAME}'
        export GIT_AUTHOR_EMAIL='${GITHUB_USER_EMAIL}'
        export GIT_COMMITTER_NAME='${GITHUB_USER_NAME}'
        export GIT_COMMITTER_EMAIL='${GITHUB_USER_EMAIL}'
    " -- ${CURRENT_BRANCH}
    
    # Push to GitHub
    echo -e "${GREEN}→ Pushing to GitHub...${NC}"
    git push github ${CURRENT_BRANCH} --force
    
    cd "$ORIGINAL_DIR"
fi

# Step 2: Create sync scripts
echo -e "\n${GREEN}→ Creating sync scripts...${NC}"

# Create sync-to-github-safe.sh with values already substituted
cat > "sync-to-github-safe.sh" << EOF
#!/bin/bash

# Configuration
ORIGINAL_DIR=\$(pwd)
REPO_NAME=\$(basename "\$ORIGINAL_DIR")
GITHUB_COPY_DIR="../\${REPO_NAME}-github"
CURRENT_BRANCH=\$(git branch --show-current)

# GitHub user info
GITHUB_USER_NAME="${GITHUB_USER_NAME}"
GITHUB_USER_EMAIL="${GITHUB_USER_EMAIL}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "\${YELLOW}Syncing branch '\${CURRENT_BRANCH}' to GitHub copy...\${NC}"

# Check if GitHub copy exists
if [ ! -d "\$GITHUB_COPY_DIR" ]; then
    echo -e "\${RED}Error: GitHub copy not found at \$GITHUB_COPY_DIR\${NC}"
    echo "Run ./fix-and-setup.sh first"
    exit 1
fi

# Get current commit
ORIGINAL_COMMIT=\$(git rev-parse HEAD 2>/dev/null || echo "none")

cd "\$GITHUB_COPY_DIR"

# Check if branch exists and if in sync
BRANCH_EXISTS=false
GITHUB_COMMIT="none"
if git show-ref --verify --quiet "refs/heads/\${CURRENT_BRANCH}"; then
    BRANCH_EXISTS=true
    git checkout \${CURRENT_BRANCH} 2>/dev/null
    GITHUB_COMMIT=\$(git rev-parse HEAD 2>/dev/null || echo "none")
fi

# Show current state
echo -e "\${YELLOW}→ Current state:\${NC}"
cd "\$ORIGINAL_DIR"
echo "  Original (\${CURRENT_BRANCH}): \$(git log -1 --oneline 2>/dev/null || echo "no commits")"
cd "\$GITHUB_COPY_DIR"
if [ "\$BRANCH_EXISTS" = true ]; then
    echo "  GitHub (\${CURRENT_BRANCH}):   \$(git log -1 --oneline 2>/dev/null || echo "no commits")"
else
    echo "  GitHub (\${CURRENT_BRANCH}):   branch doesn't exist"
fi

# Check if already in sync
if [ "\$GITHUB_COMMIT" = "\$ORIGINAL_COMMIT" ] && [ "\$ORIGINAL_COMMIT" != "none" ] && [ "\$BRANCH_EXISTS" = true ]; then
    echo -e "\${GREEN}✓ Already in sync!\${NC}"
    cd "\$ORIGINAL_DIR"
    exit 0
fi

# Sync using reset method (always works, no conflicts)
echo -e "\n\${YELLOW}→ Syncing GitHub copy with original...\${NC}"

# Fetch from original (force to overwrite)
echo -e "\${GREEN}→ Fetching branch '\${CURRENT_BRANCH}' from original...\${NC}"
git fetch "\$ORIGINAL_DIR" \${CURRENT_BRANCH}:temp-sync --force

# Delete and recreate branch
if [ "\$BRANCH_EXISTS" = true ]; then
    git checkout temp-sync 2>/dev/null
    git branch -D \${CURRENT_BRANCH} 2>/dev/null
fi

# Create branch from temp
git checkout -b \${CURRENT_BRANCH} temp-sync
git branch -D temp-sync 2>/dev/null

# Rewrite all commits
echo -e "\${GREEN}→ Rewriting commits with GitHub author...\${NC}"
FILTER_BRANCH_SQUELCH_WARNING=1 git filter-branch -f --env-filter "
    export GIT_AUTHOR_NAME='${GITHUB_USER_NAME}'
    export GIT_AUTHOR_EMAIL='${GITHUB_USER_EMAIL}'
    export GIT_COMMITTER_NAME='${GITHUB_USER_NAME}'
    export GIT_COMMITTER_EMAIL='${GITHUB_USER_EMAIL}'
" -- \${CURRENT_BRANCH}

# Push to GitHub
echo -e "\${GREEN}→ Pushing branch '\${CURRENT_BRANCH}' to GitHub (force)...\${NC}"
git push github \${CURRENT_BRANCH} --force

cd "\$ORIGINAL_DIR"
echo -e "\${GREEN}✓ Sync complete!\${NC}"

# Show result
echo -e "\n\${YELLOW}Result:\${NC}"
echo "  Original: \$(git log -1 --oneline 2>/dev/null || echo "no commits")"
cd "\$GITHUB_COPY_DIR" 2>/dev/null && git checkout \${CURRENT_BRANCH} 2>/dev/null
echo "  GitHub:   \$(git log -1 --oneline --format='%h %s (%an)' 2>/dev/null || echo "no commits")"
cd "\$ORIGINAL_DIR"
EOF

chmod +x sync-to-github-safe.sh

# Create push-all.sh
cat > "push-all.sh" << 'EOF'
#!/bin/bash

CURRENT_BRANCH=$(git branch --show-current)

echo "Working on branch: ${CURRENT_BRANCH}"
echo ""
echo "→ Pushing to original..."
git push original ${CURRENT_BRANCH}

echo ""
echo "→ Syncing and pushing to GitHub..."
./sync-to-github-safe.sh
EOF

chmod +x push-all.sh

# Step 3: Summary
echo -e "\n${BLUE}========================================${NC}"
echo -e "${BLUE}Setup Complete!${NC}"
echo -e "${BLUE}========================================${NC}\n"

echo -e "${GREEN}✓ GitHub copy:${NC} $GITHUB_COPY_DIR"
echo -e "${GREEN}✓ Current branch:${NC} ${CURRENT_BRANCH}"
echo -e "${GREEN}✓ Scripts created:${NC}"
echo -e "  - sync-to-github-safe.sh (with your GitHub details)"
echo -e "  - push-all.sh"

# Show the configured values
echo -e "\n${YELLOW}Configured with:${NC}"
echo -e "  GitHub User: ${GITHUB_USER_NAME}"
echo -e "  GitHub Email: ${GITHUB_USER_EMAIL}"
echo -e "  GitHub Repo: ${GITHUB_REPO_URL}"

echo -e "\n${YELLOW}Latest commits:${NC}"
echo -e "Original (${CURRENT_BRANCH}): $(git log -1 --oneline)"
cd "$GITHUB_COPY_DIR" && echo -e "GitHub (${CURRENT_BRANCH}):   $(git log -1 --format='%h %s (%an <%ae>)')" && cd "$ORIGINAL_DIR"

echo -e "\n${BLUE}========================================${NC}"
echo -e "${BLUE}Usage:${NC}"
echo -e "${BLUE}========================================${NC}\n"
echo -e "  ${YELLOW}./push-all.sh${NC}      - Push current branch to both remotes"
echo -e "  ${YELLOW}./sync-to-github-safe.sh${NC} - Sync current branch to GitHub only"

echo -e "\n${GREEN}✅ Try running: ./push-all.sh${NC}"

