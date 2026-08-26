<# :
@echo off
setlocal
cd /d "%~dp0"
title Julibe's Item Organizer - GUI

:: 1. PREPARE HYBRID EXECUTION (extract the PowerShell half of this file to %temp%)
for /f "usebackq delims=" %%G in (`powershell -NoProfile -Command "[guid]::NewGuid().ToString()"`) do set "PS_GUID=%%G"
set "PS_FILE=%temp%\%~n0_%PS_GUID%_organizergui.ps1"
copy /y "%~f0" "%PS_FILE%" >nul

:: 2. EXECUTE (STA apartment is required for Windows Forms)
powershell -NoProfile -STA -ExecutionPolicy Bypass -File "%PS_FILE%" %*

:: 3. CLEANUP
del "%PS_FILE%" >nul 2>&1
exit /b
#>

# ============================================================================
# Julibe's Item Organizer - GUI Edition
# ----------------------------------------------------------------------------
# Author:  Julibe - Crafting Digital Experiences
# Year:    2026
# Website: https://julibe.com
# Email:   mail@julibe.com
# ----------------------------------------------------------------------------
# A drag-and-drop Windows Forms front end for the same grouping/organizing
# engine used by "Folder Organizer.bat". This file is fully independent from
# the console version - it does not modify or depend on it in any way.
# ============================================================================

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

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
            "Julibe's Item Organizer - Fatal Error",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error) | Out-Null
    } catch {}
    exit
}

# ---------------------------------------------------------------------------
# Palette (matches the blue theme of the console version)
# ---------------------------------------------------------------------------
$colorAccent     = [System.Drawing.Color]::FromArgb(30, 136, 229)
$colorAccentDark = [System.Drawing.Color]::FromArgb(21, 101, 192)
$colorBg         = [System.Drawing.Color]::FromArgb(246, 248, 250)
$fontUi          = New-Object System.Drawing.Font("Segoe UI", 9.5)
$fontHeader      = New-Object System.Drawing.Font("Segoe UI Semibold", 15)
$fontMono        = New-Object System.Drawing.Font("Consolas", 9)

# ---------------------------------------------------------------------------
# Shared logic (identical behavior to the console version's helper functions)
# ---------------------------------------------------------------------------
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
        if ($isFolder) { $newPath = Join-Path $directory "$filename ($counter)" }
        else { $newPath = Join-Path $directory "$filename ($counter)$extension" }
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

function Get-SuggestedName {
    param([string]$path)
    $item = Get-Item $path
    $base = if ($item.PSIsContainer) { $item.Name } else { $item.BaseName }
    $base = $base -replace '[^\p{L}\p{Nd}]+', ' '
    $base = (Get-Culture).TextInfo.ToTitleCase($base.ToLower())
    return $base.Trim()
}

# ---------------------------------------------------------------------------
# Form
# ---------------------------------------------------------------------------
$form = New-Object System.Windows.Forms.Form
$form.Text = "Julibe's Item Organizer"
$form.StartPosition = "CenterScreen"
$form.ClientSize = New-Object System.Drawing.Size(640, 560)
$form.MinimumSize = New-Object System.Drawing.Size(560, 460)
$form.BackColor = $colorBg
$form.Font = $fontUi
$form.AllowDrop = $true

$panelHeader = New-Object System.Windows.Forms.Panel
$panelHeader.Dock = "Top"
$panelHeader.Height = 64
$panelHeader.BackColor = $colorAccent
$form.Controls.Add($panelHeader)

$lblTitle = New-Object System.Windows.Forms.Label
$lblTitle.Text = "Item Organizer"
$lblTitle.Font = $fontHeader
$lblTitle.ForeColor = [System.Drawing.Color]::White
$lblTitle.AutoSize = $true
$lblTitle.Location = New-Object System.Drawing.Point(18, 10)
$panelHeader.Controls.Add($lblTitle)

