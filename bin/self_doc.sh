#!/usr/bin/env bash
set -euo pipefail

trap '[[ "$QUIET" == false ]] && echo "❌ Error occurred on line $LINENO"; exit 1' ERR

# --- Default values ---
VERSION="1.0.5"

IFS=$'\n\t'

# --- Default values ---
TEMPLATE_DIR="tpl"
OUT_FILE="README.md"
DRY_RUN=false
QUIET=false
TREE_SOURCE=""

# --- Dynamic discovery (unless overridden) ---
CLI_BIN="${CLI_BIN:-$(find ./bin -maxdepth 1 -type f -perm +111 | grep -v '\.sh$' | head -n1)}"

if [[ -z "${CLI_BIN:-}" || ! -f "$CLI_BIN" ]]; then
  echo "❌ Could not find CLI binary in ./bin."
  exit 1
fi

VERSION=$(grep -E '^VERSION=' "$CLI_BIN" | cut -d '=' -f2 | tr -d '"')

# --- Fallbacks if not set in vars ---
CLI_NAME="${CLI_NAME:-$(basename "$CLI_BIN")}"
EMOJI="${EMOJI:-🌳}"
TAGLINE="${TAGLINE:-"CLI tool that visualizes and documents folder structures"}"
QUOTE="${QUOTE:-"Structure isn't boring – it's your first line of clarity."}"
QUOTE_AUTHOR="${QUOTE_AUTHOR:-"You (probably during a cleanup)"}"
BREW_LINK="${BREW_LINK:-"https://github.com/raymonepping/homebrew-${CLI_NAME}"}"

TREE_TMP=$(mktemp)

show_help() {
  cat <<EOF
Usage: $0 [options]

Options:
  -t DIR      Template directory (default: tpl)
  -o FILE     Output README file (default: README.md)
  -n          Dry run (don't write output)
  -q          Quiet mode (suppress logs)
  -v          Print version and exit
  -h          Show help and exit

Long flags supported as well: --tpl-dir, --outfile, --dry-run, --quiet, --version, --help
EOF
}

print_version() {
  echo "${CLI_NAME} ${VERSION}"
}

# --- Parse options ---
while [[ $# -gt 0 ]]; do
  case "$1" in
  -t | --tpl-dir)
    TEMPLATE_DIR="$2"
    shift 2
    ;;
  -o | --outfile)
    OUT_FILE="$2"
    shift 2
    ;;
  -n | --dry-run)
    DRY_RUN=true
    shift
    ;;
  -q | --quiet)
    QUIET=true
    shift
    ;;
  -v | --version)
    print_version
    exit 0
    ;;
  -h | --help)
    show_help
    exit 0
    ;;
  *)
    echo "Unknown argument: $1"
    show_help
    exit 1
    ;;
  esac
done

VARS_FILE="${TEMPLATE_DIR}/$(basename "$CLI_BIN" .sh).cli.vars"
if [[ -f "$VARS_FILE" ]]; then
  # shellcheck source=/dev/null
  source "$VARS_FILE"
fi

mapfile -t TEMPLATE_FILES < <(find "$TEMPLATE_DIR" -maxdepth 1 -type f -name 'readme_*.tpl' | sort)
# TEMPLATE_FILES=($(ls "$TEMPLATE_DIR"/readme_*.tpl | sort))

# Template existence check
MISSING_TPL=()
for tpl in "${TEMPLATE_FILES[@]}"; do [[ -f "$tpl" ]] || MISSING_TPL+=("$tpl"); done
if ((${#MISSING_TPL[@]})); then
  echo "❌ Error: One or more template files are missing:"
  for tpl in "${MISSING_TPL[@]}"; do echo "   - $tpl"; done
  exit 1
fi

# TEMPLATE_FILES=($(ls "$TEMPLATE_DIR"/readme_*.tpl 2>/dev/null | sort))

#TEMPLATE_FILES=(
#  "$TEMPLATE_DIR/readme_header.tpl"
#  "$TEMPLATE_DIR/readme_project.tpl"
#  "$TEMPLATE_DIR/readme_structure.tpl"
#  "$TEMPLATE_DIR/readme_body.tpl"
#  "$TEMPLATE_DIR/readme_quote.tpl"
#  "$TEMPLATE_DIR/readme_article.tpl"
#  "$TEMPLATE_DIR/readme_footer.tpl"
#)

generate_folder_tree_block() {

  local raw_tree cleaned_tree
  if command -v folder_tree &>/dev/null; then
    raw_tree=$(folder_tree --hidden)
    TREE_SOURCE="folder_tree"
  elif command -v tree &>/dev/null; then
    raw_tree=$(tree --filesfirst -v)
    TREE_SOURCE="tree"
  else
    raw_tree="(Neither folder_tree nor tree is available in PATH.)\n./\n└── (tree unavailable)"
    TREE_SOURCE="none"
  fi

  cleaned_tree=$(
    echo "$raw_tree" |
      sed -E 's/\x1B\[[0-9;]*[mK]//g' |
      sed -e '/^[[:space:]]*ℹ️/d' \
        -e '/^[[:space:]]*👻/d' \
        -e '/^[[:space:]]*📂/d' \
        -e '/^[[:space:]]*🛡️/d' \
        -e '/tpl\/readme_.*\.tpl/d' \
        -e '/^[[:digit:]]\+ directories, [[:digit:]]\+ files/d'
  )
  echo "$cleaned_tree" >"$TREE_TMP"
}

generate_readme_from_tpl() {
  {
    for tpl in "${TEMPLATE_FILES[@]}"; do
      awk -v cli_name="$CLI_NAME" \
        -v emoji="$EMOJI" \
        -v tagline="$TAGLINE" \
        -v version="$VERSION" \
        -v quote="$QUOTE" \
        -v author="$QUOTE_AUTHOR" \
        -v brew_link="$BREW_LINK" \
        -v tree_file="$TREE_TMP" \
        -v tree_source="$TREE_SOURCE" '
        {
          # Skip internal comments
          if ($0 ~ /^# ---/) next

          gsub("{{CLI_NAME}}", cli_name)
          gsub("{{EMOJI}}", emoji)
          gsub("{{TAGLINE}}", tagline)
          gsub("{{VERSION}}", version)
          gsub("{{QUOTE}}", quote)
          gsub("{{QUOTE_AUTHOR}}", author)
          gsub("{{BREW_LINK}}", brew_link)

          if ($0 ~ /{{FOLDER_TREE}}/) {
            # Insert warning if not folder_tree
            if (tree_source == "tree") {
              print "> ⚠️  **folder_tree CLI not found.** This structure was generated using standard `tree` as fallback."
              print "> \n> To install folder_tree: `brew install raymonepping/folder-tree-cli/folder-tree-cli`"
              print ""
            }
            if (tree_source == "none") {
              print "> ❌ **No tree tool available!** Install either `folder_tree` or `tree` for full functionality."
              print ""
            }
            print "```"
            while ((getline line < tree_file) > 0) print line
            close(tree_file)
            print "```"
          } else {
            print
          }
        }
      ' "$tpl"
    done
  } >"$OUT_FILE"
}

main() {
  [[ "$QUIET" == false ]] && echo "📄 Generating $OUT_FILE using modular templates..."
  generate_folder_tree_block
  if [[ "$DRY_RUN" == true ]]; then
    [[ "$QUIET" == false ]] && echo "🟡 Dry run: Skipping README write."
    cat "$TREE_TMP"
  else
    generate_readme_from_tpl
    [[ "$QUIET" == false ]] && echo "✅ $OUT_FILE generated from templates."
  fi
  rm -f "$TREE_TMP"
}

main "$@"
