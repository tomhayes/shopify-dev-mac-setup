# Restart affected applications
print_status "Restarting affected applications..."
killall Finder
killall Dock
killall SystemUIServer# Configure macOS system preferences for development
print_status "Configuring macOS system preferences for development..."

# Finder preferences
print_status "Configuring Finder..."
defaults write com.apple.finder AppleShowAllFiles -bool true  # Show hidden files
defaults write com.apple.finder ShowPathbar -bool true       # Show path bar
defaults write com.apple.finder ShowStatusBar -bool true     # Show status bar
defaults write com.apple.finder _FXShowPosixPathInTitle -bool true  # Show full path in title
defaults write NSGlobalDomain AppleShowAllExtensions -bool true     # Show all file extensions

# Dock preferences
print_status "Configuring Dock..."
defaults write com.apple.dock tilesize -int 48              # Smaller dock icons
defaults write com.apple.dock autohide -bool true           # Auto-hide dock
defaults write com.apple.dock autohide-delay -float 0       # Remove dock show delay
defaults write com.apple.dock show-recents -bool false      # Don't show recent apps in dock

# Screenshots
print_status "Configuring Screenshots..."
defaults write com.apple.screencapture location -string "$HOME/Desktop/Screenshots"  # Screenshot location
defaults write com.apple.screencapture type -string "png"   # PNG format
defaults write com.apple.screencapture disable-shadow -bool true  # No window shadows
mkdir -p "$HOME/Desktop/Screenshots"

# Trackpad preferences
print_status "Configuring Trackpad..."
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true  # Tap to click
defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 1

# Keyboard preferences
print_status "Configuring Keyboard..."
defaults write NSGlobalDomain KeyRepeat -int 2              # Fast key repeat
defaults write NSGlobalDomain InitialKeyRepeat -int 15      # Short delay before repeat
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false  # Disable press-and-hold for accents

# Terminal preferences
print_status "Configuring Terminal..."
defaults write com.apple.terminal StringEncodings -array 4  # UTF-8 encoding

# Menu bar
print_status "Configuring Menu Bar..."
defaults write com.apple.menuextra.clock DateFormat -string "EEE MMM d  h:mm a"  # Show date in menu bar

# Safari (for web development)
print_status "Configuring Safari for development..."
defaults write com.apple.Safari IncludeInternalDebugMenu -bool true
defaults write com.apple.Safari IncludeDevelopMenu -bool true
defaults write com.apple.Safari WebKitDeveloperExtrasEnabledPreferenceKey -bool true
defaults write com.apple.Safari com.apple.Safari.ContentPageGroupIdentifier.WebKit2DeveloperExtrasEnabled -bool true

print_success "macOS system preferences configured for development"
print_warning "Some changes require a restart to take effect"# Set up Oh My Zsh
print_status "Installing Oh My Zsh..."
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    
    # Install popular plugins
    git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
    git clone https://github.com/zsh-users/zsh-syntax-highlighting ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
    
    # Set up a nice theme and plugins
    sed -i '' 's/ZSH_THEME="robbyrussell"/ZSH_THEME="agnoster"/g' ~/.zshrc
    sed -i '' 's/plugins=(git)/plugins=(git node npm yarn docker shopify nvm zsh-autosuggestions zsh-syntax-highlighting)/g' ~/.zshrc
    
    print_success "Oh My Zsh installed with plugins and agnoster theme"
else
    print_success "Oh My Zsh already installed"
fi# Install Claude Code CLI
print_status "Installing Claude Code CLI..."
if ! command -v claude_code &> /dev/null; then
    # Check if npx is available for installing Claude Code
    if command -v npx &> /dev/null; then
        # Note: Claude Code installation method may vary - check Anthropic's docs
        print_status "Claude Code CLI installation - please check Anthropic's documentation for latest installation method"
        print_warning "Visit: https://docs.anthropic.com for Claude Code CLI installation instructions"
    else
        print_error "npx not found - needed for Claude Code CLI installation"
    fi
else
    print_success "Claude Code CLI already installed"
fi#!/bin/bash

# Shopify Development Environment Setup Script for macOS
# Run with: bash setup.sh

set -e  # Exit on any error

echo "🚀 Starting Shopify Development Environment Setup..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    print_error "This script is designed for macOS only"
    exit 1
fi

# Install Xcode Command Line Tools
print_status "Installing Xcode Command Line Tools..."
if ! xcode-select -p &> /dev/null; then
    xcode-select --install
    print_warning "Please complete the Xcode Command Line Tools installation and re-run this script"
    exit 1
else
    print_success "Xcode Command Line Tools already installed"
fi

# Install Homebrew
print_status "Installing Homebrew..."
if ! command -v brew &> /dev/null; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    
    # Add Homebrew to PATH for Apple Silicon Macs
    if [[ $(uname -m) == "arm64" ]]; then
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
    
    print_success "Homebrew installed successfully"
else
    print_success "Homebrew already installed"
    brew update
fi

# Install essential development tools
print_status "Installing essential development tools..."

