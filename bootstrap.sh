#!/bin/bash

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Install Homebrew if not installed
if ! command_exists brew; then
    echo "⚠️ Homebrew not found. Installing..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Install applications from Brewfile
brewfile_url="https://raw.githubusercontent.com/JacobCoffee/dotfiles/main/.config/Brewfile"
brewfile_local_path="/tmp/Brewfile"

curl -fsSL "$brewfile_url" -o "$brewfile_local_path"
if [ -f "$brewfile_local_path" ]; then
    echo "Installing applications from Brewfile..."
    brew bundle --file="$brewfile_local_path"
else
    echo "❗ Brewfile not found at $brewfile_url. Please make sure the Brewfile exists in the specified path."
    exit 1
fi

# Install Rust if not installed
if ! command_exists rustc; then
    echo "⚠️ Rust not found. Installing..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
fi

# Create the directory structure
mkdir -p ~/git/internal/{psf,pypa,pycon,python,pypi}
mkdir -p ~/git/public/{litestar-org,JacobCoffee}
echo "✅ Directory structure created successfully."

# Clone repositories function
clone_repos() {
    local base_dir=$1
    shift
    for repo in "$@"; do
        echo "Cloning $repo into $base_dir..."
        gh repo clone "$repo" "$base_dir/$(basename "$repo")"
    done
}

# Clone repositories for public/litestar-org
clone_repos ~/git/public/litestar-org \
    litestar-org/litestar \
    litestar-org/litestar-fullstack \
    litestar-org/polyfactory \
    litestar-org/litestar.dev \
    litestar-org/litestar-sphinx-theme \
    litestar-org/advanced-alchemy \
    litestar-org/type-lens \
    litestar-org/dtos \
    litestar-org/awesome-litestar \
    litestar-org/branding

# Clone repositories for public/JacobCoffee
clone_repos ~/git/public/JacobCoffee \
    JacobCoffee/byte

# Clone repositories for internal/python
clone_repos ~/git/internal/python \
    python/psf-salt \
    python/devguide \
    python/pythondotorg

# Clone repositories for internal/psf
clone_repos ~/git/internal/psf \
    psf/policies

# Clone repositories for internal/pypi
clone_repos ~/git/internal/pypi \
    pypi/warehouse

echo "✅ Repositories cloned successfully."
echo "🎉 Bootstrap script completed successfully."
