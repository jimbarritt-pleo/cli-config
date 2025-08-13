#!/bin/bash

# PR Dashboard - Lists open PRs for configured repositories
# Uses GitHub CLI to fetch PR information

set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/../conf/repos.list"

# Check if GitHub CLI is installed
if ! command -v gh &> /dev/null; then
    echo "Error: GitHub CLI (gh) is not installed or not in PATH"
    echo "Please install it from: https://cli.github.com/"
    exit 1
fi

# Check if config file exists
if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "Error: Configuration file not found at $CONFIG_FILE"
    echo "Please create the file with one GitHub repository URL per line"
    exit 1
fi

# Check if user is authenticated with GitHub CLI
if ! gh auth status &> /dev/null; then
    echo "Error: Not authenticated with GitHub CLI"
    echo "Please run: gh auth login"
    exit 1
fi

echo "🔍 Fetching open PRs for configured repositories..."
echo "=================================================="

# Read the config file and process each repository URL
while IFS= read -r repo_url; do
    # Skip empty lines and comments
    [[ -z "$repo_url" || "$repo_url" =~ ^[[:space:]]*# ]] && continue

    # Extract owner/repo from URL and get repo name
    if [[ "$repo_url" =~ github\.com/([^/]+)/([^/]+)/?$ ]]; then
        owner="${BASH_REMATCH[1]}"
        repo="${BASH_REMATCH[2]}"
        repo_identifier="$owner/$repo"
        repo_name="$repo"  # Use the repo part as the display name

        echo ""
        echo "📁 Repository: $repo_name ($repo_identifier)"
        echo "   URL: $repo_url"
        echo "   ----------------------------------------"

        # Fetch open PRs using GitHub CLI
        prs=$(gh pr list --repo "$repo_identifier" --state open --json number,title,author,createdAt,url --template '{{range .}}#{{.number}} - {{.title}} (by @{{.author.login}}, {{timeago .createdAt}})
{{.url}}
{{end}}')

        if [[ -z "$prs" ]]; then
            echo "   ✅ No open PRs"
        else
            echo "$prs" | sed 's/^/   /'
        fi
    else
        echo "⚠️  Invalid repository URL format: $repo_url"
        echo "   Expected format: https://github.com/owner/repo"
    fi
done < "$CONFIG_FILE"

echo ""
echo "=================================================="
echo "✨ PR dashboard complete!"
