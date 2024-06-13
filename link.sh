#!/bin/bash

SOURCE_DIR=~/git/public/dotfiles/.config
DEST_DIR=~/.config

mkdir -p "$DEST_DIR"

for item in "$SOURCE_DIR"/*; do
  base_item=$(basename "$item")
  ln -sfn "$SOURCE_DIR/$base_item" "$DEST_DIR/$base_item"
done

