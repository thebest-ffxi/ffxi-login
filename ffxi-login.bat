@echo off
setlocal enabledelayedexpansion

REM ================================
REM FFXI Multi-Character Login Script
REM ================================
REM This script automatically launches multiple FFXI characters, detecting which ones are already running
REM and only starting the missing ones. It supports switching between different login credential files
REM for different sets of characters.

REM Check for admin privileges
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo This script requires administrator privileges.
    echo Requesting elevation...
    powershell -Command "Start-Process cmd -Argument '/c \"%~f0\"' -Verb runAs"
    exit /b
)

echo ================================
echo FFXI Multi-Character Login Script
echo ================================
echo.

REM Set up variables
set "PS_SCRIPT=%~dp0load-config.ps1"
set "CONFIG_FILE=%~dp0ffxi-login-config.json"

REM Initialize log file
set "LOG_FILE=%~dp0ffxi-login.log"
echo [%date% %time%] Script started >> "%LOG_FILE%"
echo Loading configuration from: %CONFIG_FILE% >> "%LOG_FILE%"

REM Check if config file exists
if not exist "%CONFIG_FILE%" (
    echo ERROR: Configuration file not found: "%CONFIG_FILE%"
    echo Please create %CONFIG_FILE% based on the example configuration.
    pause
    exit /b 1
)

REM Check if PowerShell config loader exists
if not exist "%PS_SCRIPT%" (
    echo ERROR: PowerShell config loader not found: "%PS_SCRIPT%"
    pause
    exit /b 1
)

echo Loading configuration...

REM Initialize variables
set "AUTOPOL_PATH="
set "BIN_FILES_PATH="
set "LOGIN_BIN_DEST="
set "LAUNCH_DELAY="
set "BIN_SWAP_DELAY="
set "DEBUG_MODE="
set "LOG_FILE_NAME="
set "CHAR_LIST="

REM Load configuration using PowerShell
set "IN_CHAR_LIST=0"
for /f "usebackq delims=" %%i in (`powershell -NoProfile -ExecutionPolicy Bypass -File "%PS_SCRIPT%" "%CONFIG_FILE%"`) do (
    set "LINE=%%i"
    
    if "!LINE!"=="CHAR_LIST_START" (
        set "IN_CHAR_LIST=1"
    ) else if "!LINE!"=="CHAR_LIST_END" (
        set "IN_CHAR_LIST=0"
    ) else if "!IN_CHAR_LIST!"=="1" (
        if "!CHAR_LIST!"=="" (
            set "CHAR_LIST=!LINE!"
        ) else (
            set "CHAR_LIST=!CHAR_LIST! !LINE!"
        )
    ) else (
        REM Process configuration variables
        for /f "tokens=1,2 delims==" %%a in ("!LINE!") do (
            set "%%a=%%b"
        )
    )
)

call :LogMessage "Configuration loaded successfully"
call :LogMessage "  AUTOPOL_PATH=%AUTOPOL_PATH%"
call :LogMessage "  BIN_FILES_PATH=%BIN_FILES_PATH%"
call :LogMessage "  LOGIN_BIN_DEST=%LOGIN_BIN_DEST%"
call :LogMessage "  LAUNCH_DELAY=%LAUNCH_DELAY%"
call :LogMessage "  BIN_SWAP_DELAY=%BIN_SWAP_DELAY%"
call :LogMessage "  DEBUG_MODE=%DEBUG_MODE%"

REM Validate paths
if not exist "%AUTOPOL_PATH%" (
    echo ERROR: autoPOL executable not found at: "%AUTOPOL_PATH%"
    echo Please update the autopol_path in %CONFIG_FILE%
    pause
    exit /b 1
)

call :LogMessage "autoPOL path verified"

if not exist "%BIN_FILES_PATH%" (
    echo ERROR: Bin files directory not found: "%BIN_FILES_PATH%"
    echo Please update the bin_files_path in %CONFIG_FILE%
    pause
    exit /b 1
)

call :LogMessage "Bin files path verified"

REM Check if the destination login_w.bin directory exists
for %%f in ("%LOGIN_BIN_DEST%") do set "LOGIN_BIN_DIR=%%~dpf"
if not exist "%LOGIN_BIN_DIR%" (
    echo ERROR: Login bin destination directory not found: "%LOGIN_BIN_DIR%"
    echo Please check the login_bin_dest path in %CONFIG_FILE%
    pause
    exit /b 1
)

call :LogMessage "Login bin destination path verified"

echo Configuration loaded successfully.
echo autoPOL Path: %AUTOPOL_PATH%
echo Bin Files Path: %BIN_FILES_PATH%
echo Login Bin Destination: %LOGIN_BIN_DEST%
echo.

call :LogMessage "Starting character detection and launch process"

REM Check which characters are running
call :CheckRunningCharacters

REM Check if there are any characters to launch
if !PENDING_COUNT! equ 0 (
    echo All characters are already running!
    call :LogMessage "All characters already running - script complete"
    echo.
    echo All operations complete!
    call :LogMessage "Script completed successfully"
    pause
    exit /b 0
)

REM Group pending characters by bin file
call :GroupCharactersByBin

