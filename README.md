# TraeSpec 工具

TraeSpec 在 trae 中实现类似于 kiro 中的 spec 编程。

## 更新日志

- 2026-01-16 新增 `--skill` 参数支持，用于将 SKILL.md 部署到项目的 `.trae/skills/spec` 目录。
- 2026-01-10 在脚本中增加了标签 ```<!-- trae_rules.md start -->```，方便后续版本更新时替换trae规则
- 改版本修改，是为了方便之后的版本更新。
- 改版本更新说明
```

# 交流反馈

+ 如果有问题，建议或者需要，可以进 QQ群: 661990120 交流。

# 使用说明
# 也可以手动删除trae规则中相关的规则，或者修改添加标签
# 后续 ./trae_spec.sh 命令或自动添加标签，自动替换标签内的规则
# windows 使用 deal_old.ps1、deal_old.bat 命令处理

# 处理之前的版本中的规则
# 添加 <!-- trae_rules.md start -->、<!-- trae_rules.md end -->
deal_old.sh --path <项目路径>  

# 处理之前的版本中的规则，处理 ~/.trae、~/.trae-cn中的规则
deal_old.sh --all 
```

## 功能特性

- 在 trae 中实现类似于 kiro 中的 spec 编程
- 使用脚本想 trae 规则中添加 TraeSpec 规则。

## TraeSpec 规则文件要点

1. **需求文档**：根据 `requirements_spec.md` 的描述生成 `requirements.md`
2. **设计文档**：根据 `design_spec.md` 的描述生成 `design.md`
3. **任务文档**：根据 `tasks_spec.md` 的描述生成 `tasks.md`
4. **代码生成**：确认任务文档后，开始生成代码

- 每次spec任务，必须先创建一个子目录，子目录名称采用 kebab-case 格式
- 生成 `requirements.md` 后，必须通过用户确认后，才能生成 `design.md`
- 生成 `design.md` 后，必须通过用户确认后，才能生成 `tasks.md`
- 生成 `tasks.md` 后，必须通过用户确认后，才能生成代码

## TraeSpec 规范文档

- `requirements_spec.md`：需求文档规范参考
- `design_spec.md`：设计文档规范参考
- `tasks_spec.md`：任务文档规范参考

## 脚本使用说明

TraeSpec 提供了多个平台的执行脚本：

- `trae_spec.bat`：Windows 批处理脚本
- `trae_spec.ps1`：PowerShell 脚本
- `trae_spec.sh`：Unix/Linux shell 脚本

### 使用方法

在项目根目录下运行相应的脚本：

#### Windows 系统
```cmd
trae_spec.bat [参数]
```

#### PowerShell
```powershell
.\trae_spec.ps1 [参数]
```

#### Unix/Linux 系统
```bash
./trae_spec.sh [参数]
```

### 脚本参数说明

- `--path <项目路径>` 或 `-Path <项目路径>`：指定项目路径，用于在指定项目中创建规范文件
- `--skill` 或 `-Skill`：与 --path 参数配合使用，仅将技能文件 SKILL.md 复制到项目目录（.trae/skills/spec），不处理规则文件
- `--all` 或 `-All`：将规范文件复制到用户目录（~/.trae 或 ~/.trae-cn）
- `--cn` 或 `-Cn`：与 --all 参数配合使用，将规范文件复制到中文用户目录（~/.trae-cn）

### 示例用法

#### 为指定项目创建规范文件
```bash
./trae_spec.sh --path /path/to/your/project
```

#### 将规范文件复制到国际版用户目录
```bash
./trae_spec.sh --all
```

#### 将规范文件复制到国内版用户目录
```bash
./trae_spec.sh --all --cn
```

#### 为项目部署 SKILL.md 技能文件
```bash
./trae_spec.sh --path /path/to/your/project --skill
```

#### 使用简写参数
```bash
./trae_spec.sh -Path /path/to/your/project
./trae_spec.sh -All -Cn
```

### 脚本功能

这些脚本的主要功能包括：
- 将规范文件（requirements_spec.md, design_spec.md, tasks_spec.md）复制到指定项目或用户目录
- 支持部署 Trae Spec 技能文件（SKILL.md）到项目目录
- 自动创建必要的目录结构（.trae/rules 或 .trae/skills/spec）
- 特殊处理 trae_rules.md 文件（复制为 project_rules.md 或追加到现有文件）
- 支持多平台参数格式（-- 和 - 前缀）