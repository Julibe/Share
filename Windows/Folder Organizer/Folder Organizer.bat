<# :
@echo off
setlocal
cd /d "%~dp0"
:: 1 = Blue Background, E = Light Yellow Text
color 1E
title Julibe's Item Organizer

:: --- HEADER ---
cls
echo ========================================================
echo       JULIBE'S FOLDER ORGANIZER
echo       Julibe (https://julibe.com) - Crafting Amazing Digital Experiences
echo       Copyright 2026
echo ========================================================
echo.

:: 1. CHECK INPUT
if "%~1"=="" (
    echo [ERROR] No items detected.
    echo Please drag and drop files and/or folders onto this file.
    echo.
    pause
    exit /b
)

:: 2. PREPARE HYBRID EXECUTION
for /f "usebackq delims=" %%G in (`powershell -NoProfile -Command "[guid]::NewGuid().ToString()"`) do set "PS_GUID=%%G"
set "PS_FILE=%temp%\%~n0_%PS_GUID%_organizer.ps1"
copy /y "%~f0" "%PS_FILE%" >nul

echo [STATUS] Analyzing dropped items...
echo.

:: 3. EXECUTE
powershell -NoProfile -ExecutionPolicy Bypass -File "%PS_FILE%" %*

:: 4. CLEANUP & HOLD
del "%PS_FILE%"
echo.
echo ========================================================
echo [BATCH STATUS] Organizing finished.
echo ========================================================
pause
exit /b
#>

# ============================================================
# POWERSHELL LOGIC
# ============================================================

# --- CONFIGURATION ---
$replacement_char = " "    # Character used to replace non-alphanumeric characters
$naming_case = "Title"     # Options: "Title", "Upper", "Lower"
# ---------------------

# Load VisualBasic for InputBox
Add-Type -AssemblyName Microsoft.VisualBasic

$debug_mode = $true

# Counters for the end-of-run summary
$moved_count = 0
$skipped_count = 0
$failed_count = 0
$renamed_count = 0
$overwritten_count = 0

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

    $isFolder = (Test-Path $path -PathType Container)

    if ($isFolder) {
        $filename = [System.IO.Path]::GetFileName($path)
        $extension = ""
    } else {
        $filename = [System.IO.Path]::GetFileNameWithoutExtension($path)
        $extension = [System.IO.Path]::GetExtension($path)
    }

    $counter = 2
    $newPath = $path

    while (Test-Path $newPath) {
        if ($isFolder) {
            $newPath = Join-Path $directory "$filename ($counter)"
        } else {
            $newPath = Join-Path $directory "$filename ($counter)$extension"
        }
        $counter++
    }
    return $newPath
}

function Get-SanitizedName {
    param([string]$name, [string]$replacement)
    $invalidChars = [System.IO.Path]::GetInvalidFileNameChars() -join ''
    $pattern = "[$([regex]::Escape($invalidChars))]"
    $clean = $name -replace $pattern, $replacement
    return $clean.Trim()
}

# --- MAIN LOGIC ---

$dropped_items = $args

if ($dropped_items.Count -eq 0) {
    Write-Host "[ERROR] You must drag files or folders onto the script." -ForegroundColor Red
    exit
}

# 1. Determine Name from the FIRST dropped item
$first_item = Get-Item $dropped_items[0]
$default_name = if ($first_item.PSIsContainer) { $first_item.Name } else { $first_item.BaseName }
$parent_dir = Split-Path $first_item.FullName -Parent

Write-Host "Found $($dropped_items.Count) item(s) to process."

# --- NORMALIZATION ---

# Step A: Replace all non-alphanumeric chars (including periods, commas, dashes, underscores)
# with a space temporarily. This ensures Title Casing can identify separate words properly.
# \p{L} = Any Letter, \p{Nd} = Any Number.
$default_name = $default_name -replace '[^\p{L}\p{Nd}]+', ' '

# Step B: Apply the chosen naming case
switch ($naming_case.ToLower()) {
    "upper" { $default_name = $default_name.ToUpper() }
    "lower" { $default_name = $default_name.ToLower() }
    "title" {
        # ToTitleCase works best when starting from all lowercase
        $default_name = (Get-Culture).TextInfo.ToTitleCase($default_name.ToLower())
    }
}

