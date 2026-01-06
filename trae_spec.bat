@echo off
setlocal enabledelayedexpansion

REM trae_spec.bat - Batch version of trae specification file management script
REM Usage: trae_spec.bat --path <projectPath> or trae_spec.bat --all [--cn]
REM Also supports: trae_spec.bat -Path <projectPath> or trae_spec.bat -All [-Cn]

REM Initialize variables
set "Path="
set "All=false"
set "Cn=false"
set "ScriptDir=c:\work\tools\traeSpec"

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
    set "Path=%~2"
    shift
) else if /i "%~1"=="-Path" (
    if "%~2"=="" (
        echo Error: -Path argument requires a project path
        exit /b 1
    )
    set "Path=%~2"
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
if not defined Path if "!All!"=="false" (
    echo Error: Missing arguments
    echo.
    echo Usage:
    echo   trae_spec.bat --path ^<projectPath^>
    echo   trae_spec.bat --all
    echo.
    exit /b 1
)

if defined Path if "!All!"=="true" (
    echo Error: Cannot use --path and --all arguments together
    exit /b 1
)

REM Define spec files
set "SpecFiles=requirements_spec.md design_spec.md tasks_spec.md"
set "TraeRulesFile=trae_rules.md"

REM Process --path argument
if defined Path (
    echo [INFO] Detected --path argument
    echo [INFO] Project path: !Path!
    
    REM Check if project path exists
    if not exist "!Path!" (
        echo Error: Project path does not exist: !Path!
        exit /b 1
    )
    
    REM Create .trae/rules directory
    set "RulesDir=!Path!\.trae\rules"
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
    
    REM Special handling for trae_rules.md -^> project_rules.md
    set "SourceFile=!ScriptDir!\!TraeRulesFile!"
    set "TargetFile=!RulesDir!\project_rules.md"
    
    if not exist "!SourceFile!" (
        echo Warning: Source file does not exist: !SourceFile!
    ) else (
        if exist "!TargetFile!" (
            echo [INFO] Target file already exists, appending content to: !TargetFile!
            echo. >> "!TargetFile!"
            echo # Following content from trae_rules.md >> "!TargetFile!"
            echo. >> "!TargetFile!"
            type "!SourceFile!" >> "!TargetFile!"
            if errorlevel 1 (
                echo Error: Cannot append content to !TargetFile!
            ) else (
                echo [INFO] Appended content to !TargetFile!
            )
        ) else (
            copy /Y "!SourceFile!" "!TargetFile!" >nul
            if errorlevel 1 (
                echo Error: Cannot copy file !SourceFile! -^> !TargetFile!
            ) else (
                echo [INFO] Copied file: !SourceFile! -^> !TargetFile!
            )
        )
    )
    
    echo.
    echo Complete: All specification files have been processed to project path !Path!
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
    
    REM Special handling for trae_rules.md -^> user_rules.md
    set "SourceFile=!ScriptDir!\!TraeRulesFile!"
    set "TargetFile=!UserRulesDir!\user_rules.md"
    
    if not exist "!SourceFile!" (
        echo Warning: Source file does not exist: !SourceFile!
    ) else (
        if exist "!TargetFile!" (
            echo [INFO] Target file already exists, appending content to: !TargetFile!
            echo. >> "!TargetFile!"
            echo # Following content from trae_rules.md >> "!TargetFile!"
            echo. >> "!TargetFile!"
            type "!SourceFile!" >> "!TargetFile!"
            if errorlevel 1 (
                echo Error: Cannot append content to !TargetFile!
            ) else (
                echo [INFO] Appended content to !TargetFile!
            )
        ) else (
            copy /Y "!SourceFile!" "!TargetFile!" >nul
            if errorlevel 1 (
                echo Error: Cannot copy file !SourceFile! -^> !TargetFile!
            ) else (
                echo [INFO] Copied file: !SourceFile! -^> !TargetFile!
            )
        )
    )
    
    echo.
    echo Complete: All specification files have been processed to user directory !UserRulesDir!
)

echo.
echo trae_spec.bat script execution complete!