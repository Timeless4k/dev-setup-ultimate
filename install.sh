#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}Installing DEV-SETUP framework...${NC}"

# Create necessary directories
mkdir -p "$HOME/.dev-setup/modules"
mkdir -p "$HOME/.dev-setup/logs"
mkdir -p "$HOME/.dev-setup/config"

# Copy main script
cp "$(dirname "$0")/main_script.sh" "$HOME/.dev-setup/"
chmod +x "$HOME/.dev-setup/main_script.sh"

# Copy module scripts
cp "$(dirname "$0")/modules/"*.sh "$HOME/.dev-setup/modules/"
chmod +x "$HOME/.dev-setup/modules/"*.sh

# Create alias for easy access (optional)
if ! grep -q "alias dev-setup" "$HOME/.bashrc"; then
    echo "# DEV-SETUP alias" >> "$HOME/.bashrc"
    echo "alias dev-setup='$HOME/.dev-setup/main_script.sh'" >> "$HOME/.bashrc"
    
    # Also add to .zshrc if it exists
    if [ -f "$HOME/.zshrc" ]; then
        echo "# DEV-SETUP alias" >> "$HOME/.zshrc"
        echo "alias dev-setup='$HOME/.dev-setup/main_script.sh'" >> "$HOME/.zshrc"
    fi
    
    echo -e "${GREEN}Added 'dev-setup' alias to shell configuration${NC}"
fi

echo -e "${GREEN}Installation complete!${NC}"
echo -e "${BLUE}Run the framework with:${NC} dev-setup"
echo -e "${BLUE}(You may need to restart your terminal for the alias to work)${NC}"
echo -e "${BLUE}Alternatively, run:${NC} $HOME/.dev-setup/main_script.sh"