<# :
@echo off
setlocal
cd /d "%~dp0"
title Julibe's Folder Merger - GUI

:: 1. PREPARE HYBRID EXECUTION (extract the PowerShell half of this file to %temp%)
for /f "usebackq delims=" %%G in (`powershell -NoProfile -Command "[guid]::NewGuid().ToString()"`) do set "PS_GUID=%%G"
set "PS_FILE=%temp%\%~n0_%PS_GUID%_mergergui.ps1"
copy /y "%~f0" "%PS_FILE%" >nul

:: 2. EXECUTE (STA apartment is required for Windows Forms)
powershell -NoProfile -STA -ExecutionPolicy Bypass -File "%PS_FILE%" %*

:: 3. CLEANUP
del "%PS_FILE%" >nul 2>&1
exit /b
#>

# ============================================================================
# Julibe's Folder Merger - GUI Edition
# ----------------------------------------------------------------------------
# Author:  Julibe - Crafting Digital Experiences
# Year:    2026
# Website: https://julibe.com
# Email:   mail@julibe.com
# ----------------------------------------------------------------------------
# A drag-and-drop Windows Forms front end for the same folder-merging engine
# used by "Folder Merger.bat". This file is fully independent from the
# console version - it does not modify or depend on it in any way.
# ============================================================================

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName Microsoft.VisualBasic
[System.Windows.Forms.Application]::EnableVisualStyles()

