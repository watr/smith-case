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

# 🔹 cot
# Wrapper for CotEditor's bundled CLI.
# Behaves like the real "cot" command without creating a symlink.
# Example:
#   % cot file.txt
#   (opens file.txt in CotEditor)
function cot() {
    local app="/Applications/CotEditor.app"
    local cli="$app/Contents/SharedSupport/bin/cot"

    if [[ -x "$cli" ]]; then
        "$cli" "$@"
        return $?
    else
        echo "❌ CotEditorのcotコマンドが見つかりませんでした。" >&2
        echo "   CotEditor.app が /Applications にあるか確認してください。" >&2
        return 1
    fi
}

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

# Compare two list files and show additions (+) and deletions (-) with colors
# Usage:
#   % listdiff old.txt new.txt [--added] [--removed] [--print]
# Examples:
#   % listdiff Brewfile <(brewdump)
#   % listdiff Brewfile <(brewdump) --added
#   % listdiff Brewfile <(brewdump) --removed --print
function listdiff() {
  if [[ $# -lt 2 ]]; then
    echo "usage: listdiff old.txt new.txt [--added] [--removed] [--print]"
    return 1
  fi

  local old="$1"
  local new="$2"
  shift 2
  local show_added=true
  local show_removed=true
  local print_sorted=false

  # Parse flags
  for arg in "$@"; do
    case "$arg" in
      --added)
        show_removed=false ;;
      --removed)
        show_added=false ;;
      --print)
        print_sorted=true ;;
      *)
        echo "error: unknown option '$arg'" >&2
        return 1 ;;
    esac
  done

  # ANSI colors (Git standard style)
  local red="\033[31m"
  local green="\033[32m"
  local reset="\033[0m"

  # Normalize & sort each input (remove empty lines and comments)
  local old_sorted new_sorted
  old_sorted=$(awk '!/^($|#)/ {print}' "$old" | sort -u)
  new_sorted=$(awk '!/^($|#)/ {print}' "$new" | sort -u)

  # Print sorted output
  if $print_sorted; then
    echo "----- OLD (sorted) -----"
    printf '%s\n' "$old_sorted"
    echo "----- NEW (sorted) -----"
    printf '%s\n' "$new_sorted"
    echo "------------------------"
  fi

  # Removed (-): lines in old but not in new
  if $show_removed; then
    while IFS= read -r line; do
      if ! grep -Fxq "$line" <<<"$new_sorted"; then
        printf "${red}-%s${reset}\n" "$line"
      fi
    done <<<"$old_sorted"
  fi

  # Added (+): lines in new but not in old
  if $show_added; then
    while IFS= read -r line; do
      if ! grep -Fxq "$line" <<<"$old_sorted"; then
        printf "${green}+%s${reset}\n" "$line"
      fi
    done <<<"$new_sorted"
  fi
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
