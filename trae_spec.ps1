# trae_spec.ps1 - PowerShell 版本的 trae 规范文件管理脚本
# 用法: .\trae_spec.ps1 --path <projectPath> 或 .\trae_spec.ps1 --all [--cn]
# 也支持: .\trae_spec.ps1 -Path <projectPath> 或 .\trae_spec.ps1 -All [-Cn]

# 手动解析参数以支持 -- 和 - 前缀
$Path = $null
$All = $false
$Cn = $false

# 检查参数
if ($args.Count -eq 0) {
    Write-Host "错误: 缺少参数" -ForegroundColor Red
    Write-Host ""
    Write-Host "用法:" -ForegroundColor Cyan
    Write-Host "  .\trae_spec.ps1 --path <projectPath>" -ForegroundColor White
    Write-Host "  .\trae_spec.ps1 --all [--cn]" -ForegroundColor White
    Write-Host ""
    exit 1
}

# 解析参数
for ($i = 0; $i -lt $args.Count; $i++) {
    $arg = $args[$i]
    
    if ($arg -eq "--path" -or $arg -eq "-Path") {
        if ($i + 1 -lt $args.Count) {
            $Path = $args[$i + 1]
            $i++  # 跳过下一个参数（路径值）
        } else {
            Write-Host "错误: --path 参数需要项目路径" -ForegroundColor Red
            exit 1
        }
    }
    elseif ($arg -eq "--all" -or $arg -eq "-All") {
        $All = $true
    }
    elseif ($arg -eq "--cn" -or $arg -eq "-Cn") {
        $Cn = $true
    }
}

# 定义需要处理的文件列表
$SpecFiles = @("requirements_spec.md", "design_spec.md", "tasks_spec.md")
$TraeRulesFile = "trae_rules.md"
$ScriptDir = "c:\work\tools\traeSpec"

Write-Host "[INFO] trae_spec.ps1 开始执行" -ForegroundColor Green
Write-Host "[INFO] 参数: Path=$Path, All=$All, Cn=$Cn" -ForegroundColor Yellow
Write-Host "[INFO] 当前目录: $PWD" -ForegroundColor Yellow

# 检查参数
if (-not $Path -and -not $All) {
    Write-Host "错误: 缺少参数" -ForegroundColor Red
    Write-Host ""
    Write-Host "用法:" -ForegroundColor Cyan
    Write-Host "  .\trae_spec.ps1 --path <projectPath>" -ForegroundColor White
    Write-Host "  .\trae_spec.ps1 --all" -ForegroundColor White
    Write-Host ""
    exit 1
}

if ($Path -and $All) {
    Write-Host "错误: 不能同时使用 --path 和 --all 参数" -ForegroundColor Red
    exit 1
}

