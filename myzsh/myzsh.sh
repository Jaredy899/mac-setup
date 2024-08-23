#!/usr/bin/env zsh

# Set the GITPATH variable to the directory where the script is located
GITPATH="$(cd "$(dirname "$0")" && pwd)"
echo "GITPATH is set to: $GITPATH"

# GitHub URL base for the necessary configuration files
GITHUB_BASE_URL="https://raw.githubusercontent.com/Jaredy899/mac/main/myzsh"

# Function to install dependencies
installDepend() {
    # List of dependencies
    DEPENDENCIES=(zsh zsh-completions bat tree multitail fastfetch wget unzip fontconfig starship fzf zoxide)

    echo "Installing dependencies..."
    for package in "${DEPENDENCIES[@]}"; do
        echo "Installing $package..."
        if ! brew install "$package"; then
            echo "Failed to install $package. Please check your brew installation."
            exit 1
        fi
    done

    # List of cask dependencies, including the Nerd Font
    CASK_DEPENDENCIES=("alacritty" "kitty" "tabby" "font-caskaydia-cove-nerd-font")

    echo "Installing cask dependencies: ${CASK_DEPENDENCIES[*]}..."
    for cask in "${CASK_DEPENDENCIES[@]}"; do
        echo "Installing $cask..."
        if ! brew install --cask "$cask"; then
            echo "Failed to install $cask. Please check your brew installation."
            exit 1
        fi
    done

    # Complete fzf installation
    if [ -e ~/.fzf/install ]; then
        ~/.fzf/install --all
    fi
}

# Function to link or copy fastfetch and starship configurations
linkConfig() {
    USER_HOME="$HOME"
    CONFIG_DIR="$USER_HOME/.config"

    # Fastfetch configuration
    FASTFETCH_CONFIG_DIR="$CONFIG_DIR/fastfetch"
    FASTFETCH_CONFIG="$FASTFETCH_CONFIG_DIR/config.jsonc"

    if [ ! -d "$FASTFETCH_CONFIG_DIR" ]; then
        mkdir -p "$FASTFETCH_CONFIG_DIR"
    fi

    if [ ! -f "$FASTFETCH_CONFIG" ]; then
        if [ -f "$GITPATH/config.jsonc" ]; then
            ln -svf "$GITPATH/config.jsonc" "$FASTFETCH_CONFIG" || {
                echo "Failed to create symbolic link for config.jsonc"
                exit 1
            }
            echo "Linked config.jsonc to $FASTFETCH_CONFIG."
        else
            echo "config.jsonc not found in $GITPATH. Attempting to download from GitHub..."
            curl -fsSL "$GITHUB_BASE_URL/config.jsonc" -o "$FASTFETCH_CONFIG" || {
                echo "Failed to download config.jsonc from GitHub."
                exit 1
            }
            echo "Downloaded config.jsonc from GitHub to $FASTFETCH_CONFIG."
        fi
    else
        echo "config.jsonc already exists in $FASTFETCH_CONFIG_DIR."
    fi

    # Starship configuration
    STARSHIP_CONFIG="$CONFIG_DIR/starship.toml"
    if [ ! -f "$STARSHIP_CONFIG" ]; then
        if [ -f "$GITPATH/starship.toml" ]; then
            ln -svf "$GITPATH/starship.toml" "$STARSHIP_CONFIG" || {
                echo "Failed to create symbolic link for starship.toml"
                exit 1
            }
            echo "Linked starship.toml to $STARSHIP_CONFIG."
        else
            echo "starship.toml not found in $GITPATH. Attempting to download from GitHub..."
            curl -fsSL "$GITHUB_BASE_URL/starship.toml" -o "$STARSHIP_CONFIG" || {
                echo "Failed to download starship.toml from GitHub."
                exit 1
            }
            echo "Downloaded starship.toml from GitHub to $STARSHIP_CONFIG."
        fi
    else
        echo "starship.toml already exists in $CONFIG_DIR."
    fi
}

# Function to update .zshrc
update_zshrc() {
    USER_HOME="$HOME"
    ZSHRC_FILE="$USER_HOME/.zshrc"

    # Check if .zshrc file exists, if not create it
    if [ ! -f "$ZSHRC_FILE" ]; then
        touch "$ZSHRC_FILE"
    fi

    # Add line to the top of the .zshrc file
    AUTOCOMPLETE_LINE="source /opt/homebrew/share/zsh-autocomplete/zsh-autocomplete.plugin.zsh"
    if ! grep -Fxq "$AUTOCOMPLETE_LINE" "$ZSHRC_FILE"; then
        echo "$AUTOCOMPLETE_LINE" | cat - "$ZSHRC_FILE" > temp && mv temp "$ZSHRC_FILE"
    fi

    # Add lines to the bottom of the .zshrc file
    STARSHIP_INIT="eval \"\$(starship init zsh)\""
    ZOXIDE_INIT="eval \"\$(zoxide init zsh)\""
    FASTFETCH="fastfetch"

    for LINE in "$STARSHIP_INIT" "$ZOXIDE_INIT" "$FASTFETCH"; do
        if ! grep -Fxq "$LINE" "$ZSHRC_FILE"; then
            echo "$LINE" >> "$ZSHRC_FILE"
        fi
    done

    echo ".zshrc updated."
}

# Run all functions
installDepend
linkConfig
update_zshrc

echo "Setup completed successfully."