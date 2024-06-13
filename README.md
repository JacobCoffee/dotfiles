# Dotfiles

This repository contains a script to set up a new macOS machine with the required tools and configurations.

## Usage

To use this script on a brand-new macOS machine, open the Terminal app and run the following command:

```sh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/JacobCoffee/dotfiles/main/bootstrap.sh)"
```

This command will:

1. Install `Homebrew`
2. Install applications from the [`./.config/Brewfile`](.config/Brewfile) in this repository
3. Install `Rust` 
4. Create the necessary directory structure in `~/git`
5. Clone specified repositories

Make sure to adjust any paths or repository URLs as needed for your specific setup.


