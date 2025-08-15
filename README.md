# FFXI Multi-Character Login Script

This script automatically launches multiple FFXI characters, detecting which ones are already running and only starting the missing ones.

## What it does

- Detects which FFXI characters are already logged in
- Launches only the characters that aren't running
- Handles >4 PlayOnline accounts by switching login files

## Setup

### 1. Install autoPOL

1. [Download autoPOL](https://github.com/jaku/FFXI-autoPOL/releases) and copy it to your Windower directory (usually `C:\Program Files (x86)\Windower\`)
2. Run autoPOL by clicking it, and set up all your characters with their account credentials, character slots (1 to 4), and settings
    * character slot should be the slot for the corresponding POL bin file (i.e. you can repeat character slots)

### 2. Set up POL login files

PlayOnline has a limit of 4 characters, so we need to create POL login bin files for each set of characters.

1. **Set up your characters in PlayOnline**: Add all your accounts to the 1st screen in POL normally
2. **Copy the login file**: Go to your FFXI directory and copy `login_w.bin` to this script's folder as something like `POL-chars1.bin`
3. **For additional accounts**: Remove the accounts from the POL login screen and add the other ones, then copy `login_w.bin` as something like `POL-chars2.bin`

You can do this for as many accounts/sets of accounts as you need.

### 3. Configure the script

Rename `ffxi-login-config.example.json` to `ffxi-login-config.json` and update:

- `autopol_path`: Path to autoPOL.exe (usually `C:\Program Files (x86)\Windower\autoPOL.exe`)
- `login_bin_dest`: Path to your FFXI's `login_w.bin` file
- `characters`: List each character with its name and which bin file to use

Example:
```json
{
  "paths": {
    "autopol_path": "C:\\Program Files (x86)\\Windower\\autoPOL.exe",
    "login_bin_dest": "C:\\Users\\YourName\\Documents\\Games\\Steam\\steamapps\\common\\FFXINA\\SquareEnix\\PlayOnlineViewer\\usr\\all\\login_w.bin"
  },
  "characters": [
    {
      "name": "Character1",
      "bin_file": "POL-chars1.bin"
    },
    {
      "name": "Character2", 
      "bin_file": "POL-chars2.bin"
    }
  ]
}
```

## Usage

1. Double-click `ffxi-login.bat`
2. The script will automatically request administrator privileges
3. It will detect running characters and launch the missing ones
4. Check `ffxi-login.log` if you have any issues

## Common paths

**Steam FFXI**: `C:\Users\[USERNAME]\Documents\Games\Steam\steamapps\common\FFXINA\SquareEnix\PlayOnlineViewer\usr\all\login_w.bin`

**Retail FFXI**: `C:\Program Files (x86)\PlayOnline\SquareEnix\PlayOnlineViewer\usr\all\login_w.bin`