# 处理 --path 参数
if ($Path) {
    Write-Host "[INFO] 检测到 --path 参数" -ForegroundColor Green
    Write-Host "[INFO] 项目路径: $Path" -ForegroundColor Yellow
    
    # 检查项目路径是否存在
    if (-not (Test-Path $Path)) {
        Write-Host "错误: 项目路径不存在: $Path" -ForegroundColor Red
        exit 1
    }
    
    # 创建 .trae/rules 目录
    $RulesDir = Join-Path $Path ".trae\rules"
    if (-not (Test-Path $RulesDir)) {
        try {
            New-Item -ItemType Directory -Path $RulesDir -Force | Out-Null
            Write-Host "[INFO] 创建目录: $RulesDir" -ForegroundColor Green
        }
        catch {
            Write-Host "错误: 无法创建目录 $RulesDir" -ForegroundColor Red
            exit 1
        }
    }
    
    # 处理三个规范文件（直接覆盖）
    foreach ($File in $SpecFiles) {
        $SourceFile = Join-Path $ScriptDir $File
        $TargetFile = Join-Path $RulesDir $File
        
        # 检查源文件是否存在
        if (-not (Test-Path $SourceFile)) {
            Write-Host "警告: 源文件不存在: $SourceFile" -ForegroundColor Yellow
            continue
        }
        
        # 直接复制规范文件（覆盖已存在的文件）
        try {
            Copy-Item -Path $SourceFile -Destination $TargetFile -Force
            Write-Host "[INFO] 复制文件: $SourceFile -> $TargetFile" -ForegroundColor Green
        }
        catch {
            Write-Host "错误: 无法复制文件 $SourceFile -> $TargetFile" -ForegroundColor Red
        }
    }
    
    # 特殊处理 trae_rules.md -> project_rules.md
    $SourceFile = Join-Path $ScriptDir $TraeRulesFile
    $TargetFile = Join-Path $RulesDir "project_rules.md"
    
    # 检查源文件是否存在
    if (-not (Test-Path $SourceFile)) {
        Write-Host "警告: 源文件不存在: $SourceFile" -ForegroundColor Yellow
    }
    else {
        # 检查目标文件是否存在
        if (Test-Path $TargetFile) {
            Write-Host "[INFO] 目标文件已存在，智能更新内容: $TargetFile" -ForegroundColor Yellow
            try {
                # 读取目标文件内容
                $targetContent = Get-Content -Path $TargetFile -Raw
                $sourceContent = Get-Content -Path $SourceFile -Raw
                
                # 定义标记
                $startMarker = "<!-- trae_rules.md start -->"
                $endMarker = "<!-- trae_rules.md end -->"
                
                # 检查是否已存在标记
                if ($targetContent -match [regex]::Escape($startMarker) -and $targetContent -match [regex]::Escape($endMarker)) {
                    # 替换标记之间的内容
                    $pattern = "(?s)$([regex]::Escape($startMarker)).*?$([regex]::Escape($endMarker))"
                    $newContent = $startMarker + "`n" + $sourceContent + "`n" + $endMarker
                    $targetContent = $targetContent -replace $pattern, $newContent
                    
                    Set-Content -Path $TargetFile -Value $targetContent
                    Write-Host "[INFO] 已替换标记内容到 $TargetFile" -ForegroundColor Green
                }
                else {
                    # 如果不存在标记，则追加内容
                    Add-Content -Path $TargetFile -Value ""
                    Add-Content -Path $TargetFile -Value "# 以下内容来自 trae_rules.md"
                    Add-Content -Path $TargetFile -Value ""
                    Add-Content -Path $TargetFile -Value $startMarker
                    Add-Content -Path $TargetFile -Value $sourceContent
                    Add-Content -Path $TargetFile -Value $endMarker
                    Write-Host "[INFO] 已追加内容到 $TargetFile" -ForegroundColor Green
                }
            }
            catch {
                Write-Host "错误: 无法更新内容到 $TargetFile" -ForegroundColor Red
            }
        }
        else {
            try {
                # 第一次复制时，添加标记
                $sourceContent = Get-Content -Path $SourceFile -Raw
                $startMarker = "<!-- trae_rules.md start -->"
                $endMarker = "<!-- trae_rules.md end -->"
                $markedContent = $startMarker + "`n" + $sourceContent + "`n" + $endMarker
                
                Set-Content -Path $TargetFile -Value $markedContent
                Write-Host "[INFO] 复制文件并添加标记: $SourceFile -> $TargetFile" -ForegroundColor Green
            }
            catch {
                Write-Host "错误: 无法复制文件 $SourceFile -> $TargetFile" -ForegroundColor Red
            }
        }
    }
    
    Write-Host ""
    Write-Host "完成: 所有规范文件已处理到项目路径 $Path" -ForegroundColor Green
}

