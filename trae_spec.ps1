# trae_spec.ps1 - PowerShell version of trae specification file management script
# Usage: .\trae_spec.ps1 --path <projectPath> or .\trae_spec.ps1 --all [--cn]
# Also supports: .\trae_spec.ps1 -Path <projectPath> or .\trae_spec.ps1 -All [-Cn]

# Manual argument parsing to support -- and - prefixes
$Path = $null
$All = $false
$Cn = $false
$Skill = $false

# Check arguments
if ($args.Count -eq 0) {
    Write-Host "Error: Missing arguments" -ForegroundColor Red
    Write-Host ""
    Write-Host "Usage:" -ForegroundColor Cyan
    Write-Host "  .\trae_spec.ps1 --path <projectPath>" -ForegroundColor White
    Write-Host "  .\trae_spec.ps1 --all [--cn]" -ForegroundColor White
    Write-Host ""
    exit 1
}

# Parse arguments
for ($i = 0; $i -lt $args.Count; $i++) {
    $arg = $args[$i]
    
    if ($arg -eq "--path" -or $arg -eq "-Path") {
        if ($i + 1 -lt $args.Count) {
            $Path = $args[$i + 1]
            $i++  # Skip next argument (path value)
        } else {
            Write-Host "Error: --path argument requires a project path" -ForegroundColor Red
            exit 1
        }
    }
    elseif ($arg -eq "--all" -or $arg -eq "-All") {
        $All = $true
    }
    elseif ($arg -eq "--cn" -or $arg -eq "-Cn") {
        $Cn = $true
    }
    elseif ($arg -eq "--skill" -or $arg -eq "-Skill") {
        $Skill = $true
    }
}

# Define list of files to process
$SpecFiles = @("requirements_spec.md", "design_spec.md", "tasks_spec.md")
$TraeRulesFile = "trae_rules.md"
$ScriptDir = "c:\work\tools\traeSpec"

Write-Host "[INFO] trae_spec.ps1 starts execution" -ForegroundColor Green
Write-Host "[INFO] Arguments: Path=$Path, All=$All, Cn=$Cn, Skill=$Skill" -ForegroundColor Yellow
Write-Host "[INFO] Current directory: $PWD" -ForegroundColor Yellow

# Validate arguments
if (-not $Path -and -not $All) {
    Write-Host "Error: Missing arguments" -ForegroundColor Red
    Write-Host ""
    Write-Host "Usage:" -ForegroundColor Cyan
    Write-Host "  .\trae_spec.ps1 --path <projectPath>" -ForegroundColor White
    Write-Host "  .\trae_spec.ps1 --all" -ForegroundColor White
    Write-Host ""
    exit 1
}

if ($Path -and $All) {
    Write-Host "Error: Cannot use --path and --all arguments together" -ForegroundColor Red
    exit 1
}

