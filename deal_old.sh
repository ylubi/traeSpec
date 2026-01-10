#!/bin/bash

# deal_old.sh - Checks and wraps old rules content with markers
# Usage: ./deal_old.sh --path <projectPath> or ./deal_old.sh --all

# Define colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OLD_RULES_FILE="$SCRIPT_DIR/trae_rules_old.md"

if [ ! -f "$OLD_RULES_FILE" ]; then
    echo -e "${RED}Error: $OLD_RULES_FILE not found${NC}"
    exit 1
fi

# Create awk script
AWK_SCRIPT=$(mktemp)
cat << 'EOF' > "$AWK_SCRIPT"
BEGIN {
    # Read old rules content
    old_content = ""
    while ((getline line < old_rules_file) > 0) {
        old_content = old_content line "\n"
    }
    close(old_rules_file)
}

{
    # Read target file content into memory
    target_content = target_content $0 "\n"
}

END {
    start_marker = "<!-- trae_rules.md start -->"
    end_marker = "<!-- trae_rules.md end -->"
    
    # Try to find old_content in target_content
    pos = index(target_content, old_content)
    
    # If not found, try stripping the last newline from old_content
    if (pos == 0) {
        if (substr(old_content, length(old_content)) == "\n") {
             temp_content = substr(old_content, 1, length(old_content) - 1)
             pos = index(target_content, temp_content)
             if (pos > 0) {
                 old_content = temp_content
             }
        }
    }

    if (pos > 0) {
        # Check surroundings
        before = substr(target_content, 1, pos - 1)
        after = substr(target_content, pos + length(old_content))
        
        is_wrapped = 0
        
        # Check if "before" ends with start marker (ignoring trailing spaces/newlines)
        if (match(before, /<!-- trae_rules\.md start -->[[:space:]]*$/)) {
            # Check if "after" starts with end marker (ignoring leading spaces/newlines)
            if (match(after, /^[[:space:]]*<!-- trae_rules\.md end -->/)) {
                is_wrapped = 1
            }
        }
        
        if (is_wrapped) {
            print "[INFO] Content found but already wrapped." > "/dev/stderr"
            printf "%s", target_content
        } else {
            print "[INFO] Found unwrapped old content. Wrapping it now." > "/dev/stderr"
            
            # Print Part 1: before
            printf "%s", substr(target_content, 1, pos - 1)
            
            # Ensure a newline before start marker if needed
            if (pos > 1 && substr(target_content, pos-1, 1) != "\n") {
                print ""
            }
            
            print start_marker
            
            # Print content
            printf "%s", old_content
            
            # Ensure newline after content if not present
            if (substr(old_content, length(old_content)) != "\n") {
                print ""
            }
            
            print end_marker
            
            # Print Part 2: after
            printf "%s", substr(target_content, pos + length(old_content))
        }
    } else {
        print "[INFO] Old content not found." > "/dev/stderr"
        printf "%s", target_content
    }
}
EOF

process_file() {
    local target_file="$1"
    
    if [ ! -f "$target_file" ]; then
        echo -e "${YELLOW}[WARN] File not found: $target_file${NC}"
        return
    fi
    
    echo -e "${GREEN}[INFO] Processing file: $target_file${NC}"
    
    # Execute awk script
    local temp_file="${target_file}.tmp"
    awk -v old_rules_file="$OLD_RULES_FILE" -f "$AWK_SCRIPT" "$target_file" > "$temp_file"

    if [ $? -eq 0 ]; then
        # Check if file changed (optional, but awk prints everything anyway)
        # We can just move it back.
        mv "$temp_file" "$target_file"
        echo -e "${GREEN}[INFO] Processed $target_file${NC}"
    else
        echo -e "${RED}[ERROR] Failed to process $target_file${NC}"
        rm -f "$temp_file"
    fi
}

# Cleanup on exit
trap 'rm -f "$AWK_SCRIPT"' EXIT

# Argument parsing
PATH_ARG=""
ALL=false

if [ $# -eq 0 ]; then
    echo -e "${RED}Error: Missing arguments${NC}"
    echo -e "${CYAN}Usage:${NC}"
    echo -e "  ${WHITE}./deal_old.sh --path <projectPath>${NC}"
    echo -e "  ${WHITE}./deal_old.sh --all${NC}"
    echo -e "  ${WHITE}Note: Also supports -Path and -All${NC}"
    exit 1
fi

while [[ $# -gt 0 ]]; do
    case $1 in
        --path|-Path)
            if [[ -n "$2" ]]; then
                PATH_ARG="$2"
                shift 2
            else
                echo -e "${RED}Error: $1 requires an argument${NC}"
                exit 1
            fi
            ;;
        --all|-All)
            ALL=true
            shift
            ;;
        *)
            echo -e "${RED}Error: Unknown argument $1${NC}"
            exit 1
            ;;
    esac
done

if [[ -n "$PATH_ARG" ]]; then
    echo -e "${GREEN}[INFO] Processing project path: $PATH_ARG${NC}"
    # Project file: .trae/rules/project_rules.md
    TARGET="$PATH_ARG/.trae/rules/project_rules.md"
    process_file "$TARGET"
fi

if [[ "$ALL" == true ]]; then
    echo -e "${GREEN}[INFO] Processing user directories${NC}"
    USER_HOME="$HOME"
    
    # ~/.trae/user_rules.md
    TARGET_TRAE="$USER_HOME/.trae/user_rules.md"
    process_file "$TARGET_TRAE"
    
    # ~/.trae-cn/user_rules.md
    TARGET_TRAE_CN="$USER_HOME/.trae-cn/user_rules.md"
    process_file "$TARGET_TRAE_CN"
fi
