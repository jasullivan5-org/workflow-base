#!/usr/bin/env sh
set -e

echo "Configuring global 'git run' alias to dispatch to ./git-aliases..."

git config alias.run \
  "!f() { cmd=\"\$1\"; shift; sh ./git-aliases/\"\$cmd\" \"\$@\"; }; f"

echo
echo "Done."
echo "You can now run commands like:"
echo "  git run sync-pr"
echo "  git run travel"