# Core development tools
brew_packages=(
    # Version control
    "git"
    "gh"  # GitHub CLI
    
    # Node.js and package managers
    "nvm"
    "npm"
    "yarn"
    "pnpm"
    
    # Ruby (useful for Jekyll, legacy tools, and general scripting)
    "ruby"
    "rbenv"
    
    # Python
    "python@3.11"
    
    # Database
    "postgresql"
    "redis"
    
    # Development utilities
    "curl"
    "wget"
    "jq"  # JSON processor
    "tree"
    "htop"
    
    # Image optimization
    "imagemagick"
    "webp"
    
    # SSL certificates
    "mkcert"
    
    # Development servers
    "nginx"
)

for package in "${brew_packages[@]}"; do
    if brew list "$package" &>/dev/null; then
        print_success "$package already installed"
    else
        print_status "Installing $package..."
        brew install "$package"
    fi
done

# Install GUI applications via Homebrew Cask
print_status "Installing GUI applications..."

cask_packages=(
    # Code editors
    "visual-studio-code"
    
    # Browsers for testing
    "google-chrome"
    "firefox"
    "microsoft-edge"
    
    # Development tools
    "docker"
    "postman"
    "tableplus"  # Database client
    "gitkraken"  # Git GUI client
    "herd"       # Laravel/PHP development environment
    
    # AI Tools
    "claude"     # Claude Desktop app
    
    # Terminals
    "warp"       # Modern terminal
    "hyper"      # Electron-based terminal
    
    # Design tools
    "figma"
    
    # Productivity apps
    "notion"
    "obsidian"
    "notion-calendar"
    "slack"
    "raycast"    # Spotlight replacement
    "1password"  # Password manager
    
    # System utilities
    "hazel"      # Automated file organization
    "dozer"      # Hide menu bar icons
    "rectangle"  # Window management
    "imageoptim" # Image compression
    
    # Database GUIs
    "mongodb-compass"  # MongoDB GUI
    "another-redis-desktop-manager"  # Redis GUI
    
    # Utilities
    "ngrok"      # Tunneling tool
)

for cask in "${cask_packages[@]}"; do
    if brew list --cask "$cask" &>/dev/null; then
        print_success "$cask already installed"
    else
        print_status "Installing $cask..."
        brew install --cask "$cask"
    fi
done

# Install Shopify CLI and Theme Kit
print_status "Installing Shopify CLI and Theme Kit..."
if ! command -v shopify &> /dev/null; then
    npm install -g @shopify/cli @shopify/theme
    print_success "Shopify CLI installed successfully"
else
    print_success "Shopify CLI already installed"
    npm update -g @shopify/cli @shopify/theme
fi

# Install legacy Shopify Theme Kit
print_status "Installing Shopify Theme Kit (legacy)..."
if ! command -v theme &> /dev/null; then
    brew tap shopify/shopify
    brew install themekit
    print_success "Shopify Theme Kit installed successfully"
else
    print_success "Shopify Theme Kit already installed"
fi

# Install useful Node.js global packages
print_status "Installing useful Node.js global packages..."
global_npm_packages=(
    "lighthouse"
    "pm2"
    "nodemon"
    "typescript"
    "eslint"
    "prettier"
    "serve"
    "http-server"
    "koa"
    "koa-generator"
)

for package in "${global_npm_packages[@]}"; do
    npm install -g "$package"
done

