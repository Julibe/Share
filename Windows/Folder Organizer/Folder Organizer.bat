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
echo       JULIBE'S ITEM ORGANIZER
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
set "PS_FILE=%temp%\%~n0_organizer.ps1"
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

# --- MAIN LOGIC ---

$dropped_items = $args

if ($dropped_items.Count -eq 0) {
    Write-Host "[ERROR] You must drag files or folders onto the script." -ForegroundColor Red
    exit
}

# 1. Determine Name from the FIRST dropped item
$first_item = Get-Item $dropped_items[0]
$default_name = $first_item.BaseName
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
$destination_path = Join-Path $parent_dir $target_folder_name

# Create Destination
if (!(Test-Path $destination_path)) {
    New-Item -ItemType Directory -Path $destination_path | Out-Null
    Write-Host "[CREATED] $destination_path"
} else {
    Write-Host "[TARGET] Moving into existing: $destination_path"
}

echo "--------------------------------------------------------"

# 2. Process Move
foreach ($itemPath in $dropped_items) {
    # Safety: Prevent trying to move the destination folder into itself
    if ($itemPath -eq $destination_path) { continue }

    $item = Get-Item $itemPath
    Write-Host "Moving: $($item.Name)" -ForegroundColor Cyan

    $destItem = Join-Path $destination_path $item.Name

    # CONFLICT HANDLING
    if (Test-Path $destItem) {
        Write-Host "`n[CONFLICT] Item exists: " -NoNewline -ForegroundColor Red
        Write-Host $item.Name
        Write-Host "   (O)verwrite  |  (R)ename  |  (S)kip" -ForegroundColor Gray

        $action = Read-Host "   Choice"
        $action = $action.Trim().ToUpper()

        if ($action -eq "O") {
            Move-Item -Path $item.FullName -Destination $destItem -Force
            Write-Host "   -> Overwritten" -ForegroundColor Red
        }
        elseif ($action -eq "R") {
            $newDest = Get-UniqueFileName $destItem
            Move-Item -Path $item.FullName -Destination $newDest
            Write-Host "   -> Renamed: $([System.IO.Path]::GetFileName($newDest))"
        }
        else {
            Write-Host "   -> Skipped" -ForegroundColor Gray
        }
    }
    else {
        Move-Item -Path $item.FullName -Destination $destItem
        Write-Host "   -> Done"
    }
}

echo ""
echo "--------------------------------------------------------"
Write-Host "Organize Complete."
Write-Host "Press Enter to exit..."
[void][Console]::ReadLine()