# Hide the console window the .bat handed off from - the GUI is the interface.
try {
    Add-Type -Name Win -Namespace ConsoleUtil -MemberDefinition '
        [DllImport("kernel32.dll")] public static extern IntPtr GetConsoleWindow();
        [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
    '
    [ConsoleUtil.Win]::ShowWindow([ConsoleUtil.Win]::GetConsoleWindow(), 0) | Out-Null
} catch {}

trap {
    try {
        [System.Windows.Forms.MessageBox]::Show(
            "$($_.Exception.Message)`n`nAt line $($_.InvocationInfo.ScriptLineNumber)",
            "Julibe's Folder Merger - Fatal Error",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error) | Out-Null
    } catch {}
    exit
}

# ---------------------------------------------------------------------------
# Palette (matches the amber/construction theme of the console version)
# ---------------------------------------------------------------------------
$colorAccent     = [System.Drawing.Color]::FromArgb(230, 126, 34)
$colorAccentDark = [System.Drawing.Color]::FromArgb(198, 106, 27)
$colorBg         = [System.Drawing.Color]::FromArgb(247, 247, 245)
$colorPanel      = [System.Drawing.Color]::White
$colorText       = [System.Drawing.Color]::FromArgb(45, 45, 45)
$fontUi          = New-Object System.Drawing.Font("Segoe UI", 9.5)
$fontHeader      = New-Object System.Drawing.Font("Segoe UI Semibold", 15)
$fontMono        = New-Object System.Drawing.Font("Consolas", 9)

# ---------------------------------------------------------------------------
# Shared logic (identical behavior to the console version's helper functions)
# ---------------------------------------------------------------------------
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

# ---------------------------------------------------------------------------
# Form
# ---------------------------------------------------------------------------
$form = New-Object System.Windows.Forms.Form
$form.Text = "Julibe's Folder Merger"
$form.StartPosition = "CenterScreen"
$form.ClientSize = New-Object System.Drawing.Size(640, 560)
$form.MinimumSize = New-Object System.Drawing.Size(560, 460)
$form.BackColor = $colorBg
$form.Font = $fontUi
$form.AllowDrop = $true

# --- Header banner ---
$panelHeader = New-Object System.Windows.Forms.Panel
$panelHeader.Dock = "Top"
$panelHeader.Height = 64
$panelHeader.BackColor = $colorAccent
$form.Controls.Add($panelHeader)

$lblTitle = New-Object System.Windows.Forms.Label
$lblTitle.Text = "Folder Merger"
$lblTitle.Font = $fontHeader
$lblTitle.ForeColor = [System.Drawing.Color]::White
$lblTitle.AutoSize = $true
$lblTitle.Location = New-Object System.Drawing.Point(18, 10)
$panelHeader.Controls.Add($lblTitle)

$lblSubtitle = New-Object System.Windows.Forms.Label
$lblSubtitle.Text = "Drag folders in, pick a destination name, and consolidate them in one click."
$lblSubtitle.ForeColor = [System.Drawing.Color]::FromArgb(255, 240, 224)
$lblSubtitle.AutoSize = $true
$lblSubtitle.Location = New-Object System.Drawing.Point(19, 38)
$panelHeader.Controls.Add($lblSubtitle)

# --- Body container ---
$panelBody = New-Object System.Windows.Forms.Panel
$panelBody.Dock = "Fill"
$panelBody.Padding = New-Object System.Windows.Forms.Padding(16, 12, 16, 12)
$form.Controls.Add($panelBody)
$panelBody.BringToFront()

# --- Folder list group ---
$grpFolders = New-Object System.Windows.Forms.GroupBox
$grpFolders.Text = "Folders to Merge (drag & drop here)"
$grpFolders.Location = New-Object System.Drawing.Point(0, 0)
$grpFolders.Size = New-Object System.Drawing.Size(608, 160)
$grpFolders.Anchor = "Top,Left,Right"
$panelBody.Controls.Add($grpFolders)

$listFolders = New-Object System.Windows.Forms.ListBox
$listFolders.Location = New-Object System.Drawing.Point(12, 24)
$listFolders.Size = New-Object System.Drawing.Size(470, 122)
$listFolders.Anchor = "Top,Bottom,Left,Right"
$listFolders.HorizontalScrollbar = $true
$grpFolders.Controls.Add($listFolders)

$btnAddFolder = New-Object System.Windows.Forms.Button
$btnAddFolder.Text = "Add Folder..."
$btnAddFolder.Location = New-Object System.Drawing.Point(492, 24)
$btnAddFolder.Size = New-Object System.Drawing.Size(104, 30)
$btnAddFolder.Anchor = "Top,Right"
$btnAddFolder.FlatStyle = "Flat"
$grpFolders.Controls.Add($btnAddFolder)

$btnRemoveFolder = New-Object System.Windows.Forms.Button
$btnRemoveFolder.Text = "Remove"
$btnRemoveFolder.Location = New-Object System.Drawing.Point(492, 60)
$btnRemoveFolder.Size = New-Object System.Drawing.Size(104, 30)
$btnRemoveFolder.Anchor = "Top,Right"
$btnRemoveFolder.FlatStyle = "Flat"
$grpFolders.Controls.Add($btnRemoveFolder)

$btnClearFolders = New-Object System.Windows.Forms.Button
$btnClearFolders.Text = "Clear All"
$btnClearFolders.Location = New-Object System.Drawing.Point(492, 96)
$btnClearFolders.Size = New-Object System.Drawing.Size(104, 30)
$btnClearFolders.Anchor = "Top,Right"
$btnClearFolders.FlatStyle = "Flat"
$grpFolders.Controls.Add($btnClearFolders)

# --- Destination name ---
$lblName = New-Object System.Windows.Forms.Label
$lblName.Text = "Merged folder name:"
$lblName.Location = New-Object System.Drawing.Point(2, 172)
$lblName.AutoSize = $true
$lblName.Anchor = "Top,Left"
$panelBody.Controls.Add($lblName)

$txtName = New-Object System.Windows.Forms.TextBox
$txtName.Location = New-Object System.Drawing.Point(2, 194)
$txtName.Size = New-Object System.Drawing.Size(604, 26)
$txtName.Anchor = "Top,Left,Right"
$txtName.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$panelBody.Controls.Add($txtName)

# --- Conflict policy ---
$grpConflict = New-Object System.Windows.Forms.GroupBox
$grpConflict.Text = "When a file already exists at the destination"
$grpConflict.Location = New-Object System.Drawing.Point(0, 232)
$grpConflict.Size = New-Object System.Drawing.Size(608, 56)
$grpConflict.Anchor = "Top,Left,Right"
$panelBody.Controls.Add($grpConflict)

$radRename = New-Object System.Windows.Forms.RadioButton
$radRename.Text = "Rename (keep both, e.g. Image (2).jpg)"
$radRename.Location = New-Object System.Drawing.Point(12, 24)
$radRename.AutoSize = $true
$radRename.Checked = $true
$grpConflict.Controls.Add($radRename)

$radOverwrite = New-Object System.Windows.Forms.RadioButton
$radOverwrite.Text = "Overwrite"
$radOverwrite.Location = New-Object System.Drawing.Point(320, 24)
$radOverwrite.AutoSize = $true
$grpConflict.Controls.Add($radOverwrite)

$radSkip = New-Object System.Windows.Forms.RadioButton
$radSkip.Text = "Skip"
$radSkip.Location = New-Object System.Drawing.Point(440, 24)
$radSkip.AutoSize = $true
$grpConflict.Controls.Add($radSkip)

# --- Log ---
$lblLog = New-Object System.Windows.Forms.Label
$lblLog.Text = "Activity Log"
$lblLog.Location = New-Object System.Drawing.Point(2, 298)
$lblLog.AutoSize = $true
$lblLog.Anchor = "Top,Left"
$panelBody.Controls.Add($lblLog)

$logBox = New-Object System.Windows.Forms.RichTextBox
$logBox.Location = New-Object System.Drawing.Point(2, 318)
$logBox.Size = New-Object System.Drawing.Size(604, 128)
$logBox.Anchor = "Top,Bottom,Left,Right"
$logBox.Font = $fontMono
$logBox.ReadOnly = $true
$logBox.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)
$logBox.ForeColor = [System.Drawing.Color]::Gainsboro
$panelBody.Controls.Add($logBox)

