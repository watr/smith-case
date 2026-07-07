#!/bin/zsh
set -eu

# Ensure hook arrays exist before mise/starship add entries
typeset -ga precmd_functions
typeset -ga preexec_functions
typeset -ga chpwd_functions

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
# 👻 LINK GHOSTTY CONFIGURATION
###############################################################################

local_ghostty_config="${script_dir}/ghostty/config"
home_ghostty_dir="${HOME}/.config/ghostty"
home_ghostty_config="${home_ghostty_dir}/config"

if [ ! -d "$home_ghostty_dir" ]; then
  mkdir -p "$home_ghostty_dir"
fi

if [ -f "$local_ghostty_config" ]; then
  if [ -L "$home_ghostty_config" ] && [ "$(readlink "$home_ghostty_config")" = "$local_ghostty_config" ]; then
    echo ">>> Ghostty config already linked: $home_ghostty_config → $local_ghostty_config"
  else
    echo ">>> Linking Ghostty config $home_ghostty_config → $local_ghostty_config ..."
    ln -snf "$local_ghostty_config" "$home_ghostty_config"
  fi
else
  echo ">>> ⚠️  Warning: Ghostty config not found at $local_ghostty_config. Skipped linking."
fi


###############################################################################
# 🤖 LINK AGENTS AND CODEX SKILLS
###############################################################################

link_preserving_existing() {
  local source_path=$1
  local target_path=$2
  local label=$3

  if [ -L "$target_path" ] && [ "$(readlink "$target_path")" = "$source_path" ]; then
    echo ">>> $label already linked: $target_path → $source_path"
  elif [ -e "$target_path" ] || [ -L "$target_path" ]; then
    echo ">>> ⚠️  Warning: $target_path already exists. Skipped linking $label."
  else
    echo ">>> Linking $label $target_path → $source_path ..."
    ln -s "$source_path" "$target_path"
  fi
}

local_agents_dir="${script_dir}/.agents"
home_agents_dir="${HOME}/.agents"
local_codex_agents_file="${script_dir}/.codex/AGENTS.md"
home_codex_dir="${HOME}/.codex"
home_codex_agents_file="${home_codex_dir}/AGENTS.md"
local_claude_file="${script_dir}/.claude/CLAUDE.md"
home_claude_dir="${HOME}/.claude"
home_claude_file="${home_claude_dir}/CLAUDE.md"

if [ -f "$local_codex_agents_file" ]; then
  if [ ! -d "$home_codex_dir" ]; then
    mkdir -p "$home_codex_dir"
  fi

  link_preserving_existing "$local_codex_agents_file" "$home_codex_agents_file" "Codex AGENTS.md"
else
  echo ">>> ⚠️  Warning: $local_codex_agents_file not found. Skipped linking Codex AGENTS.md."
fi

if [ -f "$local_claude_file" ]; then
  if [ ! -d "$home_claude_dir" ]; then
    mkdir -p "$home_claude_dir"
  fi

  link_preserving_existing "$local_claude_file" "$home_claude_file" "Claude CLAUDE.md"
else
  echo ">>> ⚠️  Warning: $local_claude_file not found. Skipped linking Claude CLAUDE.md."
fi

