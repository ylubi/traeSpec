$ErrorActionPreference = "Stop"

# Parse command line arguments manually to support both - and -- formats
$Path = $null
$All = $false

for ($i = 0; $i -lt $args.Count; $i++) {
    if ($args[$i] -eq "--path" -or $args[$i] -eq "-Path") {
        if ($i+1 -lt $args.Count) {
            $Path = $args[$i+1]
            $i++
        }
    } elseif ($args[$i] -eq "--all" -or $args[$i] -eq "-All") {
        $All = $true
    }
}

# Define colors (simulated for PowerShell host)
function Write-Color {
    param($Text, $Color)
    Write-Host $Text -ForegroundColor $Color
}

# Get script directory
$ScriptDir = $PSScriptRoot
$OldRulesFile = Join-Path $ScriptDir "rules\trae_rules_old.md"

if (-not (Test-Path $OldRulesFile)) {
    Write-Color "Error: $OldRulesFile not found" Red
    exit 1
}

# Read old rules content
# Use -Raw to read as single string, preserving line endings
$OldContent = Get-Content -Path $OldRulesFile -Raw -Encoding UTF8

if ([string]::IsNullOrEmpty($OldContent)) {
    Write-Color "Error: Old rules file is empty" Red
    exit 1
}

function Process-File {
    param (
        [string]$TargetFile
    )

    if (-not (Test-Path $TargetFile)) {
        Write-Color "[WARN] File not found: $TargetFile" Yellow
        return
    }

    Write-Color "[INFO] Processing file: $TargetFile" Green

    # Read target file
    $TargetContent = Get-Content -Path $TargetFile -Raw -Encoding UTF8
    
    # Try to find content
    # Normalization: We try exact match first.
    $Index = $TargetContent.IndexOf($OldContent)
    
    # If not found, try handling potential trailing newline differences
    if ($Index -eq -1) {
        $OldContentTrimmed = $OldContent.TrimEnd()
        $Index = $TargetContent.IndexOf($OldContentTrimmed)
        if ($Index -ne -1) {
            $OldContent = $OldContentTrimmed
        }
    }

    if ($Index -ne -1) {
        # Check if already wrapped
        $StartMarker = "<!-- trae_rules.md start -->"
        $EndMarker = "<!-- trae_rules.md end -->"
        
        $Before = $TargetContent.Substring(0, $Index)
        $After = $TargetContent.Substring($Index + $OldContent.Length)
        
        $IsWrapped = $false
        
        # Check surroundings using Regex to handle whitespace/newlines
        # Escape markers for regex
        $EscapedStart = [regex]::Escape($StartMarker)
        $EscapedEnd = [regex]::Escape($EndMarker)
        
        if ($Before -match "$EscapedStart\s*`$") {
            if ($After -match "^\s*$EscapedEnd") {
                $IsWrapped = $true
            }
        }
        
        if ($IsWrapped) {
            Write-Host "[INFO] Content found but already wrapped."
        } else {
            Write-Host "[INFO] Found unwrapped old content. Wrapping it now."
            
            # Build new content
            $NewContentBuilder = [System.Text.StringBuilder]::new()
            $NewContentBuilder.Append($Before)
            
            # Ensure newline before start marker if needed
            if ($Before.Length -gt 0 -and -not $Before.EndsWith("`n")) {
                $NewContentBuilder.AppendLine()
            }
            
            $NewContentBuilder.AppendLine($StartMarker)
            $NewContentBuilder.Append($OldContent)
            
            # Ensure newline after content if not present
            if (-not $OldContent.EndsWith("`n")) {
                $NewContentBuilder.AppendLine()
            }
            
            $NewContentBuilder.Append($EndMarker)
            $NewContentBuilder.Append($After)
            
            $NewContent = $NewContentBuilder.ToString()
            
            # Write back
            Set-Content -Path $TargetFile -Value $NewContent -Encoding UTF8 -NoNewline
            Write-Color "[INFO] Processed $TargetFile" Green
        }
    } else {
        Write-Color "[INFO] Old content not found." Yellow
    }
}

# Argument parsing check
if (-not $Path -and -not $All) {
    Write-Color "Error: Missing arguments" Red
    Write-Color "Usage:" Cyan
    Write-Color "  .\deal_old.ps1 -Path <projectPath>" White
    Write-Color "  .\deal_old.ps1 -All" White
    Write-Color "  Note: Also supports --path and --all" White
    exit 1
}

if ($Path) {
    Write-Color "[INFO] Processing project path: $Path" Green
    $Target = Join-Path $Path ".trae\rules\project_rules.md"
    Process-File -TargetFile $Target
}

if ($All) {
    Write-Color "[INFO] Processing user directories" Green
    $UserHome = $HOME
    
    $TargetTrae = Join-Path $UserHome ".trae\user_rules.md"
    Process-File -TargetFile $TargetTrae
    
    $TargetTraeCn = Join-Path $UserHome ".trae-cn\user_rules.md"
    Process-File -TargetFile $TargetTraeCn
}