# Process --path argument
if ($Path) {
    Write-Host "[INFO] Detected --path argument" -ForegroundColor Green
    Write-Host "[INFO] Project path: $Path" -ForegroundColor Yellow
    
    # Check if project path exists
    if (-not (Test-Path $Path)) {
        Write-Host "Error: Project path does not exist: $Path" -ForegroundColor Red
        exit 1
    }

    if ($Skill) {
        Write-Host "[INFO] Detected --skill argument, copying SKILL.md" -ForegroundColor Green
        
        # Create .trae/skills/spec directory
        $SkillDir = Join-Path $Path ".trae\skills\spec"
        if (-not (Test-Path $SkillDir)) {
            try {
                New-Item -ItemType Directory -Path $SkillDir -Force | Out-Null
                Write-Host "[INFO] Created directory: $SkillDir" -ForegroundColor Green
            }
            catch {
                Write-Host "Error: Cannot create directory $SkillDir" -ForegroundColor Red
                exit 1
            }
        }
        
        # Copy SKILL.md
        $SourceFile = Join-Path $ScriptDir "skills\TraeSpec\SKILL.md"
        $TargetFile = Join-Path $SkillDir "SKILL.md"
        
        if (-not (Test-Path $SourceFile)) {
            Write-Host "Error: Source file does not exist: $SourceFile" -ForegroundColor Red
            exit 1
        }
        
        try {
            Copy-Item -Path $SourceFile -Destination $TargetFile -Force
            Write-Host "[INFO] Copied file: $SourceFile -> $TargetFile" -ForegroundColor Green
        }
        catch {
            Write-Host "Error: Cannot copy file $SourceFile -> $TargetFile" -ForegroundColor Red
            exit 1
        }
        
        Write-Host ""
        Write-Host "Complete: SKILL.md processed to project path $Path" -ForegroundColor Green
        exit 0
    }
    
    # Create .trae/rules directory
    $RulesDir = Join-Path $Path ".trae\rules"
    if (-not (Test-Path $RulesDir)) {
        try {
            New-Item -ItemType Directory -Path $RulesDir -Force | Out-Null
            Write-Host "[INFO] Created directory: $RulesDir" -ForegroundColor Green
        }
        catch {
            Write-Host "Error: Cannot create directory $RulesDir" -ForegroundColor Red
            exit 1
        }
    }
    
    # Process three spec files (direct copy)
    foreach ($File in $SpecFiles) {
        $SourceFile = Join-Path $ScriptDir "rules\$File"
        $TargetFile = Join-Path $RulesDir $File
        
        # Check if source file exists
        if (-not (Test-Path $SourceFile)) {
            Write-Host "Warning: Source file does not exist: $SourceFile" -ForegroundColor Yellow
            continue
        }
        
        # Direct copy (overwrite existing)
        try {
            Copy-Item -Path $SourceFile -Destination $TargetFile -Force
            Write-Host "[INFO] Copied file: $SourceFile -> $TargetFile" -ForegroundColor Green
        }
        catch {
            Write-Host "Error: Cannot copy file $SourceFile -> $TargetFile" -ForegroundColor Red
        }
    }
    
    # Special handling for trae_rules.md -> project_rules.md
    $SourceFile = Join-Path $ScriptDir "rules\$TraeRulesFile"
    $TargetFile = Join-Path $RulesDir "project_rules.md"
    
    # Check if source file exists
    if (-not (Test-Path $SourceFile)) {
        Write-Host "Warning: Source file does not exist: $SourceFile" -ForegroundColor Yellow
    }
    else {
        # Check if target file exists
        if (Test-Path $TargetFile) {
            Write-Host "[INFO] Target file exists, smart updating content: $TargetFile" -ForegroundColor Yellow
            try {
                # Read target file content
                $targetContent = Get-Content -Path $TargetFile -Raw
                $sourceContent = Get-Content -Path $SourceFile -Raw
                
                # Define markers
                $startMarker = "<!-- trae_rules.md start -->"
                $endMarker = "<!-- trae_rules.md end -->"
                
                # Check if markers exist
                if ($targetContent -match [regex]::Escape($startMarker) -and $targetContent -match [regex]::Escape($endMarker)) {
                    # Replace content between markers
                    $pattern = "(?s)$([regex]::Escape($startMarker)).*?$([regex]::Escape($endMarker))"
                    $newContent = $startMarker + "`n" + $sourceContent + "`n" + $endMarker
                    $targetContent = $targetContent -replace $pattern, $newContent
                    
                    Set-Content -Path $TargetFile -Value $targetContent
                    Write-Host "[INFO] Replaced marked content in $TargetFile" -ForegroundColor Green
                }
                else {
                    # If markers don't exist, append content
                    Add-Content -Path $TargetFile -Value ""
                    Add-Content -Path $TargetFile -Value "# Content below from trae_rules.md"
                    Add-Content -Path $TargetFile -Value ""
                    Add-Content -Path $TargetFile -Value $startMarker
                    Add-Content -Path $TargetFile -Value $sourceContent
                    Add-Content -Path $TargetFile -Value $endMarker
                    Write-Host "[INFO] Appended content to $TargetFile" -ForegroundColor Green
                }
            }
            catch {
                Write-Host "Error: Cannot update content in $TargetFile" -ForegroundColor Red
            }
        }
        else {
            try {
                # First copy, add markers
                $sourceContent = Get-Content -Path $SourceFile -Raw
                $startMarker = "<!-- trae_rules.md start -->"
                $endMarker = "<!-- trae_rules.md end -->"
                $markedContent = $startMarker + "`n" + $sourceContent + "`n" + $endMarker
                
                Set-Content -Path $TargetFile -Value $markedContent
                Write-Host "[INFO] Copied file and added markers: $SourceFile -> $TargetFile" -ForegroundColor Green
            }
            catch {
                Write-Host "Error: Cannot copy file $SourceFile -> $TargetFile" -ForegroundColor Red
            }
        }
    }
    
    Write-Host ""
    Write-Host "Complete: All spec files processed to project path $Path" -ForegroundColor Green
}