# Set up Node.js with NVM
print_status "Setting up Node.js with NVM..."
if command -v nvm &> /dev/null; then
    # Source NVM for this session
    export NVM_DIR="$HOME/.nvm"
    [ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"
    [ -s "/usr/local/opt/nvm/nvm.sh" ] && \. "/usr/local/opt/nvm/nvm.sh"
    
    # Add NVM to shell profile
    echo 'export NVM_DIR="$HOME/.nvm"' >> ~/.zshrc
    echo '[ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"' >> ~/.zshrc
    echo '[ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"' >> ~/.zshrc
    
    # Install Node.js versions
    print_status "Installing Node.js 14 (legacy support)..."
    nvm install 14
    
    print_status "Installing Node.js stable..."
    nvm install stable
    
    print_status "Installing Node.js latest..."
    nvm install node
    
    # Set stable as default
    nvm use stable
    nvm alias default stable
    
    print_success "Node.js versions installed - stable set as default"
    print_status "Available versions:"
    nvm list
else
    print_error "NVM installation failed"
fi

# Set up Ruby environment
print_status "Setting up Ruby environment..."
if command -v rbenv &> /dev/null; then
    # Initialize rbenv
    echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.zshrc
    echo 'eval "$(rbenv init -)"' >> ~/.zshrc
    
    # Source rbenv for this session
    export PATH="$HOME/.rbenv/bin:$PATH"
    eval "$(rbenv init -)"
    
    # Install latest stable Ruby
    latest_ruby=$(rbenv install -l | grep -v - | tail -1 | tr -d ' ')
    print_status "Installing Ruby $latest_ruby..."
    rbenv install "$latest_ruby"
    rbenv global "$latest_ruby"
    
    print_success "Ruby $latest_ruby installed and set as global"
fi

# Set up Git (basic configuration)
print_status "Configuring Git..."
read -p "Enter your Git username: " git_username
read -p "Enter your Git email: " git_email

git config --global user.name "$git_username"
git config --global user.email "$git_email"
git config --global init.defaultBranch main
git config --global pull.rebase false

print_success "Git configured successfully"

# Set up SSH key for GitHub (optional)
print_status "Setting up SSH key for GitHub..."
if [ ! -f ~/.ssh/id_ed25519 ]; then
    ssh-keygen -t ed25519 -C "$git_email" -f ~/.ssh/id_ed25519 -N ""
    eval "$(ssh-agent -s)"
    ssh-add ~/.ssh/id_ed25519
    
    print_success "SSH key generated"
    print_warning "Add this SSH key to your GitHub account:"
    cat ~/.ssh/id_ed25519.pub
else
    print_success "SSH key already exists"
fi

# Create useful directories
print_status "Creating development directories..."
mkdir -p ~/Development/shopify-projects
mkdir -p ~/Development/shopify-themes
mkdir -p ~/Development/shopify-apps
mkdir -p ~/Development/node-projects
mkdir -p ~/Development/scripts
mkdir -p ~/Development/playground

# Set up VS Code Settings Sync
print_status "Setting up VS Code Settings Sync..."
if command -v code &> /dev/null; then
    print_success "VS Code installed - you can now sync your settings!"
    print_warning "To sync your extensions and settings:"
    echo "   1. Open VS Code"
    echo "   2. Press Cmd+Shift+P and search for 'Settings Sync: Turn On'"
    echo "   3. Sign in with your GitHub account"
    echo "   4. Choose what to sync (Settings, Extensions, Keybindings, etc.)"
    echo "   5. Your extensions and settings will sync automatically"
else
    print_warning "VS Code not found - install it first to use Settings Sync"
fi

# Set up SSL certificates for local development
print_status "Setting up SSL certificates for local development..."
if command -v mkcert &> /dev/null; then
    mkcert -install
    mkcert localhost 127.0.0.1 ::1
    print_success "SSL certificates configured"
fi

# Create a sample .env file template
print_status "Creating environment file template..."
cat > ~/Development/shopify-projects/.env.example << EOF
# Shopify Development Environment Variables
SHOPIFY_API_KEY=your_api_key_here
SHOPIFY_API_SECRET=your_api_secret_here
SHOPIFY_APP_URL=https://your-app-url.ngrok.io
SHOPIFY_SCOPES=read_products,write_products,read_orders
DATABASE_URL=postgresql://localhost/your_app_development
REDIS_URL=redis://localhost:6379
EOF

# Final cleanup and summary
print_status "Cleaning up..."
brew cleanup

print_success "🎉 Shopify development environment setup completed!"

echo ""
echo "📝 Next Steps:"
echo "1. Restart your terminal or run: source ~/.zshrc"
echo "2. Add your SSH key to GitHub: https://github.com/settings/keys"
echo "4. Set up VS Code Settings Sync (Cmd+Shift+P → 'Settings Sync: Turn On')"
echo "5. Install Claude Code CLI - check https://docs.anthropic.com for latest instructions"
echo "6. Authenticate with Shopify CLI: shopify auth login"
echo "7. Start a new Shopify project: shopify app create"
echo ""
echo "📁 Development directories created:"
echo "   ~/Development/shopify-projects - Main Shopify projects and apps"
echo "   ~/Development/shopify-themes - Shopify theme development"
echo "   ~/Development/shopify-apps - Standalone Shopify applications"
echo "   ~/Development/node-projects - General Node.js projects"
echo "   ~/Development/scripts - Utility scripts and automation"
echo "   ~/Development/playground - Testing and experimentation"
echo ""
echo "🔧 Installed tools:"
echo "   - Homebrew package manager"
echo "   - Git and GitHub CLI"  
echo "   - Node.js, npm, yarn, pnpm"
echo "   - Ruby and rbenv"
echo "   - Shopify CLI"
echo "   - Docker, PostgreSQL, Redis"
echo "   - VS Code with Settings Sync ready"
echo "   - Development browsers and tools"
echo ""
echo "💡 Pro tips:"
echo "   - Run 'shopify theme dev' for new Shopify CLI live reloading"
echo "   - Run 'theme watch' for legacy Theme Kit development"
echo "   - Use Claude Desktop for AI assistance with coding and writing"
echo "   - Try 'claude_code' in terminal for AI-powered command line coding (after setup)"
echo "   - Use Rectangle (⌘+⌥+Arrow) for instant window management"
echo "   - Use Raycast (⌘+Space) as your new app launcher"
echo "   - Compress images with ImageOptim before using in themes"
echo "   - Set up Hazel rules to keep your Downloads folder organized"
echo "   - Try Warp terminal for modern shell features and AI assistance"
echo "   - Customize your Oh My Zsh theme: https://github.com/ohmyzsh/ohmyzsh/wiki/Themes"
