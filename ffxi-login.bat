@echo off
setlocal enabledelayedexpansion

REM ===================================================================
REM FFXI Multi-Character Login Script
REM ===================================================================
REM This script automatically launches FFXI characters, detecting which
REM ones are already running and only starting the missing ones.
REM 
REM Configuration is now loaded from ffxi-login-config.json
REM See README.md for setup instructions.
REM ===================================================================

REM ===================================================================
REM ADMIN PRIVILEGE CHECK AND AUTO-ELEVATION
REM ===================================================================
REM Check if running as administrator
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo This script requires administrator privileges.
    echo Attempting to restart as administrator...
    
    REM Use PowerShell to restart the script as admin
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

echo Running with administrator privileges.
echo.

REM ===================================================================
REM CONFIGURATION LOADING
REM ===================================================================
set "CONFIG_FILE=%~dp0ffxi-login-config.json"

REM Set up basic logging before config load
set "LOG_FILE=%~dp0ffxi-login.log"
echo. > "%LOG_FILE%"
echo Loading configuration from: %CONFIG_FILE% >> "%LOG_FILE%"

REM Check if config file exists
if not exist "%CONFIG_FILE%" (
    echo ERROR: Configuration file not found: "%CONFIG_FILE%"
    echo Please create the configuration file. See README.md for instructions.
    echo.
    echo Press any key to exit...
    pause >nul
    exit /b 1
)

REM Load configuration using PowerShell to parse JSON
call :LoadConfiguration

REM ===================================================================
REM LOGGING SETUP
REM ===================================================================
REM Set up logging based on config
if "%DEBUG_MODE%"=="true" (
    set "DEBUG_MODE=1"
) else (
    set "DEBUG_MODE=0"
)

REM Update log file path from config and restart logging
set "LOG_FILE=%~dp0%LOG_FILE_NAME%"
echo. > "%LOG_FILE%"
call :LogMessage "Script started at %date% %time%"
call :LogMessage "Configuration loaded successfully"

REM ===================================================================
REM SCRIPT START
REM ===================================================================

echo ===================================================================
echo FFXI Multi-Character Login Script
echo ===================================================================
echo.
if "%DEBUG_MODE%"=="1" echo Debug mode enabled - output will be logged to: %LOG_FILE%
echo.

call :LogMessage "Starting main script execution"

REM Validate paths
call :ValidatePaths
if !errorlevel! neq 0 exit /b 1

echo Checking currently running FFXI characters...
echo.

call :LogMessage "Starting character detection"

REM Function to check running characters
call :CheckRunningCharacters

echo.
echo Found !RUNNING_COUNT! character(s) already running.
echo Characters to launch: !PENDING_COUNT!
echo.

call :LogMessage "Character detection complete - Running: !RUNNING_COUNT!, Pending: !PENDING_COUNT!"

if !PENDING_COUNT! equ 0 (
    echo All characters are already running!
    call :LogMessage "All characters already running - script complete"
    echo.
    echo Press any key to exit...
    pause >nul
    exit /b 0
)

REM Group characters by bin file
call :LogMessage "Grouping characters by bin file"
call :GroupCharactersByBin

REM Launch characters grouped by bin file
call :LogMessage "Starting character launches"
call :LaunchCharacterGroups

echo.
echo ===================================================================
echo All character launches completed!
echo ===================================================================
call :LogMessage "Script completed successfully"
echo.
echo Press any key to exit...
pause >nul
exit /b 0

REM ===================================================================
REM FUNCTIONS
REM ===================================================================

:LoadConfiguration
call :LogMessage "Loading configuration from JSON file"

REM Use separate PowerShell script to parse JSON
set "PS_SCRIPT=%~dp0load-config.ps1"
if not exist "%PS_SCRIPT%" (
    echo ERROR: PowerShell configuration script not found: "%PS_SCRIPT%"
    echo Please ensure load-config.ps1 is in the same directory as this script.
    exit /b 1
)

REM Parse configuration and set variables
set "IN_CHAR_LIST=0"
set "CHAR_LIST="

for /f "usebackq delims=" %%i in (`powershell -NoProfile -ExecutionPolicy Bypass -File "%PS_SCRIPT%" "%CONFIG_FILE%"`) do (
    set "LINE=%%i"
    if "!LINE!"=="CHAR_LIST_START" (
        set "IN_CHAR_LIST=1"
    ) else if "!LINE!"=="CHAR_LIST_END" (
        set "IN_CHAR_LIST=0"
    ) else if "!IN_CHAR_LIST!"=="1" (
        set "CHAR_LIST=!CHAR_LIST! !LINE!"
    ) else (
        set %%i
    )
)