# 处理 --all 参数
if ($All) {
    Write-Host "[INFO] 检测到 --all 参数" -ForegroundColor Green
    
    # 获取用户主目录
    $UserHome = $env:USERPROFILE
    Write-Host "[INFO] 用户主目录: $UserHome" -ForegroundColor Yellow
    
    # 根据 --cn 参数选择目录
    if ($Cn) {
        Write-Host "[INFO] 检测到 --cn 参数，使用 ~/.trae-cn 目录" -ForegroundColor Green
        $UserRulesDir = Join-Path $UserHome ".trae-cn"
    } else {
        Write-Host "[INFO] 未检测到 --cn 参数，使用 ~/.trae 目录" -ForegroundColor Green
        $UserRulesDir = Join-Path $UserHome ".trae"
    }
    if (-not (Test-Path $UserRulesDir)) {
        try {
            New-Item -ItemType Directory -Path $UserRulesDir -Force | Out-Null
            Write-Host "[INFO] 创建目录: $UserRulesDir" -ForegroundColor Green
        }
        catch {
            Write-Host "错误: 无法创建目录 $UserRulesDir" -ForegroundColor Red
            exit 1
        }
    }
    
    # 处理三个规范文件（直接覆盖）
    foreach ($File in $SpecFiles) {
        $SourceFile = Join-Path $ScriptDir $File
        $TargetFile = Join-Path $UserRulesDir $File
        
        # 检查源文件是否存在
        if (-not (Test-Path $SourceFile)) {
            Write-Host "警告: 源文件不存在: $SourceFile" -ForegroundColor Yellow
            continue
        }
        
        # 直接复制规范文件（覆盖已存在的文件）
        try {
            Copy-Item -Path $SourceFile -Destination $TargetFile -Force
            Write-Host "[INFO] 复制文件: $SourceFile -> $TargetFile" -ForegroundColor Green
        }
        catch {
            Write-Host "错误: 无法复制文件 $SourceFile -> $TargetFile" -ForegroundColor Red
        }
    }
    
    # 特殊处理 trae_rules.md -> user_rules.md
    $SourceFile = Join-Path $ScriptDir $TraeRulesFile
    $TargetFile = Join-Path $UserRulesDir "user_rules.md"
    
    # 检查源文件是否存在
    if (-not (Test-Path $SourceFile)) {
        Write-Host "警告: 源文件不存在: $SourceFile" -ForegroundColor Yellow
    }
    else {
        # 检查目标文件是否存在
        if (Test-Path $TargetFile) {
            Write-Host "[INFO] 目标文件已存在，智能更新内容: $TargetFile" -ForegroundColor Yellow
            try {
                # 读取目标文件内容
                $targetContent = Get-Content -Path $TargetFile -Raw
                $sourceContent = Get-Content -Path $SourceFile -Raw
                
                # 定义标记
                $startMarker = "<!-- trae_rules.md start -->"
                $endMarker = "<!-- trae_rules.md end -->"
                
                # 检查是否已存在标记
                if ($targetContent -match [regex]::Escape($startMarker) -and $targetContent -match [regex]::Escape($endMarker)) {
                    # 替换标记之间的内容
                    $pattern = "(?s)$([regex]::Escape($startMarker)).*?$([regex]::Escape($endMarker))"
                    $newContent = $startMarker + "`n" + $sourceContent + "`n" + $endMarker
                    $targetContent = $targetContent -replace $pattern, $newContent
                    
                    Set-Content -Path $TargetFile -Value $targetContent
                    Write-Host "[INFO] 已替换标记内容到 $TargetFile" -ForegroundColor Green
                }
                else {
                    # 如果不存在标记，则追加内容
                    Add-Content -Path $TargetFile -Value ""
                    Add-Content -Path $TargetFile -Value "# 以下内容来自 trae_rules.md"
                    Add-Content -Path $TargetFile -Value ""
                    Add-Content -Path $TargetFile -Value $startMarker
                    Add-Content -Path $TargetFile -Value $sourceContent
                    Add-Content -Path $TargetFile -Value $endMarker
                    Write-Host "[INFO] 已追加内容到 $TargetFile" -ForegroundColor Green
                }
            }
            catch {
                Write-Host "错误: 无法更新内容到 $TargetFile" -ForegroundColor Red
            }
        }
        else {
            try {
                # 第一次复制时，添加标记
                $sourceContent = Get-Content -Path $SourceFile -Raw
                $startMarker = "<!-- trae_rules.md start -->"
                $endMarker = "<!-- trae_rules.md end -->"
                $markedContent = $startMarker + "`n" + $sourceContent + "`n" + $endMarker
                
                Set-Content -Path $TargetFile -Value $markedContent
                Write-Host "[INFO] 复制文件并添加标记: $SourceFile -> $TargetFile" -ForegroundColor Green
            }
            catch {
                Write-Host "错误: 无法复制文件 $SourceFile -> $TargetFile" -ForegroundColor Red
            }
        }
    }
    
    Write-Host ""
    Write-Host "完成: 所有规范文件已处理到用户目录 $UserRulesDir" -ForegroundColor Green
}

Write-Host ""
Write-Host "trae_spec.ps1 脚本执行完成！" -ForegroundColor Green