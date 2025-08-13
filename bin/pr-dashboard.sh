#!/bin/bash

# PR Dashboard - Lists open PRs for configured repositories
# Uses GitHub CLI to fetch PR information

set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_CONFIG_FILE="$SCRIPT_DIR/../conf/repos.list"
USER_CONFIG_FILE="$HOME/.pr-dashboard-config"

# Use user config if it exists, otherwise use default
if [[ -f "$USER_CONFIG_FILE" ]]; then
    CONFIG_FILE="$USER_CONFIG_FILE"
else
    CONFIG_FILE="$DEFAULT_CONFIG_FILE"
fi

# Function to show help text
show_help() {
    echo "PR Dashboard - GitHub CLI Tool for Open Pull Requests"
    echo "====================================================="
    echo ""
    echo "This script fetches and displays open pull requests for configured repositories."
    echo ""
    echo "Prerequisites:"
    echo "1. Install GitHub CLI:"
    echo "   brew install gh"
    echo ""
    echo "2. Create a GitHub Personal Access Token:"
    echo "   - Go to https://github.com/settings/tokens"
    echo "   - Generate a new token with 'repo' permissions"
    echo ""
    echo "3. Authenticate with GitHub CLI:"
    echo "   gh auth login"
    echo "   (Follow the prompts and use your personal access token, or authenticate with the browser)"
    echo ""
    echo "Configuration:"
    echo "- Default config file: $DEFAULT_CONFIG_FILE"
    echo "- User override config: $USER_CONFIG_FILE (optional)"
    echo "- Currently using: $CONFIG_FILE"
    echo ""
    echo "To create your own repository list:"
    echo "1. Copy the default config file:"
    echo "   cp $DEFAULT_CONFIG_FILE $USER_CONFIG_FILE"
    echo "2. Edit your personal config:"
    echo "   nvim $USER_CONFIG_FILE"
    echo "3. Add one GitHub repository URL per line"
    echo "   Example: https://github.com/owner/repository"
    echo ""
    echo "Usage:"
    echo "  ./bin/pr-dashboard.sh"
    echo ""
}

# Check if help is requested
if [[ "$1" == "-h" || "$1" == "--help" || "$1" == "help" ]]; then
    show_help
    exit 0
fi

# Check if GitHub CLI is installed
if ! command -v gh &> /dev/null; then
    echo "❌ GitHub CLI (gh) is not installed!"
    echo ""
    show_help
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
    echo "❌ Not authenticated with GitHub CLI!"
    echo ""
    echo "Please run: gh auth login"
    echo "If you need help with authentication, run: $0 --help"
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

        # Fetch open PRs using GitHub CLI
        prs=$(gh pr list --repo "$repo_identifier" --state open --json number,title,author,createdAt,url,reviewRequests --template '{{range .}}{{$reviewers := ""}}{{range .reviewRequests}}{{$name := ""}}{{if .login}}{{$name = .login}}{{else if .name}}{{$name = .name}}{{end}}{{if ne $name "pleo-bot-auto-approver"}}{{if $reviewers}}{{$reviewers = printf "%s," $reviewers}}{{end}}{{$reviewers = printf "%s%s" $reviewers $name}}{{end}}{{end}}{{if $reviewers}}{{$reviewers = printf "\033[32m[%s]\033[0m" $reviewers}}{{end}}{{printf "%-15s %-12s #%-5.0f %-40s %-30s %s" .author.login (timeago .createdAt) .number .title $reviewers .url}}
{{end}}')

        if [[ -z "$prs" ]]; then
            echo "📁 Repository: $repo_name ($repo_identifier) - $repo_url ✅ - no open PRs"
        else
            echo "📁 Repository: $repo_name ($repo_identifier) - $repo_url"
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
