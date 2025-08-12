param(
    [string]$ConfigFile
)

try {
    $config = Get-Content $ConfigFile | ConvertFrom-Json
    
    # Output configuration variables in batch-friendly format
    Write-Output ("AUTOPOL_PATH=" + $config.paths.autopol_path)
    Write-Output ("BIN_FILES_PATH=" + $config.paths.bin_files_path)
    Write-Output ("LOGIN_BIN_DEST=" + $config.paths.login_bin_dest)
    Write-Output ("WINDOWER_CONFIG_DEST=" + $config.paths.autopol_config_dest)
    Write-Output ("CONFIG_FILES_PATH=" + $config.paths.config_files_path)
    Write-Output ("LAUNCH_DELAY=" + $config.timing.launch_delay)
    Write-Output ("BIN_SWAP_DELAY=" + $config.timing.bin_swap_delay)
    Write-Output ("DEBUG_MODE=" + $config.logging.debug_mode)
    Write-Output ("LOG_FILE_NAME=" + $config.logging.log_file)
    
    # Output character list in batch-friendly format
    Write-Output "CHAR_LIST_START"
    foreach($char in $config.characters) {
        Write-Output ($char.name + ":" + $char.bin_file + ":" + $char.config_file)
    }
    Write-Output "CHAR_LIST_END"
    
} catch {
    Write-Error "Error loading configuration: $_"
    exit 1
}