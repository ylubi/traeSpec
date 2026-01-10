@if (@CodeSection == @Batch) @then
@echo off
setlocal enabledelayedexpansion

:: Fix PATH to ensure cscript is found
set "PATH=%SystemRoot%\system32;%SystemRoot%;%SystemRoot%\System32\Wbem;%PATH%"

:: Get script directory
set "SCRIPT_DIR=%~dp0"
set "SELF=%~f0"
set "OLD_RULES_FILE=%SCRIPT_DIR%trae_rules_old.md"

if not exist "%OLD_RULES_FILE%" (
    echo [ERROR] trae_rules_old.md not found.
    exit /b 1
)

:: Parse arguments
set "TARGETS="
set "HAS_ARGS=0"

:ParseArgs
if "%~1"=="" goto :RunProcessing
if /i "%~1"=="--path" goto :SetPath
if /i "%~1"=="-Path" goto :SetPath
if /i "%~1"=="--all" goto :SetAll
if /i "%~1"=="-All" goto :SetAll
shift
goto :ParseArgs

:SetPath
if "%~2"=="" (
    echo [ERROR] %~1 requires an argument.
    exit /b 1
)
set "PROJECT_PATH=%~2"
:: Remove quotes
set "PROJECT_PATH=!PROJECT_PATH:"=!"

set "PROJECT_RULES=!PROJECT_PATH!\.trae\rules\project_rules.md"
set "TARGETS=!TARGETS! "!PROJECT_RULES!""
set "HAS_ARGS=1"
shift
shift
goto :ParseArgs

:SetAll
set "USER_RULES=%USERPROFILE%\.trae\user_rules.md"
set "USER_RULES_CN=%USERPROFILE%\.trae-cn\user_rules.md"
set "TARGETS=!TARGETS! "!USER_RULES!" "!USER_RULES_CN!""
set "HAS_ARGS=1"
shift
goto :ParseArgs

:RunProcessing
if "!HAS_ARGS!"=="0" (
    echo Error: Missing arguments
    echo Usage:
    echo   %~nx0 --path ^<projectPath^>
    echo   %~nx0 --all
    echo   Note: Also supports -Path and -All
    exit /b 1
)

:: Call JScript part
cscript //nologo //E:JScript "%SELF%" "%OLD_RULES_FILE%" !TARGETS!

goto :eof
@end

// ==========================================
// JScript Implementation
// ==========================================

var args = WScript.Arguments;
if (args.length < 2) {
    WScript.Quit(0);
}

var oldRulesPath = args(0);
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

var oldContentFull = readFile(oldRulesPath);
if (oldContentFull === null) {
    WScript.Echo("[ERROR] Could not read " + oldRulesPath);
    WScript.Quit(1);
}

for (var i = 1; i < args.length; i++) {
    var targetPath = args(i);
    processFile(targetPath, oldContentFull);
}

function processFile(path, oldContent) {
    if (!fso.FileExists(path)) {
        WScript.Echo("[WARN] File not found: " + path);
        return;
    }

    WScript.Echo("[INFO] Processing file: " + path);

    var targetContent = readFile(path);
    if (targetContent === null) {
        WScript.Echo("[ERROR] Failed to read " + path);
        return;
    }

    var contentToMatch = oldContent;
    var index = targetContent.indexOf(contentToMatch);

    // Try without trailing newline if not found
    if (index === -1) {
        if (oldContent.length > 0 && oldContent.slice(-1) === "\n") {
            var trimmed = oldContent.slice(0, -1);
            index = targetContent.indexOf(trimmed);
            if (index !== -1) {
                contentToMatch = trimmed;
            }
        }
    }

    if (index !== -1) {
        var startMarker = "<!-- trae_rules.md start -->";
        var endMarker = "<!-- trae_rules.md end -->";

        var before = targetContent.substring(0, index);
        var after = targetContent.substring(index + contentToMatch.length);

        var isWrapped = false;
        
        // Regex for markers with whitespace handling
        var reStart = /<!-- trae_rules\.md start -->\s*$/;
        var reEnd = /^\s*<!-- trae_rules\.md end -->/;

        if (reStart.test(before) && reEnd.test(after)) {
            isWrapped = true;
        }

        if (isWrapped) {
            WScript.Echo("[INFO] Content found but already wrapped.");
        } else {
            WScript.Echo("[INFO] Found unwrapped old content. Wrapping it now.");

            var newContent = before;

            if (before.length > 0 && before.slice(-1) !== "\n") {
                newContent += "\n";
            }
            newContent += startMarker + "\n";
            newContent += contentToMatch;
            
            if (contentToMatch.length > 0 && contentToMatch.slice(-1) !== "\n") {
                newContent += "\n";
            }
            newContent += endMarker;
            newContent += after;
            
            writeFile(path, newContent);
            WScript.Echo("[INFO] Processed " + path);
        }

    } else {
        WScript.Echo("[INFO] Old content not found.");
    }
}