if [ -d "$local_agents_dir" ]; then
  if [ ! -d "$home_agents_dir" ]; then
    mkdir -p "$home_agents_dir"
  fi

  for local_agents_entry in "$local_agents_dir"/*(N); do
    agents_entry_name=$(basename "$local_agents_entry")

    case "$agents_entry_name" in
      .DS_Store)
        continue
        ;;
      skills)
        home_skills_dir="${home_agents_dir}/skills"

        if [ ! -d "$home_skills_dir" ]; then
          mkdir -p "$home_skills_dir"
        fi

        for local_skill_dir in "$local_agents_entry"/*(N); do
          skill_name=$(basename "$local_skill_dir")
          home_skill_dir="${home_skills_dir}/${skill_name}"

          if [ -f "${local_skill_dir}/SKILL.md" ]; then
            link_preserving_existing "$local_skill_dir" "$home_skill_dir" "${skill_name} skill"
          else
            echo ">>> ⚠️  Warning: ${local_skill_dir}/SKILL.md not found. Skipped linking."
          fi
        done
        ;;
      *)
        link_preserving_existing "$local_agents_entry" "${home_agents_dir}/${agents_entry_name}" ".agents/${agents_entry_name}"
        ;;
    esac
  done
else
  echo ">>> ⚠️  Warning: $local_agents_dir not found. Skipped linking agents."
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

# Claude Code (native install)
install_with_prompt "Claude Code" "curl -fsSL https://claude.ai/install.sh | bash" "claude"

# Codex (npm)
install_with_prompt "Codex" "npm install -g @openai/codex" "codex"

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
# 💤 LAZYGIT CONFIGURATION
###############################################################################

if command -v lazygit >/dev/null 2>&1; then
  lazygit_config_dir="${HOME}/Library/Application Support/lazygit"
  lazygit_config="${lazygit_config_dir}/config.yml"

  if [ ! -d "${lazygit_config_dir}" ]; then
    mkdir -p "${lazygit_config_dir}"
  fi

  if [ ! -f "${lazygit_config}" ]; then
    cat > "${lazygit_config}" <<'EOF'
git:
  overrideGpg: true
EOF
    log "Created lazygit config with git.overrideGpg enabled."
  elif grep -Eq '^[[:space:]]*overrideGpg:[[:space:]]*true[[:space:]]*$' "${lazygit_config}"; then
    log "lazygit git.overrideGpg already enabled."
  else
    lazygit_config_tmp="${lazygit_config}.tmp"
    if grep -Eq '^[[:space:]]*overrideGpg:' "${lazygit_config}"; then
      awk '
        /^[[:space:]]*overrideGpg:[[:space:]]*/ {
          sub(/overrideGpg:.*/, "overrideGpg: true")
        }
        { print }
      ' "${lazygit_config}" > "${lazygit_config_tmp}"
    else
      awk '
        BEGIN { inserted = 0 }
        /^git:[[:space:]]*$/ && inserted == 0 {
          print
          print "  overrideGpg: true"
          inserted = 1
          next
        }
        { print }
        END {
          if (inserted == 0) {
            print ""
            print "git:"
            print "  overrideGpg: true"
          }
        }
      ' "${lazygit_config}" > "${lazygit_config_tmp}"
    fi
    mv "${lazygit_config_tmp}" "${lazygit_config}"
    log "Enabled lazygit git.overrideGpg."
  fi
else
  log "lazygit not found. Skipped lazygit configuration."
fi

###############################################################################
# 🔐 GIT USER CONFIGURATION WITH GITHUB
###############################################################################

log "Configuring Git user information from GitHub..."
if command -v gh >/dev/null 2>&1; then
  # Check if gh is authenticated
  if ! gh auth status >/dev/null 2>&1; then
    log "GitHub CLI is not authenticated. Starting authentication..."
    gh auth login
  fi

  # Verify authentication succeeded
  if gh auth status >/dev/null 2>&1; then
    gh_login=$(gh api user --jq .login 2>/dev/null)
    gh_name=$(gh api user --jq .name 2>/dev/null)

    if [ -n "${gh_login}" ]; then
      # Use GitHub name if available, otherwise use login
      git_name="${gh_name:-$gh_login}"
      git config --global user.name "${git_name}"
      git config --global user.email "${gh_login}@users.noreply.github.com"
      log "Git user configured: ${git_name} <${gh_login}@users.noreply.github.com>"
    else
      log "⚠️  Could not retrieve GitHub user information"
    fi
  else
    log "⚠️  GitHub authentication failed. Please run 'gh auth login' manually."
  fi
else
  log "⚠️  GitHub CLI (gh) not found. Skipping Git user configuration."
fi

###############################################################################
# 🔐 GIT COMMIT SIGNING WITH 1PASSWORD
###############################################################################

log "Configuring Git commit signing with 1Password..."
git config --global gpg.format ssh
git config --global commit.gpgsign true
git config --global gpg.ssh.program "/Applications/1Password.app/Contents/MacOS/op-ssh-sign"

# Set up allowed signers file for SSH signature verification
ssh_dir="${HOME}/.ssh"
allowed_signers="${ssh_dir}/allowed_signers"
if [ ! -d "${ssh_dir}" ]; then
  mkdir -p "${ssh_dir}"
fi

# Get SSH key from 1Password and configure signing key.
# NOTE: filter on "sign"/"署名", not just "git" — some keys (e.g. the one
# commented "GitHub Authentication") also match "git" but are for SSH auth,
# not commit signing, and must not be picked here.
op_agent_sock="${HOME}/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
if [ -S "${op_agent_sock}" ]; then
  ssh_key=$(SSH_AUTH_SOCK="${op_agent_sock}" ssh-add -L 2>/dev/null | grep -iE "(署名|sign)" | grep -viE "auth" | head -n1)
  if [ -n "${ssh_key}" ]; then
    git config --global user.signingkey "${ssh_key}"
    # Create allowed_signers file with user's email and SSH key
    user_email=$(git config --global user.email 2>/dev/null || echo "")
    if [ -n "${user_email}" ]; then
      echo "${user_email} ${ssh_key}" > "${allowed_signers}"
      git config --global gpg.ssh.allowedSignersFile "${allowed_signers}"
      log "Git commit signing configured with 1Password SSH key (signing key)"
    fi
  else
    log "⚠️  No 1Password SSH key tagged for signing (comment containing '署名' or 'sign') was found."
  fi
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
