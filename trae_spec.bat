@if (@CodeSection == @Batch) @then
@echo off
setlocal enabledelayedexpansion

REM trae_spec.bat - Batch version of trae specification file management script
REM Usage: trae_spec.bat --path <projectPath> or trae_spec.bat --all [--cn]
REM Also supports: trae_spec.bat -Path <projectPath> or trae_spec.bat -All [-Cn]

REM Fix PATH to ensure cscript is found
set "PATH=%SystemRoot%\system32;%SystemRoot%;%SystemRoot%\System32\Wbem;%PATH%"

REM Initialize variables
set "ProjectPath="
set "All=false"
set "Cn=false"
set "ScriptDir=%~dp0"
REM Remove trailing backslash if present
if "%ScriptDir:~-1%"=="\" set "ScriptDir=%ScriptDir:~0,-1%"

echo [INFO] trae_spec.bat starts execution
echo [INFO] Current directory: %CD%

REM Check if arguments are provided
if "%~1"=="" (
    echo Error: Missing arguments
    echo.
    echo Usage:
    echo   trae_spec.bat --path ^<projectPath^>
    echo   trae_spec.bat --all [--cn]
    echo.
    exit /b 1
)

REM Parse arguments
:parse_args
if "%~1"=="" goto args_parsed
if /i "%~1"=="--path" (
    if "%~2"=="" (
        echo Error: --path argument requires a project path
        exit /b 1
    )
    set "ProjectPath=%~2"
    shift
) else if /i "%~1"=="-Path" (
    if "%~2"=="" (
        echo Error: -Path argument requires a project path
        exit /b 1
    )
    set "ProjectPath=%~2"
    shift
) else if /i "%~1"=="--all" (
    set "All=true"
) else if /i "%~1"=="-All" (
    set "All=true"
) else if /i "%~1"=="--cn" (
    set "Cn=true"
) else if /i "%~1"=="-Cn" (
    set "Cn=true"
) else (
    echo Error: Unknown argument %~1
    echo.
    echo Usage:
    echo   trae_spec.bat --path ^<projectPath^>
    echo   trae_spec.bat --all [--cn]
    echo.
    exit /b 1
)
shift
goto parse_args

:args_parsed

REM Check arguments
if not defined ProjectPath if "!All!"=="false" (
    echo Error: Missing arguments
    echo.
    echo Usage:
    echo   trae_spec.bat --path ^<projectPath^>
    echo   trae_spec.bat --all
    echo.
    exit /b 1
)

if defined ProjectPath if "!All!"=="true" (
    echo Error: Cannot use --path and --all arguments together
    exit /b 1
)

REM Define spec files
set "SpecFiles=requirements_spec.md design_spec.md tasks_spec.md"
set "TraeRulesFile=trae_rules.md"

REM Process --path argument
if defined ProjectPath (
    echo [INFO] Detected --path argument
    echo [INFO] Project path: !ProjectPath!
    
    REM Check if project path exists
    if not exist "!ProjectPath!" (
        echo Error: Project path does not exist: !ProjectPath!
        exit /b 1
    )
    
    REM Create .trae/rules directory
    set "RulesDir=!ProjectPath!\.trae\rules"
    if not exist "!RulesDir!" (
        mkdir "!RulesDir!" 2>nul
        if errorlevel 1 (
            echo Error: Cannot create directory !RulesDir!
            exit /b 1
        ) else (
            echo [INFO] Created directory: !RulesDir!
        )
    )
    
    REM Process spec files (copy directly)
    for %%f in (!SpecFiles!) do (
        set "SourceFile=!ScriptDir!\%%f"
        set "TargetFile=!RulesDir!\%%f"
        
        REM Check if source file exists
        if not exist "!SourceFile!" (
            echo Warning: Source file does not exist: !SourceFile!
        ) else (
            copy /Y "!SourceFile!" "!TargetFile!" >nul
            if errorlevel 1 (
                echo Error: Cannot copy file !SourceFile! -^> !TargetFile!
            ) else (
                echo [INFO] Copied file: !SourceFile! -^> !TargetFile!
            )
        )
    )
    
    REM Special handling for trae_rules.md -> project_rules.md
    set "SourceFile=!ScriptDir!\!TraeRulesFile!"
    set "TargetFile=!RulesDir!\project_rules.md"
    
    if not exist "!SourceFile!" (
        echo Warning: Source file does not exist: !SourceFile!
    ) else (
        call :ProcessRulesFile "!SourceFile!" "!TargetFile!"
    )
    
    echo.
    echo Complete: All specification files have been processed to project path !ProjectPath!
)