# --- Progress + status ---
$progressBar = New-Object System.Windows.Forms.ProgressBar
$progressBar.Location = New-Object System.Drawing.Point(2, 452)
$progressBar.Size = New-Object System.Drawing.Size(604, 20)
$progressBar.Anchor = "Bottom,Left,Right"
$panelBody.Controls.Add($progressBar)

$lblStatus = New-Object System.Windows.Forms.Label
$lblStatus.Text = "Ready."
$lblStatus.Location = New-Object System.Drawing.Point(2, 476)
$lblStatus.Size = New-Object System.Drawing.Size(604, 18)
$lblStatus.Anchor = "Bottom,Left,Right"
$lblStatus.ForeColor = [System.Drawing.Color]::DimGray
$panelBody.Controls.Add($lblStatus)

# --- Action buttons ---
$btnMerge = New-Object System.Windows.Forms.Button
$btnMerge.Text = "Merge Folders"
$btnMerge.Location = New-Object System.Drawing.Point(2, 500)
$btnMerge.Size = New-Object System.Drawing.Size(150, 34)
$btnMerge.Anchor = "Bottom,Left"
$btnMerge.FlatStyle = "Flat"
$btnMerge.BackColor = $colorAccent
$btnMerge.ForeColor = [System.Drawing.Color]::White
$btnMerge.FlatAppearance.BorderSize = 0
$btnMerge.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 10)
$panelBody.Controls.Add($btnMerge)

$btnOpenDestination = New-Object System.Windows.Forms.Button
$btnOpenDestination.Text = "Open Destination"
$btnOpenDestination.Location = New-Object System.Drawing.Point(160, 500)
$btnOpenDestination.Size = New-Object System.Drawing.Size(150, 34)
$btnOpenDestination.Anchor = "Bottom,Left"
$btnOpenDestination.FlatStyle = "Flat"
$btnOpenDestination.Enabled = $false
$panelBody.Controls.Add($btnOpenDestination)

$linkCredit = New-Object System.Windows.Forms.LinkLabel
$linkCredit.Text = "Julibe - julibe.com"
$linkCredit.Location = New-Object System.Drawing.Point(480, 508)
$linkCredit.Size = New-Object System.Drawing.Size(126, 20)
$linkCredit.Anchor = "Bottom,Right"
$linkCredit.TextAlign = "MiddleRight"
$linkCredit.LinkColor = $colorAccentDark
$panelBody.Controls.Add($linkCredit)
$linkCredit.Add_LinkClicked({ Start-Process "https://julibe.com" })

# ---------------------------------------------------------------------------
# Behavior
# ---------------------------------------------------------------------------
$script:autoName = ""

function Write-Log {
    param([string]$text, [System.Drawing.Color]$color = [System.Drawing.Color]::Gainsboro)
    $logBox.SelectionStart = $logBox.TextLength
    $logBox.SelectionLength = 0
    $logBox.SelectionColor = $color
    $logBox.AppendText("$text`r`n")
    $logBox.ScrollToCaret()
    [System.Windows.Forms.Application]::DoEvents()
}

function Set-UiEnabled {
    param([bool]$enabled)
    foreach ($c in @($btnAddFolder, $btnRemoveFolder, $btnClearFolders, $txtName, $radRename, $radOverwrite, $radSkip, $btnMerge, $listFolders)) {
        $c.Enabled = $enabled
    }
}

