<# :
@echo off
setlocal
cd /d "%~dp0"
:: 2 = Dark Green Background, E = Light Yellow Text
color 2E
title Julibe's Shortcut Drive Changer

:: --- HEADER ---
cls
echo ========================================================
echo       SHORTCUT DRIVE CHANGER
echo       Julibe (https://julibe.com) - Crafting Amazing Digital Experiences
echo       Copyright 2026
echo ========================================================
echo.

:: 1. CHECK INPUT
if "%~1"=="" (
    echo [ERROR] No items detected.
    echo Please drag and drop shortcuts or folders onto this file.
    echo.
    pause
    exit /b
)

:: 2. PREPARE HYBRID EXECUTION
for /f "usebackq delims=" %%G in (`powershell -NoProfile -Command "[guid]::NewGuid().ToString()"`) do set "PS_GUID=%%G"
set "PS_FILE=%temp%\%~n0_%PS_GUID%_theme.ps1"
copy /y "%~f0" "%PS_FILE%" >nul

echo [STATUS] Launching PowerShell...
echo.

:: 3. EXECUTE
powershell -NoProfile -ExecutionPolicy Bypass -File "%PS_FILE%" %*

:: 4. CLEANUP & HOLD
del "%PS_FILE%"
echo.
echo ========================================================
echo [BATCH STATUS] Process finished.
echo ========================================================
pause
exit /b
#>

# ============================================================
# POWERSHELL LOGIC STARTS HERE
# ============================================================

$debug_mode = $true
$shell_object = New-Object -ComObject WScript.Shell

# Counters for the end-of-run summary
$updated_count = 0
$failed_count = 0
$skipped_count = 0

# GLOBAL TRAP: catches any crash and keeps window open
trap {
    Write-Host "`n[FATAL SYSTEM ERROR]" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host "At line: $($_.InvocationInfo.ScriptLineNumber)" -ForegroundColor Red
    Write-Host "`nPress Enter to exit..."
    [void][Console]::ReadLine()
    exit
}

function updateShortcut {
    param($file_path, $new_drive)

    try {
        if ($debug_mode) { Write-Host "[LOG] Opening: $file_path" }

        $shortcut = $shell_object.CreateShortcut($file_path)

        $old_target = $shortcut.TargetPath
        $old_work = $shortcut.WorkingDirectory
        $old_icon = $shortcut.IconLocation

        # Case-insensitive so a lowercase drive letter (e.g. "c:") is still caught
        $shortcut.TargetPath = $old_target -replace '^[A-Za-z]:', $new_drive
        $shortcut.WorkingDirectory = $old_work -replace '^[A-Za-z]:', $new_drive

        if ($old_icon -match '^[A-Za-z]:') {
            $shortcut.IconLocation = $old_icon -replace '^[A-Za-z]:', $new_drive
        }

        # Back up the original .lnk before overwriting it in place, since
        # Save() has no undo.
        try {
            Copy-Item -Path $file_path -Destination "$file_path.bak" -Force -ErrorAction Stop
        }
        catch {
            Write-Host "[WARN] Could not create backup for $($file_path): $($_.Exception.Message)" -ForegroundColor Yellow
        }

        $shortcut.Save()
        # White text ensures it is visible on the Green background
        Write-Host "[SUCCESS] Updated -> $new_drive" -ForegroundColor White
        $script:updated_count++
    }
    catch {
        Write-Host "[ERROR] Could not save $($file_path)" -ForegroundColor Red
        Write-Host "        Reason: $($_.Exception.Message)" -ForegroundColor Red
        $script:failed_count++
    }
}

# MAIN EXECUTION
Write-Host "PowerShell initialized successfully."
$dropped_args = $args

if ($dropped_args.Count -eq 0) {
    Write-Host "[ERROR] Arguments lost during handoff." -ForegroundColor Red
}
else {
    $input_letter = Read-Host "Enter the new drive letter (e.g., D)"

    if ([string]::IsNullOrWhiteSpace($input_letter)) {
        Write-Host "[ERROR] No letter entered." -ForegroundColor Red
    }
    else {
        $clean_letter = $input_letter.Trim().ToUpper().Replace(":", "")

        if ($clean_letter -notmatch '^[A-Z]$') {
            Write-Host "[ERROR] '$input_letter' is not a valid single drive letter (e.g. D)." -ForegroundColor Red
        }
        else {
        $target_drive = $clean_letter + ":"
        Write-Host "[LOG] Target Drive: $target_drive" -ForegroundColor White
        Write-Host "--------------------------------------------------------"

        foreach ($path in $dropped_args) {
            if (Test-Path $path -PathType Container) {
                Write-Host "[LOG] Scanning folder: $path"
                try {
                    $files = Get-ChildItem -Path $path -Filter *.lnk -Recurse -ErrorAction Stop
                    foreach ($f in $files) { updateShortcut $f.FullName $target_drive }
                }
                catch {
                    Write-Host "[ERROR] Could not scan folder: $path" -ForegroundColor Red
                    Write-Host "        Reason: $($_.Exception.Message)" -ForegroundColor Red
                    $failed_count++
                }
            }
            elseif ($path -like "*.lnk") {
                updateShortcut $path $target_drive
            }
            else {
                Write-Host "[SKIP] Not a shortcut: $path"
                $skipped_count++
            }
        }
        }
    }
}

Write-Host "`n--------------------------------------------------------"
Write-Host "PowerShell Tasks Completed." -ForegroundColor White
Write-Host "Press Enter to return to Batch..."
[void][Console]::ReadLine()