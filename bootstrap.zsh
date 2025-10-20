#!/bin/zsh
set -eu

###############################################################################
# 🏁 INITIAL SETUP
###############################################################################

invoked_as=$0 # how this script was invoked
script_name=$(basename "$invoked_as") # file name only
script_dir=$(cd "$(dirname "$invoked_as")" && pwd) # absolute path of the directory
dot_dir="$(cd "${script_dir}"; pwd)" # directory containing dotfiles

# Logging helper
log() {
  printf '%s\n' ">>> $*"
}

# Check if the script is sourced (zsh only, stable)
if [ "$0" != "$ZSH_NAME" ]; then
  : # sourced (OK)
else
  echo "Please run this script via:  source $0"
  echo "Or make it executable and run directly:  chmod +x $0 && $0"
  return 0 2>/dev/null || exit 0
fi

###############################################################################
# 🧩 LINK .zshrc FROM BOOTSTRAP DIRECTORY
###############################################################################

# Ensure ~/.zshrc points to the one located next to bootstrap.zsh.
# This keeps all Zsh configuration managed within the same directory.
local_zshrc="${script_dir}/.zshrc"
home_zshrc="${HOME}/.zshrc"

if [ -f "$local_zshrc" ]; then
  if [ -L "$home_zshrc" ] && [ "$(readlink "$home_zshrc")" = "$local_zshrc" ]; then
    echo ">>> .zshrc already linked: $home_zshrc → $local_zshrc"
  else
    echo ">>> Linking $home_zshrc → $local_zshrc ..."
    ln -snf "$local_zshrc" "$home_zshrc"
  fi
else
  echo ">>> ⚠️  Warning: $local_zshrc not found. Skipped linking."
fi

###############################################################################
# 🧰 XCODE COMMAND LINE TOOLS
###############################################################################

log "Checking Xcode Command Line Tools..."
if ! xcode-select -p &>/dev/null; then
  xcode-select --install
fi


###############################################################################
# ⚙️ GIT CONFIGURATION
###############################################################################

git_dir="${HOME}/.config/git"
if [ ! -d "${git_dir}" ]; then
  mkdir -p "${git_dir}"
  log "Created Git configuration directory at $git_dir..."
fi

# Link global .gitignore
command ln -snf "${dot_dir}/.gitignore_global" "${git_dir}/ignore"

# Ensure default branch is set
default_branch="$(git config --list --global 2>/dev/null | sed -nr 's/(^init.defaultBranch=)(.*)$/\2/pi')"
if [ -z "${default_branch}" ]; then
  git config --global init.defaultBranch main
fi


###############################################################################
# 🍺 HOMEBREW SETUP
###############################################################################

if command -v brew >/dev/null 2>&1; then
  log "Homebrew already installed: $(brew --version | head -n1)"
else
  log "Installing Homebrew..."

  # --- Temporarily enable non-interactive mode ---
  _old_noninteractive="${NONINTERACTIVE:-}" # save current state
  export NONINTERACTIVE=1

  sudo -v || true # pre-authenticate sudo once
  log "Installing Homebrew non-interactively..."
  install_url="https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh"
  /bin/bash -c "$(curl -fsSL "$install_url")"

  # --- Restore previous NONINTERACTIVE state ---
  if [ -z "$_old_noninteractive" ]; then
    unset NONINTERACTIVE
  else
    export NONINTERACTIVE="$_old_noninteractive"
  fi
  unset _old_noninteractive
fi

# Determine brew prefix
if /usr/bin/arch | grep -qi arm; then
  brew_prefix="/opt/homebrew"
else
  brew_prefix="/usr/local"
fi

# Apply brew shellenv to current shell
eval "$("$brew_prefix/bin/brew" shellenv)"

# Verify brew installation and update quietly
log "Verifying brew..."
brew --version | head -n1
brew update --quiet || true
log "brew prefix: $brew_prefix"


###############################################################################
# 🧩 MISE (POLYGLOT RUNTIME MANAGER)
###############################################################################

if ! command -v mise >/dev/null 2>&1; then
  log "Installing mise..."
  brew install mise
fi

# Activate mise for current shell
eval "$(mise activate zsh || mise activate --shims || true)"

# Install Node.js via mise
if ! mise list | grep -q node; then
  log "Installing Node.js via mise..."
  mise use --global node@latest
fi

# Refresh environment
eval "$(mise activate zsh || mise activate --shims || true)"

###############################################################################
# 🤖 DEVELOPER TOOLS (CLAUDE CODE / CODEX / CURSOR)
###############################################################################

install_with_prompt() {
  local name=$1
  local install_cmd=$2
  local check_cmd=${3:-$1}

  if command -v "$check_cmd" >/dev/null 2>&1; then
    log "$name already installed: $($check_cmd --version 2>/dev/null || echo ok)"
    return
  fi

  # Skip if NONINTERACTIVE=1 (explicitly)
  if [ "${NONINTERACTIVE:-0}" -eq 1 ]; then
    log "NONINTERACTIVE mode detected — skipping $name installation (manual confirmation required)."
    return
  fi

  # Otherwise, always ask
  read -r "?Do you want to install $name? [y/N] " answer
  case "$answer" in
    [yY]|[yY][eE][sS])
      log "Installing $name..."
      eval "$install_cmd"
      ;;
    *)
      log "Skipped $name installation."
      ;;
  esac
}

# Claude Code (npm)
install_with_prompt "Claude Code" "npm install -g @anthropic-ai/claude-code" "claude"

# Codex (npm)
install_with_prompt "Codex" "npm install -g @openai/codex" "codex"

# Cursor (brew cask)
install_with_prompt "Cursor" "brew install --cask cursor" "cursor"

###############################################################################
# 📦 BREWFILE INSTALLATION
###############################################################################

brewfile="$script_dir/Brewfile"
if [ -f "$brewfile" ]; then
  log "Installing packages from $brewfile ..."
  brew bundle --file="$brewfile"
else
  log "No Brewfile found at $brewfile (skipped)."
fi

###############################################################################
# 🌟 STARSHIP PROMPT INITIALIZATION
###############################################################################
if command -v starship &>/dev/null; then
  # --- Always show font warning for users who may forget terminal font setup ---
  log "⚠️  If Starship icons look broken or misaligned, set your terminal font to a Nerd Font."
  log "   Example: JetBrains Mono Nerd Font, Fira Code Nerd Font, or MesloLGS NF."
  log "   You can install one via: brew install --cask font-jetbrains-mono-nerd-font"

  # --- Temporarily disable 'nounset' (set -u) to avoid ZLE widget errors ---
  if [[ -o nounset ]]; then
    set +u
    _starship_nounset_restored=1
  fi

  # Load for current shell
  eval "$(starship init zsh)"

  # Restore 'set -u' if it was previously active
  if [[ "${_starship_nounset_restored:-0}" -eq 1 ]]; then
    set -u
    unset _starship_nounset_restored
  fi
fi


###############################################################################
# ✅ FINISH
###############################################################################

log "Bootstrap completed successfully."
