#!/bin/sh
set -e

REPO='<YOUR_REPO_URL>'

echo "Chezmoi repo: $REPO"
echo 'Initialization in progress...'
sh -c "$(curl -fsLS get.chezmoi.io/lb)" -- init --apply "$REPO"

while [ -f "$HOME/.cache/chezmoi/.reinit" ]; do
    echo 'Re-init file was found. Trying to call init with apply one more time...'
    rm "$HOME/.cache/chezmoi/.reinit"
    "$HOME/.local/bin/chezmoi" init --apply
done