REM Set full path for log file
set "LOG_FILE=%~dp0%LOG_FILE_NAME%"

call :LogMessage "Configuration variables set:"
call :LogMessage "  AUTOPOL_PATH=%AUTOPOL_PATH%"
call :LogMessage "  BIN_FILES_PATH=%BIN_FILES_PATH%"
call :LogMessage "  LOGIN_BIN_DEST=%LOGIN_BIN_DEST%"
call :LogMessage "  WINDOWER_CONFIG_DEST=%WINDOWER_CONFIG_DEST%"
call :LogMessage "  CONFIG_FILES_PATH=%CONFIG_FILES_PATH%"
call :LogMessage "  LAUNCH_DELAY=%LAUNCH_DELAY%"
call :LogMessage "  BIN_SWAP_DELAY=%BIN_SWAP_DELAY%"
call :LogMessage "  DEBUG_MODE=%DEBUG_MODE%"
call :LogMessage "  CHARACTER_LIST=%CHAR_LIST%"
exit /b 0

:ValidatePaths
call :LogMessage "Validating configured paths"

REM Check if autoPOL.exe exists
call :LogMessage "Checking if autoPOL.exe exists"
if not exist "%AUTOPOL_PATH%" (
    echo ERROR: autoPOL.exe not found at: "%AUTOPOL_PATH%"
    echo Please update the autopol_path in %CONFIG_FILE%
    call :LogMessage "ERROR: autoPOL.exe not found"
    echo.
    echo Press any key to exit...
    pause >nul
    exit /b 1
) else (
    call :LogMessage "autoPOL.exe found successfully"
    echo autoPOL.exe found at: "%AUTOPOL_PATH%"
)

REM Check if bin files directory exists
call :LogMessage "Checking if bin files directory exists"
if not exist "%BIN_FILES_PATH%" (
    echo ERROR: Bin files directory not found at: "%BIN_FILES_PATH%"
    echo Please update the bin_files_path in %CONFIG_FILE%
    call :LogMessage "ERROR: Bin files directory not found"
    echo.
    echo Press any key to exit...
    pause >nul
    exit /b 1
) else (
    call :LogMessage "Bin files directory found successfully"
    echo Bin files directory found at: "%BIN_FILES_PATH%"
)

REM Check if destination directory exists
call :LogMessage "Checking destination directory for login_w.bin"
for %%F in ("%LOGIN_BIN_DEST%") do set "DEST_DIR=%%~dpF"
if not exist "%DEST_DIR%" (
    echo ERROR: Destination directory not found: "%DEST_DIR%"
    echo Please check the login_bin_dest path in %CONFIG_FILE%
    call :LogMessage "ERROR: Destination directory not found"
    echo.
    echo Press any key to exit...
    pause >nul
    exit /b 1
) else (
    call :LogMessage "Destination directory found successfully"
    echo Destination directory found: "%DEST_DIR%"
)

exit /b 0

:LogMessage
if not defined LOG_FILE set "LOG_FILE=%~dp0ffxi-login.log"
echo %~1 >> "%LOG_FILE%"
if "%DEBUG_MODE%"=="1" echo [DEBUG] %~1
exit /b 0

:CheckRunningCharacters
call :LogMessage "Entering CheckRunningCharacters function"
set "RUNNING_COUNT=0"
set "PENDING_COUNT=0"
set "RUNNING_CHARS="
set "PENDING_CHARS="

REM Create a temporary file to store process information
set "TEMP_FILE=%TEMP%\ffxi_processes.tmp"

call :LogMessage "Getting all pol.exe processes with window titles"
REM Get all PlayOnline Viewer processes with window titles
tasklist /v /fi "imagename eq pol.exe" /fo csv > "%TEMP_FILE%" 2>nul

call :LogMessage "Starting character loop"
for %%i in (%CHAR_LIST%) do (
    for /f "tokens=1,2,3 delims=:" %%a in ("%%i") do (
        set "CHAR_NAME=%%a"
        set "BIN_FILE=%%b"
        set "CONFIG_FILE=%%c"
        
        call :LogMessage "Checking character: !CHAR_NAME! (bin: !BIN_FILE!, config: !CONFIG_FILE!)"
        
        REM Check if character is already running by looking for character name in window titles
        set "IS_RUNNING=0"
        
        REM Check if character name appears in any window title
        call :LogMessage "Searching for !CHAR_NAME! in process window titles"
        findstr /i "!CHAR_NAME!" "%TEMP_FILE%" >nul 2>&1
        if !errorlevel! equ 0 (
            set "IS_RUNNING=1"
            call :LogMessage "Character !CHAR_NAME! detected as running"
        ) else (
            call :LogMessage "Character !CHAR_NAME! not detected in running processes"
        )
        
        if !IS_RUNNING! equ 1 (
            set /a RUNNING_COUNT+=1
            set "RUNNING_CHARS=!RUNNING_CHARS! !CHAR_NAME!"
            echo [RUNNING] !CHAR_NAME!
            call :LogMessage "Marked !CHAR_NAME! as RUNNING"
        ) else (
            set /a PENDING_COUNT+=1
            set "PENDING_CHARS=!PENDING_CHARS! %%i"
            echo [PENDING] !CHAR_NAME! ^(using !BIN_FILE! and !CONFIG_FILE!^)
            call :LogMessage "Marked !CHAR_NAME! as PENDING (using !BIN_FILE! and !CONFIG_FILE!)"
        )
    )
)