$lblSubtitle = New-Object System.Windows.Forms.Label
$lblSubtitle.Text = "Drag files & folders in and group them into one clean, named folder."
$lblSubtitle.ForeColor = [System.Drawing.Color]::FromArgb(224, 240, 255)
$lblSubtitle.AutoSize = $true
$lblSubtitle.Location = New-Object System.Drawing.Point(19, 38)
$panelHeader.Controls.Add($lblSubtitle)

$panelBody = New-Object System.Windows.Forms.Panel
$panelBody.Dock = "Fill"
$panelBody.Padding = New-Object System.Windows.Forms.Padding(16, 12, 16, 12)
$form.Controls.Add($panelBody)
$panelBody.BringToFront()

$grpItems = New-Object System.Windows.Forms.GroupBox
$grpItems.Text = "Items to Organize (drag & drop here)"
$grpItems.Location = New-Object System.Drawing.Point(0, 0)
$grpItems.Size = New-Object System.Drawing.Size(608, 160)
$grpItems.Anchor = "Top,Left,Right"
$panelBody.Controls.Add($grpItems)

$listItems = New-Object System.Windows.Forms.ListBox
$listItems.Location = New-Object System.Drawing.Point(12, 24)
$listItems.Size = New-Object System.Drawing.Size(470, 122)
$listItems.Anchor = "Top,Bottom,Left,Right"
$listItems.HorizontalScrollbar = $true
$grpItems.Controls.Add($listItems)

$btnAddItems = New-Object System.Windows.Forms.Button
$btnAddItems.Text = "Add Files..."
$btnAddItems.Location = New-Object System.Drawing.Point(492, 24)
$btnAddItems.Size = New-Object System.Drawing.Size(104, 30)
$btnAddItems.Anchor = "Top,Right"
$btnAddItems.FlatStyle = "Flat"
$grpItems.Controls.Add($btnAddItems)

$btnAddFolder = New-Object System.Windows.Forms.Button
$btnAddFolder.Text = "Add Folder..."
$btnAddFolder.Location = New-Object System.Drawing.Point(492, 60)
$btnAddFolder.Size = New-Object System.Drawing.Size(104, 30)
$btnAddFolder.Anchor = "Top,Right"
$btnAddFolder.FlatStyle = "Flat"
$grpItems.Controls.Add($btnAddFolder)

$btnRemoveItem = New-Object System.Windows.Forms.Button
$btnRemoveItem.Text = "Remove"
$btnRemoveItem.Location = New-Object System.Drawing.Point(492, 96)
$btnRemoveItem.Size = New-Object System.Drawing.Size(104, 30)
$btnRemoveItem.Anchor = "Top,Right"
$btnRemoveItem.FlatStyle = "Flat"
$grpItems.Controls.Add($btnRemoveItem)

$lblName = New-Object System.Windows.Forms.Label
$lblName.Text = "Destination folder name:"
$lblName.Location = New-Object System.Drawing.Point(2, 172)
$lblName.AutoSize = $true
$panelBody.Controls.Add($lblName)

$txtName = New-Object System.Windows.Forms.TextBox
$txtName.Location = New-Object System.Drawing.Point(2, 194)
$txtName.Size = New-Object System.Drawing.Size(604, 26)
$txtName.Anchor = "Top,Left,Right"
$txtName.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$panelBody.Controls.Add($txtName)

$grpConflict = New-Object System.Windows.Forms.GroupBox
$grpConflict.Text = "When an item already exists at the destination"
$grpConflict.Location = New-Object System.Drawing.Point(0, 232)
$grpConflict.Size = New-Object System.Drawing.Size(608, 56)
$grpConflict.Anchor = "Top,Left,Right"
$panelBody.Controls.Add($grpConflict)

$radRename = New-Object System.Windows.Forms.RadioButton
$radRename.Text = "Rename (keep both)"
$radRename.Location = New-Object System.Drawing.Point(12, 24)
$radRename.AutoSize = $true
$radRename.Checked = $true
$grpConflict.Controls.Add($radRename)

$radOverwrite = New-Object System.Windows.Forms.RadioButton
$radOverwrite.Text = "Overwrite"
$radOverwrite.Location = New-Object System.Drawing.Point(230, 24)
$radOverwrite.AutoSize = $true
$grpConflict.Controls.Add($radOverwrite)

