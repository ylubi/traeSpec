#!/bin/bash

# trae_spec.sh - Shell 版本的 trae 规范文件管理脚本
# 用法: ./trae_spec.sh --path <projectPath> 或 ./trae_spec.sh --all [--cn]
# 也支持: ./trae_spec.sh -Path <projectPath> 或 ./trae_spec.sh -All [-Cn]

# 定义颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# 初始化变量
PATH_ARG=""
ALL=false
CN=false
SKILL=false

# ==========================================
# 辅助函数
# ==========================================

process_rules_file() {
    local src="$1"
    local tgt="$2"
    local start_marker="<!-- trae_rules.md start -->"
    local end_marker="<!-- trae_rules.md end -->"

    if [[ ! -f "$tgt" ]]; then
        # Create new with markers
        echo -e "${GREEN}[INFO] Creating file with markers: $src -> $tgt${NC}"
        echo "$start_marker" > "$tgt"
        cat "$src" >> "$tgt"
        echo "" >> "$tgt"
        echo "$end_marker" >> "$tgt"
        return 0
    fi

    # Check markers
    if grep -Fq "$start_marker" "$tgt" && grep -Fq "$end_marker" "$tgt"; then
        echo -e "${GREEN}[INFO] Target file already exists, updating content between markers: $tgt${NC}"
        local temp_file="${tgt}.tmp"
        
        # Use awk to replace
        awk -v start="$start_marker" -v end="$end_marker" -v src_file="$src" '
        BEGIN { copying = 1 }
        index($0, start) > 0 {
            print $0
            while ((getline line < src_file) > 0) {
                print line
            }
            close(src_file)
            print ""
            copying = 0
            next
        }
        index($0, end) > 0 {
            copying = 1
            print $0
            next
        }
        copying { print }
        ' "$tgt" > "$temp_file"

        mv "$temp_file" "$tgt"
        echo -e "${GREEN}[INFO] Updated content in $tgt${NC}"
    else
        echo -e "${YELLOW}[INFO] Target file already exists, appending content to: $tgt${NC}"
        echo "" >> "$tgt"
        echo "$start_marker" >> "$tgt"
        cat "$src" >> "$tgt"
        echo "" >> "$tgt"
        echo "$end_marker" >> "$tgt"
        echo -e "${GREEN}[INFO] Appended content to $tgt${NC}"
    fi
}

# 检查参数
if [ $# -eq 0 ]; then
    echo -e "${RED}错误: 缺少参数${NC}"
    echo ""
    echo -e "${CYAN}用法:${NC}"
    echo -e "  ${WHITE}./trae_spec.sh --path <projectPath>${NC}"
    echo -e "  ${WHITE}./trae_spec.sh --all [--cn]${NC}"
    echo ""
    exit 1
fi

# 解析参数
while [[ $# -gt 0 ]]; do
    case $1 in
        --path|-Path)
            if [[ -n "$2" ]]; then
                PATH_ARG="$2"
                shift 2
            else
                echo -e "${RED}错误: --path 参数需要项目路径${NC}"
                exit 1
            fi
            ;;
        --all|-All)
            ALL=true
            shift
            ;;
        --cn|-Cn)
            CN=true
            shift
            ;;
        --skill|-Skill)
            SKILL=true
            shift
            ;;
        *)
            echo -e "${RED}错误: 未知参数 $1${NC}"
            echo ""
            echo -e "${CYAN}用法:${NC}"
            echo -e "  ${WHITE}./trae_spec.sh --path <projectPath>${NC}"
            echo -e "  ${WHITE}./trae_spec.sh --all [--cn]${NC}"
            echo ""
            exit 1
            ;;
    esac
done

# 定义需要处理的文件列表
SPEC_FILES=("requirements_spec.md" "design_spec.md" "tasks_spec.md")
TRAE_RULES_FILE="trae_rules.md"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${GREEN}[INFO] trae_spec.sh 开始执行${NC}"
echo -e "${YELLOW}[INFO] 参数: Path=${PATH_ARG}, All=${ALL}, Cn=${CN}, Skill=${SKILL}${NC}"
echo -e "${YELLOW}[INFO] 当前目录: $PWD${NC}"