REM Process --all argument
if "!All!"=="true" (
    echo [INFO] Detected --all argument
    
    REM Get user home directory
    set "UserHome=%USERPROFILE%"
    echo [INFO] User home directory: !UserHome!
    
    REM Choose directory based on --cn argument
    if "!Cn!"=="true" (
        echo [INFO] Detected --cn argument, using ~/.trae-cn directory
        set "UserRulesDir=!UserHome!\.trae-cn"
    ) else (
        echo [INFO] No --cn argument detected, using ~/.trae directory
        set "UserRulesDir=!UserHome!\.trae"
    )
    
    if not exist "!UserRulesDir!" (
        mkdir "!UserRulesDir!" 2>nul
        if errorlevel 1 (
            echo Error: Cannot create directory !UserRulesDir!
            exit /b 1
        ) else (
            echo [INFO] Created directory: !UserRulesDir!
        )
    )
    
    REM Process spec files (copy directly)
    for %%f in (!SpecFiles!) do (
        set "SourceFile=!ScriptDir!\%%f"
        set "TargetFile=!UserRulesDir!\%%f"
        
        REM Check if source file exists
        if not exist "!SourceFile!" (
            echo Warning: Source file does not exist: !SourceFile!
        ) else (
            copy /Y "!SourceFile!" "!TargetFile!" >nul
            if errorlevel 1 (
                echo Error: Cannot copy file !SourceFile! -^> !TargetFile!
            ) else (
                echo [INFO] Copied file: !SourceFile! -^> !TargetFile!
            )
        )
    )
    
    REM Special handling for trae_rules.md -> user_rules.md
    set "SourceFile=!ScriptDir!\!TraeRulesFile!"
    set "TargetFile=!UserRulesDir!\user_rules.md"
    
    if not exist "!SourceFile!" (
        echo Warning: Source file does not exist: !SourceFile!
    ) else (
        call :ProcessRulesFile "!SourceFile!" "!TargetFile!"
    )
    
    echo.
    echo Complete: All specification files have been processed to user directory !UserRulesDir!
)

echo.
echo trae_spec.bat script execution complete!
goto :eof

REM ==========================================
REM Helper Functions
REM ==========================================

:ProcessRulesFile
REM Arguments: %1 = SourceFile, %2 = TargetFile
REM Call JScript to handle UTF-8 file processing safely
cscript //nologo //E:JScript "%~f0" "%~1" "%~2"
exit /b 0

@end

// ==========================================
// JScript Implementation
// ==========================================

var args = WScript.Arguments;
if (args.length < 2) {
    WScript.Quit(1);
}

var sourcePath = args(0);
var targetPath = args(1);
var fso = new ActiveXObject("Scripting.FileSystemObject");

function readFile(path) {
    var stream = new ActiveXObject("ADODB.Stream");
    stream.Type = 2; // adTypeText
    stream.Charset = "utf-8";
    stream.Open();
    try {
        stream.LoadFromFile(path);
        var text = stream.ReadText();
        return text;
    } catch(e) {
        return null;
    } finally {
        if (stream.State != 0) stream.Close();
    }
}

function writeFile(path, content) {
    var stream = new ActiveXObject("ADODB.Stream");
    stream.Type = 2; // adTypeText
    stream.Charset = "utf-8";
    stream.Open();
    stream.WriteText(content);
    // adSaveCreateOverWrite = 2
    stream.SaveToFile(path, 2);
    stream.Close();
}

var sourceContent = readFile(sourcePath);
if (sourceContent === null) {
    WScript.Echo("[ERROR] Could not read source file: " + sourcePath);
    WScript.Quit(1);
}

var startMarker = "<!-- trae_rules.md start -->";
var endMarker = "<!-- trae_rules.md end -->";

if (!fso.FileExists(targetPath)) {
    // Create new file
    WScript.Echo("[INFO] Creating file with markers: " + targetPath);
    var newContent = startMarker + "\n" + sourceContent;
    if (sourceContent.length > 0 && sourceContent.slice(-1) !== "\n") {
        newContent += "\n";
    }
    newContent += endMarker + "\n";
    writeFile(targetPath, newContent);
} else {
    // Update existing file
    var targetContent = readFile(targetPath);
    if (targetContent === null) {
        WScript.Echo("[ERROR] Could not read target file: " + targetPath);
        WScript.Quit(1);
    }

    var startIndex = targetContent.indexOf(startMarker);
    var endIndex = targetContent.indexOf(endMarker);

    if (startIndex !== -1 && endIndex !== -1 && endIndex > startIndex) {
        WScript.Echo("[INFO] Target file already exists, updating content between markers: " + targetPath);
        
        var before = targetContent.substring(0, startIndex);
        var after = targetContent.substring(endIndex + endMarker.length);
        
        var newContent = before + startMarker + "\n" + sourceContent;
        if (sourceContent.length > 0 && sourceContent.slice(-1) !== "\n") {
            newContent += "\n";
        }
        newContent += endMarker + after;
        
        writeFile(targetPath, newContent);
        WScript.Echo("[INFO] Updated content in " + targetPath);
    } else {
        WScript.Echo("[INFO] Target file already exists, appending content to: " + targetPath);
        
        var newContent = targetContent;
        if (targetContent.length > 0 && targetContent.slice(-1) !== "\n") {
            newContent += "\n";
        }
        newContent += "\n" + startMarker + "\n" + sourceContent;
        if (sourceContent.length > 0 && sourceContent.slice(-1) !== "\n") {
            newContent += "\n";
        }
        newContent += endMarker + "\n";
        
        writeFile(targetPath, newContent);
        WScript.Echo("[INFO] Appended content to " + targetPath);
    }
}
