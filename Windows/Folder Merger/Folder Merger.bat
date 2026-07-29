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
for /f "usebackq delims=" %%G in (`powershell -NoProfile -Command "[guid]::NewGuid().ToString()"`) do set "PS_GUID=%%G"
set "PS_FILE=%temp%\%~n0_%PS_GUID%_merger.ps1"
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

# Counters for the end-of-run summary
$moved_count = 0
$renamed_count = 0
$overwritten_count = 0
$skipped_count = 0
$failed_count = 0
$recycled_count = 0
$kept_count = 0

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

function Get-SanitizedName {
    param([string]$name, [string]$replacement = " ")
    $invalidChars = [System.IO.Path]::GetInvalidFileNameChars() -join ''
    $pattern = "[$([regex]::Escape($invalidChars))]"
    $clean = $name -replace $pattern, $replacement
    return $clean.Trim()
}

# --- MAIN LOGIC ---

$dropped_items = $args

# Filter for folders only, and normalize each path via Get-Item so that
# later string comparisons/Substring math are reliable.
$source_folders = @()
foreach ($item in $dropped_items) {
    if (Test-Path $item -PathType Container) {
        $source_folders += (Get-Item $item).FullName
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

$target_folder_name = Get-SanitizedName -name $target_folder_name.Trim()

if ([string]::IsNullOrWhiteSpace($target_folder_name)) {
    Write-Host "[CANCELLED] Name became empty after removing invalid characters." -ForegroundColor Red
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
$destination_path = (Get-Item $destination_path).FullName

echo "--------------------------------------------------------"

# Track a running "apply to all" choice so large merges with many conflicts
# don't require answering one at a time.
$apply_all_action = $null

# 2. Process Merge
foreach ($folder in $source_folders) {
    if ($folder -eq $destination_path) { continue }

    # Guard against a source folder that contains the destination, or a
    # source folder that now lives inside the destination.
    $folderWithSep = $folder.TrimEnd('\') + '\'
    if ($destination_path.StartsWith($folderWithSep, [System.StringComparison]::OrdinalIgnoreCase)) {
        Write-Host "Skipping: $folder (destination is nested inside this folder)" -ForegroundColor Yellow
        continue
    }
    if ($folder.StartsWith($destination_path.TrimEnd('\') + '\', [System.StringComparison]::OrdinalIgnoreCase)) {
        Write-Host "Skipping: $folder (this folder is nested inside the destination)" -ForegroundColor Yellow
        continue
    }

    if (!(Test-Path $folder)) {
        Write-Host "Skipping: $folder (no longer exists)" -ForegroundColor Yellow
        continue
    }

    Write-Host "Processing: $folder" -ForegroundColor DarkGray

    $files = Get-ChildItem -Path $folder -Recurse -File -Force

    foreach ($file in $files) {
        try {
            $relativePath = $file.FullName.Substring($folder.Length)
            if ($relativePath.StartsWith("\")) { $relativePath = $relativePath.Substring(1) }

            $destFile = Join-Path $destination_path $relativePath
            $destDir = [System.IO.Path]::GetDirectoryName($destFile)

            if (!(Test-Path $destDir)) {
                New-Item -ItemType Directory -Path $destDir -Force | Out-Null
            }

            # CONFLICT HANDLING
            if (Test-Path $destFile) {
                $action = $apply_all_action

                if (-not $action) {
                    Write-Host "`n[CONFLICT] File exists: " -NoNewline -ForegroundColor Red
                    Write-Host $file.Name -ForegroundColor Black
                    Write-Host "   (O)verwrite  |  (R)ename  |  (S)kip  |  (OA) Overwrite All  |  (RA) Rename All  |  (SA) Skip All" -ForegroundColor DarkGray

                    $input = Read-Host "   Choice"
                    $input = $input.Trim().ToUpper()

                    if ($input -in @("OA", "RA", "SA")) {
                        $apply_all_action = $input.Substring(0, 1)
                        $action = $apply_all_action
                    } else {
                        $action = $input
                    }
                }

                if ($action -eq "O") {
                    Move-Item -Path $file.FullName -Destination $destFile -Force -ErrorAction Stop
                    Write-Host "   -> Overwritten" -ForegroundColor Red
                    $overwritten_count++
                    $moved_count++
                }
                elseif ($action -eq "R") {
                    $newDest = Get-UniqueFileName $destFile
                    Move-Item -Path $file.FullName -Destination $newDest -ErrorAction Stop
                    Write-Host "   -> Renamed: $([System.IO.Path]::GetFileName($newDest))" -ForegroundColor Black
                    $renamed_count++
                    $moved_count++
                }
                else {
                    Write-Host "   -> Skipped" -ForegroundColor Gray
                    $skipped_count++
                }
            }
            else {
                Move-Item -Path $file.FullName -Destination $destFile -ErrorAction Stop
                Write-Host "." -NoNewline -ForegroundColor Black
                $moved_count++
            }
        }
        catch {
            Write-Host "`n   -> FAILED: $($file.Name) - $($_.Exception.Message)" -ForegroundColor Red
            $failed_count++
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
            $recycled_count++
        }
        catch {
            Write-Host "[ERROR] Could not recycle: $($folder)" -ForegroundColor Red
            $failed_count++
        }
    } else {
        Write-Host "[KEPT] Not empty: $([System.IO.Path]::GetFileName($folder))" -ForegroundColor DarkGray
        $kept_count++
    }
}

echo ""
Write-Host "Merge Complete." -ForegroundColor Black
Write-Host "  Files moved: $moved_count  (overwritten: $overwritten_count, renamed: $renamed_count)"
Write-Host "  Files skipped: $skipped_count"
Write-Host "  Files failed:  $failed_count" -ForegroundColor $(if ($failed_count -gt 0) { "Red" } else { "DarkGray" })
Write-Host "  Folders recycled: $recycled_count  |  Folders kept (not empty): $kept_count"
Write-Host "Press Enter to exit..."
[void][Console]::ReadLine()