function Add-FolderToList {
    param([string]$path)
    if (-not (Test-Path $path -PathType Container)) { return }
    $full = (Get-Item $path).FullName
    if ($listFolders.Items -contains $full) { return }
    $listFolders.Items.Add($full) | Out-Null
    if ($listFolders.Items.Count -eq 1 -or $txtName.Text -eq $script:autoName) {
        $script:autoName = (Get-Item $full).Name
        $txtName.Text = $script:autoName
    }
}

$btnAddFolder.Add_Click({
    $dlg = New-Object System.Windows.Forms.FolderBrowserDialog
    $dlg.Description = "Select a folder to add to the merge"
    if ($dlg.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        Add-FolderToList $dlg.SelectedPath
    }
})

$btnRemoveFolder.Add_Click({
    $sel = @($listFolders.SelectedItems)
    foreach ($item in $sel) { $listFolders.Items.Remove($item) }
})

$btnClearFolders.Add_Click({ $listFolders.Items.Clear() })

$form.Add_DragEnter({
    param($s, $e)
    if ($e.Data.GetDataPresent([System.Windows.Forms.DataFormats]::FileDrop)) {
        $e.Effect = [System.Windows.Forms.DragDropEffects]::Copy
    }
})
$form.Add_DragDrop({
    param($s, $e)
    $paths = $e.Data.GetData([System.Windows.Forms.DataFormats]::FileDrop)
    foreach ($p in $paths) { Add-FolderToList $p }
})

$btnOpenDestination.Add_Click({
    $dest = $btnOpenDestination.Tag
    if ($dest -and (Test-Path $dest)) { Start-Process explorer.exe $dest }
})