REM Clean up temporary file
if exist "%TEMP_FILE%" del "%TEMP_FILE%"
call :LogMessage "CheckRunningCharacters function complete"
exit /b 0

:GroupCharactersByBin
call :LogMessage "Entering GroupCharactersByBin function"
set "BIN_GROUPS="
set "CURRENT_BIN="
set "CURRENT_CONFIG="
set "CURRENT_GROUP="

call :LogMessage "Pending characters to group: !PENDING_CHARS!"

REM Sort pending characters by bin file and config file
for %%i in (!PENDING_CHARS!) do (
    call :LogMessage "Raw pending character entry: %%i"
    for /f "tokens=1,2,3 delims=:" %%a in ("%%i") do (
        set "CHAR_NAME=%%a"
        set "BIN_FILE=%%b"
        set "CONFIG_FILE=%%c"
        
        call :LogMessage "Processing character !CHAR_NAME! with bin !BIN_FILE! and config !CONFIG_FILE!"
        
        if "!CURRENT_BIN!" neq "!BIN_FILE!" (
            if "!CURRENT_GROUP!" neq "" (
                set "BIN_GROUPS=!BIN_GROUPS!|!CURRENT_BIN!:!CURRENT_CONFIG!:!CURRENT_GROUP!"
                call :LogMessage "Created group: !CURRENT_BIN!:!CURRENT_CONFIG!:!CURRENT_GROUP!"
            )
            set "CURRENT_BIN=!BIN_FILE!"
            set "CURRENT_CONFIG=!CONFIG_FILE!"
            set "CURRENT_GROUP=!CHAR_NAME!"
            call :LogMessage "Started new group with bin=!CURRENT_BIN!, config=!CURRENT_CONFIG!, first_char=!CURRENT_GROUP!"
        ) else (
            set "CURRENT_GROUP=!CURRENT_GROUP!,!CHAR_NAME!"
            call :LogMessage "Added !CHAR_NAME! to existing group, now: !CURRENT_GROUP!"
        )
    )
)

REM Add the last group
if "!CURRENT_GROUP!" neq "" (
    set "BIN_GROUPS=!BIN_GROUPS!|!CURRENT_BIN!:!CURRENT_CONFIG!:!CURRENT_GROUP!"
    call :LogMessage "Added final group: !CURRENT_BIN!:!CURRENT_CONFIG!:!CURRENT_GROUP!"
)

REM Log the final groups safely (avoid issues with special characters)
echo Final bin groups: !BIN_GROUPS! >> "%LOG_FILE%"
if "%DEBUG_MODE%"=="1" echo [DEBUG] Final bin groups: !BIN_GROUPS!

call :LogMessage "GroupCharactersByBin function complete"
exit /b 0

:LaunchCharacterGroups
call :LogMessage "Entering LaunchCharacterGroups function"
echo Starting character launches...
echo.