# Step C: Swap the temporary spaces with the configured replacement character
if ($replacement_char -ne " ") {
    $default_name = $default_name -replace ' ', $replacement_char
}

# Step D: Trim leading and trailing whitespace
$default_name = $default_name.Trim()


# --- POPUP INPUT BOX ---
$target_folder_name = [Microsoft.VisualBasic.Interaction]::InputBox("Confirm or edit the normalized folder name:", "Julibe's Item Organizer", $default_name)

if ([string]::IsNullOrWhiteSpace($target_folder_name)) {
    Write-Host "[CANCELLED] Operation aborted by user." -ForegroundColor Red
    exit
}

# Trim final input just in case the user added accidental spaces
$target_folder_name = $target_folder_name.Trim()
$target_folder_name = Get-SanitizedName -name $target_folder_name -replacement $replacement_char

if ([string]::IsNullOrWhiteSpace($target_folder_name)) {
    Write-Host "[CANCELLED] Name became empty after removing invalid characters." -ForegroundColor Red
    exit
}

$destination_path = Join-Path $parent_dir $target_folder_name

# Create Destination
if (!(Test-Path $destination_path)) {
    New-Item -ItemType Directory -Path $destination_path | Out-Null
    Write-Host "[CREATED] $destination_path"
} else {
    Write-Host "[TARGET] Moving into existing: $destination_path"
}

echo "--------------------------------------------------------"

# Track a running "apply to all" choice so large batches of conflicts
# don't require answering one at a time.
$apply_all_action = $null

# 2. Process Move
foreach ($itemPath in $dropped_items) {
    # Safety: Prevent trying to move the destination folder into itself
    if ($itemPath -eq $destination_path) { continue }

    $item = Get-Item $itemPath

    # Guard against dropping a folder that the newly-created destination
    # actually lives inside of.
    if ($item.PSIsContainer) {
        $itemFullWithSep = $item.FullName.TrimEnd('\') + '\'
        if ($destination_path.StartsWith($itemFullWithSep, [System.StringComparison]::OrdinalIgnoreCase)) {
            Write-Host "Skipping: $($item.Name)" -ForegroundColor Yellow
            Write-Host "   -> Skipped (destination is nested inside this folder)" -ForegroundColor Yellow
            $skipped_count++
            continue
        }
    }

    Write-Host "Moving: $($item.Name)" -ForegroundColor Cyan

    $destItem = Join-Path $destination_path $item.Name

    # Wrap each item's move so one failure doesn't abort the whole batch.
    try {
        # CONFLICT HANDLING
        if (Test-Path $destItem) {
            $action = $apply_all_action

            if (-not $action) {
                Write-Host "`n[CONFLICT] Item exists: " -NoNewline -ForegroundColor Red
                Write-Host $item.Name
                Write-Host "   (O)verwrite  |  (R)ename  |  (S)kip  |  (OA) Overwrite All  |  (RA) Rename All  |  (SA) Skip All" -ForegroundColor Gray

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
                Move-Item -Path $item.FullName -Destination $destItem -Force -ErrorAction Stop
                Write-Host "   -> Overwritten" -ForegroundColor Red
                $overwritten_count++
                $moved_count++
            }
            elseif ($action -eq "R") {
                $newDest = Get-UniqueFileName $destItem
                Move-Item -Path $item.FullName -Destination $newDest -ErrorAction Stop
                Write-Host "   -> Renamed: $([System.IO.Path]::GetFileName($newDest))"
                $renamed_count++
                $moved_count++
            }
            else {
                Write-Host "   -> Skipped" -ForegroundColor Gray
                $skipped_count++
            }
        }
        else {
            Move-Item -Path $item.FullName -Destination $destItem -ErrorAction Stop
            Write-Host "   -> Done"
            $moved_count++
        }
    }
    catch {
        Write-Host "   -> FAILED: $($_.Exception.Message)" -ForegroundColor Red
        $failed_count++
    }
}

echo ""
echo "--------------------------------------------------------"
Write-Host "Organize Complete."
Write-Host "  Moved:   $moved_count  (overwritten: $overwritten_count, renamed: $renamed_count)"
Write-Host "  Skipped: $skipped_count"
Write-Host "  Failed:  $failed_count" -ForegroundColor $(if ($failed_count -gt 0) { "Red" } else { "Gray" })
Write-Host "Press Enter to exit..."
[void][Console]::ReadLine()