# 检查参数
if [[ -z "$PATH_ARG" && "$ALL" == false ]]; then
    echo -e "${RED}错误: 缺少参数${NC}"
    echo ""
    echo -e "${CYAN}用法:${NC}"
    echo -e "  ${WHITE}./trae_spec.sh --path <projectPath>${NC}"
    echo -e "  ${WHITE}./trae_spec.sh --all${NC}"
    echo ""
    exit 1
fi

if [[ -n "$PATH_ARG" && "$ALL" == true ]]; then
    echo -e "${RED}错误: 不能同时使用 --path 和 --all 参数${NC}"
    exit 1
fi

# 处理 --path 参数
if [[ -n "$PATH_ARG" ]]; then
    echo -e "${GREEN}[INFO] 检测到 --path 参数${NC}"
    echo -e "${YELLOW}[INFO] 项目路径: $PATH_ARG${NC}"
    
    # 检查项目路径是否存在
    if [[ ! -d "$PATH_ARG" ]]; then
        echo -e "${RED}错误: 项目路径不存在: $PATH_ARG${NC}"
        exit 1
    fi

    if [[ "$SKILL" == true ]]; then
        echo -e "${GREEN}[INFO] 检测到 --skill 参数，将复制 SKILL.md${NC}"
        
        # 创建 .trae/skills/spec 目录
        SKILL_DIR="$PATH_ARG/.trae/skills/spec"
        if [[ ! -d "$SKILL_DIR" ]]; then
            mkdir -p "$SKILL_DIR"
            if [[ $? -eq 0 ]]; then
                echo -e "${GREEN}[INFO] 创建目录: $SKILL_DIR${NC}"
            else
                echo -e "${RED}错误: 无法创建目录 $SKILL_DIR${NC}"
                exit 1
            fi
        fi
        
        # 复制 SKILL.md
        SOURCE_FILE="$SCRIPT_DIR/skills/TraeSpec/SKILL.md"
        TARGET_FILE="$SKILL_DIR/SKILL.md"
        
        if [[ ! -f "$SOURCE_FILE" ]]; then
            echo -e "${RED}错误: 源文件不存在: $SOURCE_FILE${NC}"
            exit 1
        fi
        
        cp "$SOURCE_FILE" "$TARGET_FILE"
        if [[ $? -eq 0 ]]; then
            echo -e "${GREEN}[INFO] 复制文件: $SOURCE_FILE -> $TARGET_FILE${NC}"
        else
            echo -e "${RED}错误: 无法复制文件 $SOURCE_FILE -> $TARGET_FILE${NC}"
            exit 1
        fi
        
        echo ""
        echo -e "${GREEN}完成: SKILL.md 已处理到项目路径 $PATH_ARG${NC}"
        exit 0
    fi
    
    # 创建 .trae/rules 目录
    RULES_DIR="$PATH_ARG/.trae/rules"
    if [[ ! -d "$RULES_DIR" ]]; then
        mkdir -p "$RULES_DIR"
        if [[ $? -eq 0 ]]; then
            echo -e "${GREEN}[INFO] 创建目录: $RULES_DIR${NC}"
        else
            echo -e "${RED}错误: 无法创建目录 $RULES_DIR${NC}"
            exit 1
        fi
    fi
    
    # 处理三个规范文件（直接覆盖）
    for FILE in "${SPEC_FILES[@]}"; do
        SOURCE_FILE="$SCRIPT_DIR/rules/$FILE"
        TARGET_FILE="$RULES_DIR/$FILE"
        
        # 检查源文件是否存在
        if [[ ! -f "$SOURCE_FILE" ]]; then
            echo -e "${YELLOW}警告: 源文件不存在: $SOURCE_FILE${NC}"
            continue
        fi
        
        # 直接复制规范文件（覆盖已存在的文件）
        cp "$SOURCE_FILE" "$TARGET_FILE"
        if [[ $? -eq 0 ]]; then
            echo -e "${GREEN}[INFO] 复制文件: $SOURCE_FILE -> $TARGET_FILE${NC}"
        else
            echo -e "${RED}错误: 无法复制文件 $SOURCE_FILE -> $TARGET_FILE${NC}"
        fi
    done
    
    # 特殊处理 trae_rules.md -> project_rules.md
    SOURCE_FILE="$SCRIPT_DIR/rules/$TRAE_RULES_FILE"
    TARGET_FILE="$RULES_DIR/project_rules.md"
    
    # 检查源文件是否存在
    if [[ ! -f "$SOURCE_FILE" ]]; then
        echo -e "${YELLOW}警告: 源文件不存在: $SOURCE_FILE${NC}"
    else
        process_rules_file "$SOURCE_FILE" "$TARGET_FILE"
    fi
    
    echo ""
    echo -e "${GREEN}完成: 所有规范文件已处理到项目路径 $PATH_ARG${NC}"