REM Log safely without using LogMessage function (which can't handle pipe characters)
echo All bin groups to process: !BIN_GROUPS! >> "%LOG_FILE%"
if "%DEBUG_MODE%"=="1" echo [DEBUG] All bin groups to process: !BIN_GROUPS!

REM Remove leading pipe if present and process groups
set "GROUPS=!BIN_GROUPS:~1!"
REM Log safely without using LogMessage function
echo Groups after removing leading pipe: !GROUPS! >> "%LOG_FILE%"
if "%DEBUG_MODE%"=="1" echo [DEBUG] Groups after removing leading pipe: !GROUPS!

REM Simple approach - process groups one by one
call :LogMessage "Starting group processing"

:ProcessNextGroup
if "!GROUPS!"=="" goto FinishedGroups

REM Extract first group
for /f "tokens=1* delims=|" %%a in ("!GROUPS!") do (
    set "CURRENT_GROUP=%%a"
    set "REMAINING_GROUPS=%%b"
)

call :LogMessage "Processing group: !CURRENT_GROUP!"

if "!CURRENT_GROUP!" neq "" (
    call :ProcessSingleGroup "!CURRENT_GROUP!"
)

set "GROUPS=!REMAINING_GROUPS!"
goto ProcessNextGroup

:FinishedGroups
call :LogMessage "LaunchCharacterGroups function complete"
exit /b 0

:ProcessSingleGroup
set "GROUP_ENTRY=%~1"
call :LogMessage "Raw group entry: !GROUP_ENTRY!"

for /f "tokens=1,2,3 delims=:" %%a in ("!GROUP_ENTRY!") do (
    set "BIN_FILE=%%a"
    set "CONFIG_FILE=%%b"
    set "CHAR_GROUP=%%c"
    
    call :LogMessage "Parsed - BIN_FILE=!BIN_FILE!, CONFIG_FILE=!CONFIG_FILE!, CHAR_GROUP=!CHAR_GROUP!"
    
    echo ===================================================================
    echo Switching to bin file: !BIN_FILE! and config: !CONFIG_FILE!
    echo ===================================================================
    call :LogMessage "Processing bin file: !BIN_FILE!, config: !CONFIG_FILE!, with characters: !CHAR_GROUP!"
    
    REM Copy the appropriate bin file
    if exist "%BIN_FILES_PATH%\!BIN_FILE!" (
        echo Copying !BIN_FILE! to login_w.bin...
        call :LogMessage "Copying bin file to destination"
        copy "%BIN_FILES_PATH%\!BIN_FILE!" "%LOGIN_BIN_DEST%" >nul
        if !errorlevel! equ 0 (
            echo Successfully copied bin file.
            call :LogMessage "Successfully copied bin file"
        ) else (
            echo ERROR: Failed to copy bin file!
            call :LogMessage "ERROR: Failed to copy bin file - errorlevel !errorlevel!"
            goto :EndProcessSingleGroup
        )
    ) else (
        echo ERROR: Bin file not found: "%BIN_FILES_PATH%\!BIN_FILE!"
        call :LogMessage "ERROR: Bin file not found"
        goto :EndProcessSingleGroup
    )
    
    REM Copy the appropriate config file BEFORE launching characters
    if "!CONFIG_FILE!" neq "" (
        if exist "%CONFIG_FILES_PATH%\!CONFIG_FILE!" (
            echo Copying !CONFIG_FILE! to config.json...
            call :LogMessage "Copying config file to destination"
            copy "%CONFIG_FILES_PATH%\!CONFIG_FILE!" "%WINDOWER_CONFIG_DEST%" >nul
            if !errorlevel! equ 0 (
                echo Successfully copied config file.
                call :LogMessage "Successfully copied config file"
            ) else (
                echo ERROR: Failed to copy config file!
                call :LogMessage "ERROR: Failed to copy config file - errorlevel !errorlevel!"
            )
        ) else (
            echo ERROR: Config file not found: "%CONFIG_FILES_PATH%\!CONFIG_FILE!"
            call :LogMessage "ERROR: Config file not found"
        )
    )
    
    echo.
    echo Launching characters from this group:
    
    REM Launch each character in this group
    REM Replace commas with spaces for proper iteration
    set "CHAR_GROUP_SPACED=!CHAR_GROUP:,= !"
    call :LogMessage "Character group with spaces: !CHAR_GROUP_SPACED!"
    
    for %%c in (!CHAR_GROUP_SPACED!) do (
        set "CHAR_NAME=%%c"
        echo Launching: !CHAR_NAME!
        call :LogMessage "Launching character: !CHAR_NAME!"
        
        REM Change to Windower directory and run autoPOL directly (similar to manual execution)
        for %%F in ("%AUTOPOL_PATH%") do set "WINDOWER_DIR=%%~dpF"
        call :LogMessage "Changing to Windower directory: !WINDOWER_DIR!"
        call :LogMessage "Executing: autoPOL.exe --character !CHAR_NAME!"
        
        pushd "!WINDOWER_DIR!"
        start "" "autoPOL.exe" --character !CHAR_NAME!
        popd
        
        REM Wait between character launches
        echo Waiting !LAUNCH_DELAY! seconds before next character...
        call :LogMessage "Waiting !LAUNCH_DELAY! seconds between character launches"
        timeout /t !LAUNCH_DELAY! /nobreak >nul
    )
    
    :EndProcessSingleGroup
    echo.
    echo Waiting !BIN_SWAP_DELAY! seconds before next bin file...
    call :LogMessage "Waiting !BIN_SWAP_DELAY! seconds before next bin file"
    timeout /t !BIN_SWAP_DELAY! /nobreak >nul
    echo.
)
exit /b 0

REM ===================================================================
REM END OF SCRIPT
REM ===================================================================