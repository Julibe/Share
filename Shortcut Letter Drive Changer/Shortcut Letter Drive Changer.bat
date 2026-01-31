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
set "PS_FILE=%temp%\%~n0_theme.ps1"
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

        # Regex replace for the drive letter
        $shortcut.TargetPath = $old_target -replace '^[A-Z]:', $new_drive
        $shortcut.WorkingDirectory = $old_work -replace '^[A-Z]:', $new_drive

        if ($old_icon -match '^[A-Z]:') {
            $shortcut.IconLocation = $old_icon -replace '^[A-Z]:', $new_drive
        }

        $shortcut.Save()
        # White text ensures it is visible on the Green background
        Write-Host "[SUCCESS] Updated -> $new_drive" -ForegroundColor White
    }
    catch {
        Write-Host "[ERROR] Could not save $($file_path)" -ForegroundColor Red
        Write-Host "        Reason: $($_.Exception.Message)" -ForegroundColor Red
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
        $target_drive = $input_letter.Trim().ToUpper().Replace(":", "") + ":"
        Write-Host "[LOG] Target Drive: $target_drive" -ForegroundColor White
        Write-Host "--------------------------------------------------------"

        foreach ($path in $dropped_args) {
            if (Test-Path $path -PathType Container) {
                Write-Host "[LOG] Scanning folder: $path"
                $files = Get-ChildItem -Path $path -Filter *.lnk -Recurse
                foreach ($f in $files) { updateShortcut $f.FullName $target_drive }
            }
            elseif ($path -like "*.lnk") {
                updateShortcut $path $target_drive
            }
            else {
                Write-Host "[SKIP] Not a shortcut: $path"
            }
        }
    }
}

Write-Host "`n--------------------------------------------------------"
Write-Host "PowerShell Tasks Completed." -ForegroundColor White
Write-Host "Press Enter to return to Batch..."
[void][Console]::ReadLine()