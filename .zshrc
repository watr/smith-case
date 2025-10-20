###############################################################################
# 🍺 HOMEBREW INITIALIZATION
###############################################################################
if command -v brew &>/dev/null; then
  eval "$($(command -v brew) shellenv)"
fi


###############################################################################
# 🧰 MISE (POLYGLOT RUNTIME MANAGER)
###############################################################################
if command -v mise &>/dev/null; then
  eval "$(mise activate zsh)"
fi


###############################################################################
# 🌟 STARSHIP PROMPT
###############################################################################
if command -v starship &>/dev/null; then
  eval "$(starship init zsh)"
fi


###############################################################################
# ⚙️  ZSH OPTIONS
###############################################################################
# Configure Zsh behavior for directory stack, history, and editing experience.

# zsh: pushd history duplication restriction
setopt pushd_ignore_dups

# zsh: command history duplication restriction
setopt hist_ignore_all_dups

# zsh: don't add command history if started with 'space'
setopt hist_ignore_space

# zsh: share history between terminals
setopt share_history

# zsh: perform history expansion and reload the line into the editing buffer
setopt hist_verify


###############################################################################
# ✏️  EDITOR SETTINGS
###############################################################################
# Define default text editors for command-line and GUI programs.
export EDITOR='micro'
export VISUAL='micro'


###############################################################################
# ⚙️  ALIASES & FUNCTIONS
###############################################################################
# Utility aliases and helper functions for daily use.

# 🔹 smbname2ip
# Resolve an SMB machine name to its IP address.
# Example:
#   % smbname2ip myserver
#   192.168.1.42
function smbname2ip() {
    if [ $# -ne 1 ]; then
        echo "usage:\n  smbname2ip machine_name"
        return 1
    fi

    local MACHINE_NAME=$1
    smbutil lookup "${MACHINE_NAME}" | tail -1 | tr -d ' ' | rev | cut -d":" -f1 | rev
}

# 🔹 brewdump
# Print the current Homebrew bundle (list of installed packages, casks, and taps)
# directly to standard output instead of saving it to a file.
#
# Example:
#   % brewdump
#   tap "homebrew/core"
#   brew "git"
#   cask "visual-studio-code"
#
# Equivalent to: brew bundle dump --file=/dev/stdout
function brewdump() {
    brew bundle dump --file=/dev/stdout
}

# Compare two list files and show additions (+) and deletions (-)
# Usage:
#   % listdiff old.txt new.txt
#   % listdiff old.txt new.txt --added     # only show added lines
#   % listdiff old.txt new.txt --removed   # only show removed lines
#
# Notes:
# - Files are automatically sorted internally (no need to pre-sort).
# - Output is colorized: red (-) = removed, green (+) = added.
# - For large files, consider LC_ALL=C for faster sorting.
function listdiff() {
  if [[ $# -lt 2 ]]; then
    echo "usage: listdiff old.txt new.txt [--added|--removed]"
    return 1
  fi

  local old="$1"
  local new="$2"
  local mode="$3"
  local flag=""

  case "$mode" in
    --added)   flag="-13" ;;  # show only additions
    --removed) flag="-23" ;;  # show only deletions
  esac

  comm $flag <(LC_ALL=C sort "$old") <(LC_ALL=C sort "$new") \
    | sed -E 's/^\t(.*)/\x1b[32m+\1\x1b[0m/; s/^(.*)/\x1b[31m-\1\x1b[0m/'
}
# Reload Zsh configuration (~/.zshrc)
# Usage:
#   % reload          # Reload the current Zsh configuration
#   % rr              # Short alias for reload (faster to type and avoids conflicts)
#
# Example:
#   % reload
#   Reloading ~/.zshrc...
#   ✅ Reloaded
#
function reload() {
  echo "Reloading ~/.zshrc..."
  source ~/.zshrc
  hash -r
  echo "✅ Reloaded"
}

# Short alias for reload
alias rr='reload'