REM Launch character groups
call :LaunchCharacterGroups

echo.
echo All operations complete!
call :LogMessage "Script completed successfully"
pause
exit /b 0

REM ================================
REM Function: Check Running Characters
REM ================================
:CheckRunningCharacters
call :LogMessage "Entering CheckRunningCharacters function"
echo Checking which characters are already running...

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
    for /f "tokens=1,2 delims=:" %%a in ("%%i") do (
        set "CHAR_NAME=%%a"
        set "BIN_FILE=%%b"
        
        call :LogMessage "Checking character: !CHAR_NAME! (bin: !BIN_FILE!)"
        
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
            echo [PENDING] !CHAR_NAME! ^(using !BIN_FILE!^)
            call :LogMessage "Marked !CHAR_NAME! as PENDING (using !BIN_FILE!)"
        )
    )
)

REM Clean up temporary file
if exist "%TEMP_FILE%" del "%TEMP_FILE%"
call :LogMessage "CheckRunningCharacters function complete"

echo.
echo Summary: %RUNNING_COUNT% running, %PENDING_COUNT% pending
echo.

exit /b 0

REM ================================
REM Function: Group Characters by Bin File
REM ================================
:GroupCharactersByBin
call :LogMessage "Entering GroupCharactersByBin function"

set "BIN_GROUPS="
set "CURRENT_BIN="
set "CURRENT_GROUP="

call :LogMessage "Pending characters to group: !PENDING_CHARS!"

REM Sort pending characters by bin file
for %%i in (!PENDING_CHARS!) do (
    call :LogMessage "Raw pending character entry: %%i"
    for /f "tokens=1,2 delims=:" %%a in ("%%i") do (
        set "CHAR_NAME=%%a"
        set "BIN_FILE=%%b"
        
        call :LogMessage "Processing character !CHAR_NAME! with bin !BIN_FILE!"
        
        if "!CURRENT_BIN!" neq "!BIN_FILE!" (
            if "!CURRENT_GROUP!" neq "" (
                set "BIN_GROUPS=!BIN_GROUPS!|!CURRENT_BIN!:!CURRENT_GROUP!"
                call :LogMessage "Created group: !CURRENT_BIN!:!CURRENT_GROUP!"
            )
            set "CURRENT_BIN=!BIN_FILE!"
            set "CURRENT_GROUP=!CHAR_NAME!"
            call :LogMessage "Started new group with bin=!CURRENT_BIN!, first_char=!CURRENT_GROUP!"
        ) else (
            set "CURRENT_GROUP=!CURRENT_GROUP!,!CHAR_NAME!"
            call :LogMessage "Added !CHAR_NAME! to existing group, now: !CURRENT_GROUP!"
        )
    )
)

REM Add the last group
if "!CURRENT_GROUP!" neq "" (
    set "BIN_GROUPS=!BIN_GROUPS!|!CURRENT_BIN!:!CURRENT_GROUP!"
    call :LogMessage "Added final group: !CURRENT_BIN!:!CURRENT_GROUP!"
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

REM Process each group
set "GROUP_COUNT=0"
for %%G in ("!GROUPS:|=" "!") do (
    set /a GROUP_COUNT+=1
    set "GROUP=%%~G"
    call :LogMessage "Processing group !GROUP_COUNT!: !GROUP!"
    call :ProcessSingleGroup "!GROUP!"
    
    REM Wait between groups (except for the last one)
    call :LogMessage "Checking if this is the last group"
    set "REMAINING_GROUPS=!GROUPS!"
    for /L %%i in (1,1,!GROUP_COUNT!) do (
        for /f "tokens=1* delims=|" %%a in ("!REMAINING_GROUPS!") do (
            set "REMAINING_GROUPS=%%b"
        )
    )
    if "!REMAINING_GROUPS!" neq "" (
        echo Waiting %BIN_SWAP_DELAY% seconds before next group...
        call :LogMessage "Waiting %BIN_SWAP_DELAY% seconds before next group"
        timeout /t %BIN_SWAP_DELAY% /nobreak >nul
    )
)

call :LogMessage "LaunchCharacterGroups function complete"
exit /b 0

:ProcessSingleGroup
set "GROUP_ENTRY=%~1"
call :LogMessage "Raw group entry: !GROUP_ENTRY!"

for /f "tokens=1,2 delims=:" %%a in ("!GROUP_ENTRY!") do (
    set "BIN_FILE=%%a"
    set "CHAR_GROUP=%%b"
    
    call :LogMessage "Parsed - BIN_FILE=!BIN_FILE!, CHAR_GROUP=!CHAR_GROUP!"
    
    echo ===================================================================
    echo Switching to bin file: !BIN_FILE!
    echo ===================================================================
    call :LogMessage "Processing bin file: !BIN_FILE!, with characters: !CHAR_GROUP!"
    
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

REM ================================
REM Function: Log Message
REM ================================
:LogMessage
set "MESSAGE=%~1"
echo [%date% %time%] %MESSAGE% >> "%LOG_FILE%"
if "%DEBUG_MODE%"=="1" echo [DEBUG] %MESSAGE%
exit /b 0