$radSkip = New-Object System.Windows.Forms.RadioButton
$radSkip.Text = "Skip"
$radSkip.Location = New-Object System.Drawing.Point(350, 24)
$radSkip.AutoSize = $true
$grpConflict.Controls.Add($radSkip)

$lblLog = New-Object System.Windows.Forms.Label
$lblLog.Text = "Activity Log"
$lblLog.Location = New-Object System.Drawing.Point(2, 298)
$lblLog.AutoSize = $true
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

$btnOrganize = New-Object System.Windows.Forms.Button
$btnOrganize.Text = "Organize"
$btnOrganize.Location = New-Object System.Drawing.Point(2, 500)
$btnOrganize.Size = New-Object System.Drawing.Size(150, 34)
$btnOrganize.Anchor = "Bottom,Left"
$btnOrganize.FlatStyle = "Flat"
$btnOrganize.BackColor = $colorAccent
$btnOrganize.ForeColor = [System.Drawing.Color]::White
$btnOrganize.FlatAppearance.BorderSize = 0
$btnOrganize.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 10)
$panelBody.Controls.Add($btnOrganize)

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
    foreach ($c in @($btnAddItems, $btnAddFolder, $btnRemoveItem, $txtName, $radRename, $radOverwrite, $radSkip, $btnOrganize, $listItems)) {
        $c.Enabled = $enabled
    }
}

function Add-ItemToList {
    param([string]$path)
    if (-not (Test-Path $path)) { return }
    $full = (Get-Item $path).FullName
    if ($listItems.Items -contains $full) { return }
    $listItems.Items.Add($full) | Out-Null
    if ($listItems.Items.Count -eq 1 -or $txtName.Text -eq $script:autoName) {
        $script:autoName = Get-SuggestedName $full
        $txtName.Text = $script:autoName
    }
}

$btnAddItems.Add_Click({
    $dlg = New-Object System.Windows.Forms.OpenFileDialog
    $dlg.Multiselect = $true
    $dlg.Title = "Select files to organize"
    if ($dlg.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        foreach ($f in $dlg.FileNames) { Add-ItemToList $f }
    }
})

$btnAddFolder.Add_Click({
    $dlg = New-Object System.Windows.Forms.FolderBrowserDialog
    $dlg.Description = "Select a folder to organize"
    if ($dlg.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        Add-ItemToList $dlg.SelectedPath
    }
})

$btnRemoveItem.Add_Click({
    $sel = @($listItems.SelectedItems)
    foreach ($item in $sel) { $listItems.Items.Remove($item) }
})

$form.Add_DragEnter({
    param($s, $e)
    if ($e.Data.GetDataPresent([System.Windows.Forms.DataFormats]::FileDrop)) {
        $e.Effect = [System.Windows.Forms.DragDropEffects]::Copy
    }
})
$form.Add_DragDrop({
    param($s, $e)
    $paths = $e.Data.GetData([System.Windows.Forms.DataFormats]::FileDrop)
    foreach ($p in $paths) { Add-ItemToList $p }
})

$btnOpenDestination.Add_Click({
    $dest = $btnOpenDestination.Tag
    if ($dest -and (Test-Path $dest)) { Start-Process explorer.exe $dest }
})