$btnMerge.Add_Click({
    if ($listFolders.Items.Count -lt 1) {
        [System.Windows.Forms.MessageBox]::Show("Add at least one folder to merge.", "Nothing to do", "OK", "Warning") | Out-Null
        return
    }

    $mergedName = Get-SanitizedName -name $txtName.Text.Trim()
    if ([string]::IsNullOrWhiteSpace($mergedName)) {
        [System.Windows.Forms.MessageBox]::Show("Please enter a valid destination folder name.", "Invalid Name", "OK", "Warning") | Out-Null
        return
    }

    $source_folders = @($listFolders.Items | ForEach-Object { $_.ToString() })
    $parent_dir = Split-Path $source_folders[0] -Parent
    $destination_path = Join-Path $parent_dir $mergedName

    $policy = if ($radOverwrite.Checked) { "O" } elseif ($radSkip.Checked) { "S" } else { "R" }

    Set-UiEnabled $false
    $btnOpenDestination.Enabled = $false
    $logBox.Clear()
    $progressBar.Value = 0
    $lblStatus.Text = "Preparing..."

    $moved_count = 0; $renamed_count = 0; $overwritten_count = 0
    $skipped_count = 0; $failed_count = 0; $recycled_count = 0; $kept_count = 0

    if (!(Test-Path $destination_path)) {
        New-Item -ItemType Directory -Path $destination_path | Out-Null
        Write-Log "Created destination: $destination_path" ([System.Drawing.Color]::LightSteelBlue)
    } else {
        Write-Log "Merging into existing folder: $destination_path" ([System.Drawing.Color]::LightSteelBlue)
    }
    $destination_path = (Get-Item $destination_path).FullName

    Write-Log "Scanning files..." ([System.Drawing.Color]::Gray)
    $totalFiles = 0
    foreach ($folder in $source_folders) {
        if ($folder -eq $destination_path -or !(Test-Path $folder)) { continue }
        $totalFiles += (Get-ChildItem -Path $folder -Recurse -File -Force -ErrorAction SilentlyContinue | Measure-Object).Count
    }
    $progressBar.Maximum = [Math]::Max(1, $totalFiles)
    $processed = 0

    foreach ($folder in $source_folders) {
        if ($folder -eq $destination_path) { continue }

        $folderWithSep = $folder.TrimEnd('\') + '\'
        if ($destination_path.StartsWith($folderWithSep, [System.StringComparison]::OrdinalIgnoreCase)) {
            Write-Log "Skipping: $folder (destination is nested inside this folder)" ([System.Drawing.Color]::Khaki)
            continue
        }
        if ($folder.StartsWith($destination_path.TrimEnd('\') + '\', [System.StringComparison]::OrdinalIgnoreCase)) {
            Write-Log "Skipping: $folder (this folder is nested inside the destination)" ([System.Drawing.Color]::Khaki)
            continue
        }
        if (!(Test-Path $folder)) {
            Write-Log "Skipping: $folder (no longer exists)" ([System.Drawing.Color]::Khaki)
            continue
        }

        Write-Log "Processing: $folder" ([System.Drawing.Color]::LightBlue)
        $files = Get-ChildItem -Path $folder -Recurse -File -Force -ErrorAction SilentlyContinue

        foreach ($file in $files) {
            $processed++
            $progressBar.Value = [Math]::Min($processed, $progressBar.Maximum)
            $lblStatus.Text = "Processing $processed of $totalFiles : $($file.Name)"

            try {
                $relativePath = $file.FullName.Substring($folder.Length)
                if ($relativePath.StartsWith("\")) { $relativePath = $relativePath.Substring(1) }
                $destFile = Join-Path $destination_path $relativePath
                $destDir = [System.IO.Path]::GetDirectoryName($destFile)
                if (!(Test-Path $destDir)) { New-Item -ItemType Directory -Path $destDir -Force | Out-Null }

                if (Test-Path $destFile) {
                    switch ($policy) {
                        "O" {
                            Move-Item -Path $file.FullName -Destination $destFile -Force -ErrorAction Stop
                            Write-Log "  Overwritten: $relativePath" ([System.Drawing.Color]::IndianRed)
                            $overwritten_count++; $moved_count++
                        }
                        "R" {
                            $newDest = Get-UniqueFileName $destFile
                            Move-Item -Path $file.FullName -Destination $newDest -ErrorAction Stop
                            Write-Log "  Renamed: $([System.IO.Path]::GetFileName($newDest))" ([System.Drawing.Color]::Goldenrod)
                            $renamed_count++; $moved_count++
                        }
                        "S" {
                            Write-Log "  Skipped (exists): $relativePath" ([System.Drawing.Color]::Gray)
                            $skipped_count++
                        }
                    }
                } else {
                    Move-Item -Path $file.FullName -Destination $destFile -ErrorAction Stop
                    $moved_count++
                }
            } catch {
                Write-Log "  FAILED: $($file.Name) - $($_.Exception.Message)" ([System.Drawing.Color]::Red)
                $failed_count++
            }
        }
    }

    Write-Log ""
    Write-Log "Checking for empty folders to recycle..." ([System.Drawing.Color]::Gray)
    foreach ($folder in $source_folders) {
        if ($folder -eq $destination_path -or !(Test-Path $folder)) { continue }
        $remaining_items = Get-ChildItem -Path $folder -Recurse -Force -ErrorAction SilentlyContinue
        if (@($remaining_items).Count -eq 0) {
            try {
                [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteDirectory($folder, 'OnlyErrorDialogs', 'SendToRecycleBin')
                Write-Log "Recycled empty folder: $([System.IO.Path]::GetFileName($folder))" ([System.Drawing.Color]::LightGreen)
                $recycled_count++
            } catch {
                Write-Log "Could not recycle: $folder" ([System.Drawing.Color]::Red)
                $failed_count++
            }
        } else {
            Write-Log "Kept (not empty): $([System.IO.Path]::GetFileName($folder))" ([System.Drawing.Color]::Gray)
            $kept_count++
        }
    }

    $progressBar.Value = $progressBar.Maximum
    $lblStatus.Text = "Done."
    Write-Log ""
    Write-Log "Merge complete." ([System.Drawing.Color]::White)
    Write-Log "  Moved: $moved_count (overwritten: $overwritten_count, renamed: $renamed_count)"
    Write-Log "  Skipped: $skipped_count   Failed: $failed_count"
    Write-Log "  Folders recycled: $recycled_count   Kept: $kept_count"

    $btnOpenDestination.Tag = $destination_path
    $btnOpenDestination.Enabled = $true
    Set-UiEnabled $true

    [System.Windows.Forms.MessageBox]::Show(
        "Moved: $moved_count`nSkipped: $skipped_count`nFailed: $failed_count`n`nFolders recycled: $recycled_count",
        "Merge Complete", "OK", "Information") | Out-Null
})

# Pre-fill from folders dropped onto the .bat icon at launch, if any.
foreach ($arg in $args) { Add-FolderToList $arg }

[System.Windows.Forms.Application]::Run($form)