fi

# 处理 --all 参数
if [[ "$ALL" == true ]]; then
    echo -e "${GREEN}[INFO] 检测到 --all 参数${NC}"
    
    # 获取用户主目录
    USER_HOME="$HOME"
    echo -e "${YELLOW}[INFO] 用户主目录: $USER_HOME${NC}"
    
    # 根据 --cn 参数选择目录
    if [[ "$CN" == true ]]; then
        echo -e "${GREEN}[INFO] 检测到 --cn 参数，使用 ~/.trae-cn 目录${NC}"
        USER_RULES_DIR="$USER_HOME/.trae-cn"
    else
        echo -e "${GREEN}[INFO] 未检测到 --cn 参数，使用 ~/.trae 目录${NC}"
        USER_RULES_DIR="$USER_HOME/.trae"
    fi
    
    if [[ ! -d "$USER_RULES_DIR" ]]; then
        mkdir -p "$USER_RULES_DIR"
        if [[ $? -eq 0 ]]; then
            echo -e "${GREEN}[INFO] 创建目录: $USER_RULES_DIR${NC}"
        else
            echo -e "${RED}错误: 无法创建目录 $USER_RULES_DIR${NC}"
            exit 1
        fi
    fi
    
    # 处理三个规范文件（直接覆盖）
    for FILE in "${SPEC_FILES[@]}"; do
        SOURCE_FILE="$SCRIPT_DIR/rules/$FILE"
        TARGET_FILE="$USER_RULES_DIR/$FILE"
        
        # 检查源文件是否存在
        if [[ ! -f "$SOURCE_FILE" ]]; then
            echo -e "${YELLOW}警告: 源文件不存在: $SOURCE_FILE${NC}"
            continue
        fi
        
        # 直接复制规范文件（覆盖已存在的文件）
        cp "$SOURCE_FILE" "$TARGET_FILE"
        if [[ $? -eq 0 ]]; then
            echo -e "${GREEN}[INFO] 复制文件: $SOURCE_FILE -> $TARGET_FILE${NC}"
        else
            echo -e "${RED}错误: 无法复制文件 $SOURCE_FILE -> $TARGET_FILE${NC}"
        fi
    done
    
    # 特殊处理 trae_rules.md -> user_rules.md
    SOURCE_FILE="$SCRIPT_DIR/rules/$TRAE_RULES_FILE"
    TARGET_FILE="$USER_RULES_DIR/user_rules.md"
    
    # 检查源文件是否存在
    if [[ ! -f "$SOURCE_FILE" ]]; then
        echo -e "${YELLOW}警告: 源文件不存在: $SOURCE_FILE${NC}"
    else
        process_rules_file "$SOURCE_FILE" "$TARGET_FILE"
    fi
    
    echo ""
    echo -e "${GREEN}完成: 所有规范文件已处理到用户目录 $USER_RULES_DIR${NC}"
fi

echo ""
echo -e "${GREEN}trae_spec.sh 脚本执行完成！${NC}"