#!/usr/bin/env sh
set -u

# Make sure we're in a git repo
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "✖ Not inside a git repository."
  exit 1
fi

# Discover the default base branch of origin automatically
base_branch="$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@')"

if [ -z "$base_branch" ]; then
  echo "✖ Could not determine base branch from origin (refs/remotes/origin/HEAD)."
  exit 1
fi

# Determine current branch
current_branch="$(git rev-parse --abbrev-ref HEAD)" || exit 1

# Safety: never run on base branch itself
if [ "$current_branch" = "$base_branch" ]; then
  echo "✖ Refusing to sync on the base branch ($base_branch)."
  exit 1
fi

# Auto-stash if there are any local changes (staged or unstaged, including untracked)
auto_stash=0
if ! git diff --quiet || ! git diff --cached --quiet; then
  echo "ℹ Detected local changes. Temporarily stashing them..."
  if ! git stash push -u -m "sync auto-stash"; then
    echo "✖ Failed to stash local changes. Aborting."
    exit 1
  fi
  auto_stash=1
fi

# Update base
if ! git fetch origin "$base_branch"; then
  echo "✖ Fetch failed."
  if [ "$auto_stash" -eq 1 ]; then
    echo "ℹ Your pre-sync changes are saved in the stash (likely stash@{0})."
  fi
  exit 1
fi

# Rebase onto updated base
if ! git rebase "origin/$base_branch"; then
  echo "✖ Rebase onto origin/$base_branch failed."
  if [ "$auto_stash" -eq 1 ]; then
    echo "ℹ Your pre-sync changes are still in the stash (likely stash@{0})."
    echo "  Resolve the rebase, then use 'git stash list' / 'git stash apply' as needed."
  fi
  exit 1
fi

# Force-push safely
if ! git push --force-with-lease; then
  echo "✖ Push failed."
  if [ "$auto_stash" -eq 1 ]; then
    echo "ℹ Your pre-sync changes are still in the stash (likely stash@{0})."
  fi
  exit 1
fi

# If we auto-stashed, try to restore
if [ "$auto_stash" -eq 1 ]; then
  echo "ℹ Rebasing and push succeeded. Restoring stashed changes..."
  if ! git stash pop; then
    echo "⚠️ Failed to auto-apply stash cleanly."
    echo "   Your stashed changes should still be in 'git stash list'."
    echo "   Resolve conflicts and use 'git stash apply' manually if needed."
    exit 1
  fi
fi

echo "✓ sync complete: rebased onto origin/$base_branch and pushed."
exit 0