$btnOrganize.Add_Click({
    if ($listItems.Items.Count -lt 1) {
        [System.Windows.Forms.MessageBox]::Show("Add at least one file or folder to organize.", "Nothing to do", "OK", "Warning") | Out-Null
        return
    }

    $target_folder_name = Get-SanitizedName -name $txtName.Text.Trim()
    if ([string]::IsNullOrWhiteSpace($target_folder_name)) {
        [System.Windows.Forms.MessageBox]::Show("Please enter a valid destination folder name.", "Invalid Name", "OK", "Warning") | Out-Null
        return
    }

    $dropped_items = @($listItems.Items | ForEach-Object { $_.ToString() })
    $parent_dir = Split-Path $dropped_items[0] -Parent
    $destination_path = Join-Path $parent_dir $target_folder_name

    $policy = if ($radOverwrite.Checked) { "O" } elseif ($radSkip.Checked) { "S" } else { "R" }

    Set-UiEnabled $false
    $btnOpenDestination.Enabled = $false
    $logBox.Clear()
    $progressBar.Value = 0
    $progressBar.Maximum = [Math]::Max(1, $dropped_items.Count)
    $lblStatus.Text = "Preparing..."

    $moved_count = 0; $skipped_count = 0; $failed_count = 0
    $renamed_count = 0; $overwritten_count = 0

    if (!(Test-Path $destination_path)) {
        New-Item -ItemType Directory -Path $destination_path | Out-Null
        Write-Log "Created destination: $destination_path" ([System.Drawing.Color]::LightSteelBlue)
    } else {
        Write-Log "Moving into existing folder: $destination_path" ([System.Drawing.Color]::LightSteelBlue)
    }

    $processed = 0
    foreach ($itemPath in $dropped_items) {
        $processed++
        $progressBar.Value = [Math]::Min($processed, $progressBar.Maximum)

        if ($itemPath -eq $destination_path) { continue }
        if (!(Test-Path $itemPath)) {
            Write-Log "Skipping: $itemPath (no longer exists)" ([System.Drawing.Color]::Khaki)
            $skipped_count++
            continue
        }

        $item = Get-Item $itemPath
        $lblStatus.Text = "Processing $processed of $($dropped_items.Count): $($item.Name)"

        if ($item.PSIsContainer) {
            $itemFullWithSep = $item.FullName.TrimEnd('\') + '\'
            if ($destination_path.StartsWith($itemFullWithSep, [System.StringComparison]::OrdinalIgnoreCase)) {
                Write-Log "Skipping: $($item.Name) (destination is nested inside this folder)" ([System.Drawing.Color]::Khaki)
                $skipped_count++
                continue
            }
        }

        Write-Log "Processing: $($item.Name)" ([System.Drawing.Color]::LightBlue)
        $destItem = Join-Path $destination_path $item.Name

        try {
            if (Test-Path $destItem) {
                switch ($policy) {
                    "O" {
                        Move-Item -Path $item.FullName -Destination $destItem -Force -ErrorAction Stop
                        Write-Log "  Overwritten" ([System.Drawing.Color]::IndianRed)
                        $overwritten_count++; $moved_count++
                    }
                    "R" {
                        $newDest = Get-UniqueFileName $destItem
                        Move-Item -Path $item.FullName -Destination $newDest -ErrorAction Stop
                        Write-Log "  Renamed: $([System.IO.Path]::GetFileName($newDest))" ([System.Drawing.Color]::Goldenrod)
                        $renamed_count++; $moved_count++
                    }
                    "S" {
                        Write-Log "  Skipped (exists)" ([System.Drawing.Color]::Gray)
                        $skipped_count++
                    }
                }
            } else {
                Move-Item -Path $item.FullName -Destination $destItem -ErrorAction Stop
                Write-Log "  Done" ([System.Drawing.Color]::Gainsboro)
                $moved_count++
            }
        } catch {
            Write-Log "  FAILED: $($_.Exception.Message)" ([System.Drawing.Color]::Red)
            $failed_count++
        }
    }

    $progressBar.Value = $progressBar.Maximum
    $lblStatus.Text = "Done."
    Write-Log ""
    Write-Log "Organize complete." ([System.Drawing.Color]::White)
    Write-Log "  Moved: $moved_count (overwritten: $overwritten_count, renamed: $renamed_count)"
    Write-Log "  Skipped: $skipped_count   Failed: $failed_count"

    $btnOpenDestination.Tag = $destination_path
    $btnOpenDestination.Enabled = $true
    Set-UiEnabled $true

    [System.Windows.Forms.MessageBox]::Show(
        "Moved: $moved_count`nSkipped: $skipped_count`nFailed: $failed_count",
        "Organize Complete", "OK", "Information") | Out-Null
})

foreach ($arg in $args) { Add-ItemToList $arg }

[System.Windows.Forms.Application]::Run($form)
