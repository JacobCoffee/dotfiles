#!/bin/bash

SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/.config"
DEST_DIR="$HOME/.config"

mkdir -p "$DEST_DIR"

for item in "$SOURCE_DIR"/*; do
  base_item=$(basename "$item")
  echo "linking '$item' to '$DEST_DIR/$base_item'"
  ln -sfn "$item" "$DEST_DIR/$base_item"
done

if ! grep -q "Include $HOME/.config/ssh.aliases" "$HOME/.ssh/config"; then
  echo "Updating SSH config"
  echo "Include $HOME/.config/ssh.aliases" | cat - "$HOME/.ssh/config" > temp && mv temp "$HOME/.ssh/config"
fi