# FFXI Multi-Character Login Script

This script automatically launches multiple FFXI characters, detecting which ones are already running and only starting the missing ones. It supports switching between different login credential files and autoPOL configurations for different sets of characters.

## Features

- **Smart character detection**: Automatically detects already running characters and skips them
- **Multi-account support**: Handles different login credential files (bin files) for different sets of characters
- **autoPOL configuration management**: Automatically switches autoPOL configs for different character groups
- **Configurable timing**: Customizable delays between character launches and bin file switches
- **Comprehensive logging**: Debug logging with timestamps for troubleshooting
- **Admin privilege handling**: Automatically requests administrator privileges when needed
- **JSON configuration**: All settings stored in an easy-to-edit JSON file

## Prerequisites

1. **FFXI installed via Steam** (or other method)
2. **autoPOL 4** installed and configured
3. **Multiple character login files** (chars1.bin, chars2.bin, etc.)
4. **autoPOL configuration files** for different character sets
5. **Administrator privileges** (script will auto-elevate)

## Setup Instructions

### 1. File Structure

Your login directory should look like this:

```
login/
├── ffxi-login.bat              # Main script
├── ffxi-login-config.json      # Configuration file
├── README.md                   # This file
├── POL-chars1.bin              # POL login binary for first set of characters
├── POL-chars2.bin              # POL login binary for second set of characters
├── autoPOL-config-1.json       # autoPOL config for first set
├── autoPOL-config-2.json       # autoPOL config for second set
└── ffxi-login.log              # Generated log file (created when script runs)
```

### 2. Configuration File Setup

Edit `ffxi-login-config.json` to match your system:

```json
{
  "paths": {
    "autopol_path": "C:\\Program Files (x86)\\autoPOL\\autoPOL.exe",
    "bin_files_path": "D:\\Games\\FFXI\\login",
    "login_bin_dest": "C:\\Users\\YourUsername\\Documents\\Games\\Steam\\steamapps\\common\\FFXINA\\SquareEnix\\PlayOnlineViewer\\usr\\all\\login_w.bin",
    "autopol_config_dest": "C:\\Program Files (x86)\\autoPOL\\config.json",
    "config_files_path": "D:\\Games\\FFXI\\login"
  },
  "timing": {
    "launch_delay": 5,
    "bin_swap_delay": 20
  },
  "logging": {
    "debug_mode": true,
    "log_file": "ffxi-login.log"
  },
  "characters": [
    {
      "name": "mycharacter1",
      "bin_file": "POL-chars1.bin",
      "config_file": "autoPOL-config-1.json"
    },
    {
      "name": "mycharacter2",
      "bin_file": "POL-chars1.bin",
      "config_file": "autoPOL-config-1.json"
    }
  ]
}
```

### 3. Path Configuration

Update the following paths in the configuration file:

#### `autopol_path`
- Path to autoPOL's autoPOL.exe
- Default: `C:\Program Files (x86)\Windower\autoPOL.exe`

#### `bin_files_path`
- Directory containing your character login files (chars1.bin, chars2.bin, etc.)
- Should be the same directory as this script

#### `login_bin_dest`
- Path to FFXI's login_w.bin file
- **Steam path**: `C:\Users\[USERNAME]\Documents\Games\Steam\steamapps\common\FFXINA\SquareEnix\PlayOnlineViewer\usr\all\login_w.bin`
- **Retail path**: `C:\Program Files (x86)\PlayOnline\SquareEnix\PlayOnlineViewer\usr\all\login_w.bin`

#### `autopol_config_dest`
- Path to autoPOL's config.json file
- Default: `C:\Program Files (x86)\Windower\config.json`

#### `config_files_path`
- Directory containing your autoPOL configuration files
- Should be the same directory as this script

### 4. Character Configuration

For each character, add an entry to the `characters` array:

```json
{
  "name": "mycharacter1",
  "bin_file": "chars1.bin",
  "config_file": "autoPOL-config-1.json"
}
```

- **name**: Exact character name as it appears in-game
- **bin_file**: Which login credential file to use
- **config_file**: Which autoPOL configuration to use

### 5. Timing Configuration

- **launch_delay**: Seconds to wait between launching individual characters (default: 5)
- **bin_swap_delay**: Seconds to wait between switching bin files (default: 20)

### 6. Creating Login Credential Files

1. **Log into your first set of characters manually**
2. **Copy the login_w.bin file** from your FFXI installation to `chars1.bin` in your login directory
3. **Repeat for other character sets** (chars2.bin, etc.)

### 7. Creating autoPOL Configuration Files

1. **Configure autoPOL** for your first set of characters (character names, positions, etc.)
2. **Copy config.json** from autoPOL directory to `config-1.json` in your login directory
3. **Repeat for other character sets** (config-2.json, etc.)

## Usage

1. **Run the script**: Double-click `ffxi-login.bat` or run from command line
2. **Administrator elevation**: Script will automatically request admin privileges if needed
3. **Character detection**: Script checks which characters are already running
4. **Automatic launching**: Only launches characters that aren't already running
5. **Progress monitoring**: Watch the console output for launch progress

## How It Works

1. **Detection Phase**: Scans running processes to identify already-running FFXI characters
2. **Grouping Phase**: Groups pending characters by their bin file and config file
3. **Launch Phase**: For each group:
   - Copies the appropriate login credentials (bin file)
   - Copies the appropriate autoPOL configuration
   - Launches all characters in that group
   - Waits before processing the next group

## Troubleshooting

### Script won't run
- Ensure you're running as administrator
- Check that all paths in the config file are correct
- Verify that autoPOL.exe exists at the specified path

### Characters not launching
- Check the log file for error messages
- Verify character names match exactly (case-sensitive)
- Ensure bin files and config files exist
- Check that autoPOL is properly installed

### Characters not detected as running
- Make sure FFXI characters are fully logged in (past character selection)
- Check that character names in config match the window titles exactly
- Review the log file for detection details

### Login issues
- Verify that your bin files contain valid, up-to-date login credentials
- Check that the destination path for login_w.bin is correct
- Ensure you have write permissions to the FFXI directory

## Log Files

The script creates detailed logs in `ffxi-login.log`. This file contains:
- Configuration loading details
- Character detection results
- File copy operations
- Launch commands and timing
- Error messages and troubleshooting information

Set `debug_mode` to `false` in the config to reduce console output while keeping file logging.

## Tips

- **Test with one character first** to ensure paths are correct
- **Keep backup copies** of your bin files and config files
- **Use descriptive character names** that match your in-game names exactly
- **Adjust timing delays** based on your system performance
- **Check logs** if anything doesn't work as expected

## Security Notes

- **Bin files contain login credentials** - keep them secure
- **Run from a secure location** that other users can't access
- **Be careful when sharing** configuration files (they contain paths that might reveal usernames)

## Common Configuration Examples

### Steam Installation (Default)
```json
"login_bin_dest": "C:\\Users\\YourUsername\\Documents\\Games\\Steam\\steamapps\\common\\FFXINA\\SquareEnix\\PlayOnlineViewer\\usr\\all\\login_w.bin"
```

### Retail Installation
```json
"login_bin_dest": "C:\\Program Files (x86)\\PlayOnline\\SquareEnix\\PlayOnlineViewer\\usr\\all\\login_w.bin"
```

### Custom FFXI Installation
```json
"login_bin_dest": "D:\\Games\\FFXI\\SquareEnix\\PlayOnlineViewer\\usr\\all\\login_w.bin"
```
```