# Process --all argument
if ($All) {
    Write-Host "[INFO] Detected --all argument" -ForegroundColor Green
    
    # Get user home directory
    $UserHome = $env:USERPROFILE
    Write-Host "[INFO] User home directory: $UserHome" -ForegroundColor Yellow
    
    # Choose directory based on --cn argument
    if ($Cn) {
        Write-Host "[INFO] Detected --cn argument, using ~/.trae-cn directory" -ForegroundColor Green
        $UserRulesDir = Join-Path $UserHome ".trae-cn"
    } else {
        Write-Host "[INFO] No --cn argument detected, using ~/.trae directory" -ForegroundColor Green
        $UserRulesDir = Join-Path $UserHome ".trae"
    }
    if (-not (Test-Path $UserRulesDir)) {
        try {
            New-Item -ItemType Directory -Path $UserRulesDir -Force | Out-Null
            Write-Host "[INFO] Created directory: $UserRulesDir" -ForegroundColor Green
        }
        catch {
            Write-Host "Error: Cannot create directory $UserRulesDir" -ForegroundColor Red
            exit 1
        }
    }
    
    # Process three spec files (direct copy)
    foreach ($File in $SpecFiles) {
        $SourceFile = Join-Path $ScriptDir "rules\$File"
        $TargetFile = Join-Path $UserRulesDir $File
        
        # Check if source file exists
        if (-not (Test-Path $SourceFile)) {
            Write-Host "Warning: Source file does not exist: $SourceFile" -ForegroundColor Yellow
            continue
        }
        
        # Direct copy (overwrite existing)
        try {
            Copy-Item -Path $SourceFile -Destination $TargetFile -Force
            Write-Host "[INFO] Copied file: $SourceFile -> $TargetFile" -ForegroundColor Green
        }
        catch {
            Write-Host "Error: Cannot copy file $SourceFile -> $TargetFile" -ForegroundColor Red
        }
    }
    
    # Special handling for trae_rules.md -> user_rules.md
    $SourceFile = Join-Path $ScriptDir "rules\$TraeRulesFile"
    $TargetFile = Join-Path $UserRulesDir "user_rules.md"
    
    # Check if source file exists
    if (-not (Test-Path $SourceFile)) {
        Write-Host "Warning: Source file does not exist: $SourceFile" -ForegroundColor Yellow
    }
    else {
        # Check if target file exists
        if (Test-Path $TargetFile) {
            Write-Host "[INFO] Target file exists, smart updating content: $TargetFile" -ForegroundColor Yellow
            try {
                # Read target file content
                $targetContent = Get-Content -Path $TargetFile -Raw
                $sourceContent = Get-Content -Path $SourceFile -Raw
                
                # Define markers
                $startMarker = "<!-- trae_rules.md start -->"
                $endMarker = "<!-- trae_rules.md end -->"
                
                # Check if markers exist
                if ($targetContent -match [regex]::Escape($startMarker) -and $targetContent -match [regex]::Escape($endMarker)) {
                    # Replace content between markers
                    $pattern = "(?s)$([regex]::Escape($startMarker)).*?$([regex]::Escape($endMarker))"
                    $newContent = $startMarker + "`n" + $sourceContent + "`n" + $endMarker
                    $targetContent = $targetContent -replace $pattern, $newContent
                    
                    Set-Content -Path $TargetFile -Value $targetContent
                    Write-Host "[INFO] Replaced marked content in $TargetFile" -ForegroundColor Green
                }
                else {
                    # If markers don't exist, append content
                    Add-Content -Path $TargetFile -Value ""
                    Add-Content -Path $TargetFile -Value "# Content below from trae_rules.md"
                    Add-Content -Path $TargetFile -Value ""
                    Add-Content -Path $TargetFile -Value $startMarker
                    Add-Content -Path $TargetFile -Value $sourceContent
                    Add-Content -Path $TargetFile -Value $endMarker
                    Write-Host "[INFO] Appended content to $TargetFile" -ForegroundColor Green
                }
            }
            catch {
                Write-Host "Error: Cannot update content in $TargetFile" -ForegroundColor Red
            }
        }
        else {
            try {
                # First copy, add markers
                $sourceContent = Get-Content -Path $SourceFile -Raw
                $startMarker = "<!-- trae_rules.md start -->"
                $endMarker = "<!-- trae_rules.md end -->"
                $markedContent = $startMarker + "`n" + $sourceContent + "`n" + $endMarker
                
                Set-Content -Path $TargetFile -Value $markedContent
                Write-Host "[INFO] Copied file and added markers: $SourceFile -> $TargetFile" -ForegroundColor Green
            }
            catch {
                Write-Host "Error: Cannot copy file $SourceFile -> $TargetFile" -ForegroundColor Red
            }
        }
    }
    
    Write-Host ""
    Write-Host "Complete: All spec files processed to user directory $UserRulesDir" -ForegroundColor Green
}

Write-Host ""
Write-Host "trae_spec.ps1 script execution complete!" -ForegroundColor Green
