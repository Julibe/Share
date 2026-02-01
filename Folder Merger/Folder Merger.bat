<# :
@echo off
setlocal
cd /d "%~dp0"
:: 6 = Yellow/Orange Background, 0 = Black Text
color 60
title Julibe's Folder Merger

:: --- HEADER ---
cls
echo ========================================================
echo       JULIBE'S FOLDER MERGER
echo       Julibe (https://julibe.com) - Crafting Amazing Digital Experiences
echo       Copyright 2026
echo ========================================================
echo.

:: 1. CHECK INPUT
if "%~1"=="" (
    echo [ERROR] No folders detected.
    echo Please drag and drop multiple folders onto this file.
    echo.
    pause
    exit /b
)

:: 2. PREPARE HYBRID EXECUTION
set "PS_FILE=%temp%\%~n0_merger.ps1"
copy /y "%~f0" "%PS_FILE%" >nul

echo [STATUS] Analyzing folders...
echo.

:: 3. EXECUTE
powershell -NoProfile -ExecutionPolicy Bypass -File "%PS_FILE%" %*

:: 4. CLEANUP & HOLD
del "%PS_FILE%"
echo.
echo ========================================================
echo [BATCH STATUS] Merge finished.
echo ========================================================
pause
exit /b
#>

# ============================================================
# POWERSHELL LOGIC
# ============================================================

# Load VisualBasic for InputBox AND Recycle Bin functions
Add-Type -AssemblyName Microsoft.VisualBasic

$debug_mode = $true
$fso = New-Object -ComObject Scripting.FileSystemObject

# Trap Errors
trap {
    Write-Host "`n[FATAL ERROR]" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host "At line: $($_.InvocationInfo.ScriptLineNumber)" -ForegroundColor Red
    Write-Host "`nPress Enter to exit..."
    [void][Console]::ReadLine()
    exit
}

# --- FUNCTIONS ---

function Get-UniqueFileName {
    param($path)
    $directory = [System.IO.Path]::GetDirectoryName($path)
    $filename = [System.IO.Path]::GetFileNameWithoutExtension($path)
    $extension = [System.IO.Path]::GetExtension($path)

    $counter = 2
    $newPath = $path

    while (Test-Path $newPath) {
        $newPath = Join-Path $directory "$filename ($counter)$extension"
        $counter++
    }
    return $newPath
}

# --- MAIN LOGIC ---

$dropped_items = $args

# Filter for folders only
$source_folders = @()
foreach ($item in $dropped_items) {
    if (Test-Path $item -PathType Container) {
        $source_folders += $item
    }
}

if ($source_folders.Count -eq 0) {
    Write-Host "[ERROR] You must drag FOLDERS, not files." -ForegroundColor Red
    exit
}

# 1. Determine Name
$first_folder_name = (Get-Item $source_folders[0]).Name
$parent_dir = (Get-Item $source_folders[0]).Parent.FullName

Write-Host "Found $($source_folders.Count) folders." -ForegroundColor Black

# --- POPUP INPUT BOX ---
$target_folder_name = [Microsoft.VisualBasic.Interaction]::InputBox("Edit the name for the merged folder:", "Julibe's Folder Merger", $first_folder_name)

if ([string]::IsNullOrWhiteSpace($target_folder_name)) {
    Write-Host "[CANCELLED] Operation aborted by user." -ForegroundColor Red
    exit
}

$destination_path = Join-Path $parent_dir $target_folder_name

# Create Destination
if (!(Test-Path $destination_path)) {
    New-Item -ItemType Directory -Path $destination_path | Out-Null
    Write-Host "[CREATED] $destination_path" -ForegroundColor Black
} else {
    Write-Host "[TARGET] Merging into: $destination_path" -ForegroundColor Black
}

echo "--------------------------------------------------------"

# 2. Process Merge
foreach ($folder in $source_folders) {
    if ($folder -eq $destination_path) { continue }

    Write-Host "Processing: $folder" -ForegroundColor DarkGray

    $files = Get-ChildItem -Path $folder -Recurse -File

    foreach ($file in $files) {
        $relativePath = $file.FullName.Substring($folder.Length)
        if ($relativePath.StartsWith("\")) { $relativePath = $relativePath.Substring(1) }

        $destFile = Join-Path $destination_path $relativePath
        $destDir = [System.IO.Path]::GetDirectoryName($destFile)

        if (!(Test-Path $destDir)) {
            New-Item -ItemType Directory -Path $destDir | Out-Null
        }

        # CONFLICT HANDLING
        if (Test-Path $destFile) {
            Write-Host "`n[CONFLICT] File exists: " -NoNewline -ForegroundColor Red
            Write-Host $file.Name -ForegroundColor Black
            Write-Host "   (O)verwrite  |  (R)ename  |  (S)kip" -ForegroundColor DarkGray

            $action = Read-Host "   Choice"
            $action = $action.Trim().ToUpper()

            if ($action -eq "O") {
                Move-Item -Path $file.FullName -Destination $destFile -Force
                Write-Host "   -> Overwritten" -ForegroundColor Red
            }
            elseif ($action -eq "R") {
                $newDest = Get-UniqueFileName $destFile
                Move-Item -Path $file.FullName -Destination $newDest
                Write-Host "   -> Renamed: $([System.IO.Path]::GetFileName($newDest))" -ForegroundColor Black
            }
            else {
                Write-Host "   -> Skipped" -ForegroundColor Gray
            }
        }
        else {
            Move-Item -Path $file.FullName -Destination $destFile
            Write-Host "." -NoNewline -ForegroundColor Black
        }
    }
}

echo ""
echo "--------------------------------------------------------"
Write-Host "Checking for empty folders to recycle..." -ForegroundColor Black

# 3. Clean Up (Recycle Empty Folders)
foreach ($folder in $source_folders) {
    # Safety: Never recycle the destination
    if ($folder -eq $destination_path) { continue }

    # Check if folder is truly empty (Force checks hidden files too)
    $remaining_items = Get-ChildItem -Path $folder -Recurse -Force

    if ($remaining_items.Count -eq 0) {
        try {
            # Use VisualBasic to send to Recycle Bin instead of permanent delete
            [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteDirectory($folder, 'OnlyErrorDialogs', 'SendToRecycleBin')
            Write-Host "[RECYCLED] Empty: $([System.IO.Path]::GetFileName($folder))" -ForegroundColor DarkGreen
        }
        catch {
            Write-Host "[ERROR] Could not recycle: $($folder)" -ForegroundColor Red
        }
    } else {
        Write-Host "[KEPT] Not empty: $([System.IO.Path]::GetFileName($folder))" -ForegroundColor DarkGray
    }
}

echo ""
Write-Host "Merge Complete." -ForegroundColor Black
Write-Host "Press Enter to exit..."
[void][Console]::ReadLine()