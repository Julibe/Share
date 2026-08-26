<# :
@echo off
setlocal
cd /d "%~dp0"
title Julibe's Shortcut Drive Changer - GUI

:: 1. PREPARE HYBRID EXECUTION (extract the PowerShell half of this file to %temp%)
for /f "usebackq delims=" %%G in (`powershell -NoProfile -Command "[guid]::NewGuid().ToString()"`) do set "PS_GUID=%%G"
set "PS_FILE=%temp%\%~n0_%PS_GUID%_drivegui.ps1"
copy /y "%~f0" "%PS_FILE%" >nul

:: 2. EXECUTE (STA apartment is required for Windows Forms)
powershell -NoProfile -STA -ExecutionPolicy Bypass -File "%PS_FILE%" %*

:: 3. CLEANUP
del "%PS_FILE%" >nul 2>&1
exit /b
#>

# ============================================================================
# Julibe's Shortcut Drive Changer - GUI Edition
# ----------------------------------------------------------------------------
# Author:  Julibe - Crafting Digital Experiences
# Year:    2026
# Website: https://julibe.com
# Email:   mail@julibe.com
# ----------------------------------------------------------------------------
# A drag-and-drop Windows Forms front end for the same shortcut-retargeting
# engine used by "Shortcut Letter Drive Changer.bat". This file is fully
# independent from the console version - it does not modify or depend on it
# in any way.
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
            "Julibe's Shortcut Drive Changer - Fatal Error",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error) | Out-Null
    } catch {}
    exit
}

# ---------------------------------------------------------------------------
# Palette (matches the dark-green theme of the console version)
# ---------------------------------------------------------------------------
$colorAccent     = [System.Drawing.Color]::FromArgb(46, 125, 50)
$colorAccentDark = [System.Drawing.Color]::FromArgb(27, 94, 32)
$colorBg         = [System.Drawing.Color]::FromArgb(246, 248, 246)
$fontUi          = New-Object System.Drawing.Font("Segoe UI", 9.5)
$fontHeader      = New-Object System.Drawing.Font("Segoe UI Semibold", 15)
$fontMono        = New-Object System.Drawing.Font("Consolas", 9)

$shell_object = New-Object -ComObject WScript.Shell

# ---------------------------------------------------------------------------
# Form
# ---------------------------------------------------------------------------
$form = New-Object System.Windows.Forms.Form
$form.Text = "Julibe's Shortcut Drive Changer"
$form.StartPosition = "CenterScreen"
$form.ClientSize = New-Object System.Drawing.Size(640, 580)
$form.MinimumSize = New-Object System.Drawing.Size(560, 480)
$form.BackColor = $colorBg
$form.Font = $fontUi
$form.AllowDrop = $true

$panelHeader = New-Object System.Windows.Forms.Panel
$panelHeader.Dock = "Top"
$panelHeader.Height = 64
$panelHeader.BackColor = $colorAccent
$form.Controls.Add($panelHeader)

$lblTitle = New-Object System.Windows.Forms.Label
$lblTitle.Text = "Shortcut Drive Changer"
$lblTitle.Font = $fontHeader
$lblTitle.ForeColor = [System.Drawing.Color]::White
$lblTitle.AutoSize = $true
$lblTitle.Location = New-Object System.Drawing.Point(18, 10)
$panelHeader.Controls.Add($lblTitle)

$lblSubtitle = New-Object System.Windows.Forms.Label
$lblSubtitle.Text = "Repoint .lnk shortcuts to a new drive letter after moving your files."
$lblSubtitle.ForeColor = [System.Drawing.Color]::FromArgb(220, 245, 220)
$lblSubtitle.AutoSize = $true
$lblSubtitle.Location = New-Object System.Drawing.Point(19, 38)
$panelHeader.Controls.Add($lblSubtitle)

$panelBody = New-Object System.Windows.Forms.Panel
$panelBody.Dock = "Fill"
$panelBody.Padding = New-Object System.Windows.Forms.Padding(16, 12, 16, 12)
$form.Controls.Add($panelBody)
$panelBody.BringToFront()

$grpItems = New-Object System.Windows.Forms.GroupBox
$grpItems.Text = "Shortcuts / Folders to Scan (drag & drop here)"
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

$btnAddShortcuts = New-Object System.Windows.Forms.Button
$btnAddShortcuts.Text = "Add .lnk..."
$btnAddShortcuts.Location = New-Object System.Drawing.Point(492, 24)
$btnAddShortcuts.Size = New-Object System.Drawing.Size(104, 30)
$btnAddShortcuts.Anchor = "Top,Right"
$btnAddShortcuts.FlatStyle = "Flat"
$grpItems.Controls.Add($btnAddShortcuts)

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

$lblDrive = New-Object System.Windows.Forms.Label
$lblDrive.Text = "New drive letter:"
$lblDrive.Location = New-Object System.Drawing.Point(2, 172)
$lblDrive.AutoSize = $true
$panelBody.Controls.Add($lblDrive)

$comboDrive = New-Object System.Windows.Forms.ComboBox
$comboDrive.Location = New-Object System.Drawing.Point(2, 194)
$comboDrive.Size = New-Object System.Drawing.Size(80, 26)
$comboDrive.DropDownStyle = "DropDownList"
[void]$comboDrive.Items.AddRange(([char[]](65..90) | ForEach-Object { "$_ :" }))
$panelBody.Controls.Add($comboDrive)

$chkBackup = New-Object System.Windows.Forms.CheckBox
$chkBackup.Text = "Create a .bak backup of each shortcut before saving"
$chkBackup.Location = New-Object System.Drawing.Point(96, 198)
$chkBackup.AutoSize = $true
$chkBackup.Checked = $true
$panelBody.Controls.Add($chkBackup)

$lblLog = New-Object System.Windows.Forms.Label
$lblLog.Text = "Activity Log"
$lblLog.Location = New-Object System.Drawing.Point(2, 236)
$lblLog.AutoSize = $true
$panelBody.Controls.Add($lblLog)

$logBox = New-Object System.Windows.Forms.RichTextBox
$logBox.Location = New-Object System.Drawing.Point(2, 256)
$logBox.Size = New-Object System.Drawing.Size(604, 190)
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

$btnUpdate = New-Object System.Windows.Forms.Button
$btnUpdate.Text = "Update Shortcuts"
$btnUpdate.Location = New-Object System.Drawing.Point(2, 500)
$btnUpdate.Size = New-Object System.Drawing.Size(150, 34)
$btnUpdate.Anchor = "Bottom,Left"
$btnUpdate.FlatStyle = "Flat"
$btnUpdate.BackColor = $colorAccent
$btnUpdate.ForeColor = [System.Drawing.Color]::White
$btnUpdate.FlatAppearance.BorderSize = 0
$btnUpdate.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 10)
$panelBody.Controls.Add($btnUpdate)

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
    foreach ($c in @($btnAddShortcuts, $btnAddFolder, $btnRemoveItem, $comboDrive, $chkBackup, $btnUpdate, $listItems)) {
        $c.Enabled = $enabled
    }
}

function Add-ItemToList {
    param([string]$path)
    if (-not (Test-Path $path)) { return }
    $item = Get-Item $path
    if (-not $item.PSIsContainer -and $item.Extension -ne ".lnk") { return }
    $full = $item.FullName
    if ($listItems.Items -contains $full) { return }
    $listItems.Items.Add($full) | Out-Null
}

function Update-Shortcut {
    param($file_path, $new_drive, [bool]$makeBackup)
    try {
        $shortcut = $shell_object.CreateShortcut($file_path)
        $old_target = $shortcut.TargetPath
        $old_work = $shortcut.WorkingDirectory
        $old_icon = $shortcut.IconLocation

        $shortcut.TargetPath = $old_target -replace '^[A-Za-z]:', $new_drive
        $shortcut.WorkingDirectory = $old_work -replace '^[A-Za-z]:', $new_drive
        if ($old_icon -match '^[A-Za-z]:') {
            $shortcut.IconLocation = $old_icon -replace '^[A-Za-z]:', $new_drive
        }

        if ($makeBackup) {
            try {
                Copy-Item -Path $file_path -Destination "$file_path.bak" -Force -ErrorAction Stop
            } catch {
                Write-Log "  Warning: could not back up $([System.IO.Path]::GetFileName($file_path)): $($_.Exception.Message)" ([System.Drawing.Color]::Khaki)
            }
        }

        $shortcut.Save()
        Write-Log "  Updated -> $new_drive : $([System.IO.Path]::GetFileName($file_path))" ([System.Drawing.Color]::LightGreen)
        return $true
    } catch {
        Write-Log "  FAILED: $([System.IO.Path]::GetFileName($file_path)) - $($_.Exception.Message)" ([System.Drawing.Color]::Red)
        return $false
    }
}

$btnAddShortcuts.Add_Click({
    $dlg = New-Object System.Windows.Forms.OpenFileDialog
    $dlg.Filter = "Shortcut files (*.lnk)|*.lnk"
    $dlg.Multiselect = $true
    $dlg.Title = "Select shortcuts to retarget"
    if ($dlg.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        foreach ($f in $dlg.FileNames) { Add-ItemToList $f }
    }
})

$btnAddFolder.Add_Click({
    $dlg = New-Object System.Windows.Forms.FolderBrowserDialog
    $dlg.Description = "Select a folder to scan recursively for .lnk shortcuts"
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

$btnUpdate.Add_Click({
    if ($listItems.Items.Count -lt 1) {
        [System.Windows.Forms.MessageBox]::Show("Add at least one shortcut or folder to scan.", "Nothing to do", "OK", "Warning") | Out-Null
        return
    }
    if ($comboDrive.SelectedIndex -lt 0) {
        [System.Windows.Forms.MessageBox]::Show("Please choose a target drive letter.", "No Drive Selected", "OK", "Warning") | Out-Null
        return
    }

    $target_drive = ($comboDrive.SelectedItem -replace '\s', '')
    $makeBackup = $chkBackup.Checked

    Set-UiEnabled $false
    $logBox.Clear()
    $progressBar.Value = 0
    $lblStatus.Text = "Scanning for shortcuts..."

    $updated_count = 0; $failed_count = 0; $skipped_count = 0

    $targets = @()
    foreach ($path in @($listItems.Items | ForEach-Object { $_.ToString() })) {
        if (Test-Path $path -PathType Container) {
            Write-Log "Scanning folder: $path" ([System.Drawing.Color]::LightBlue)
            try {
                $targets += Get-ChildItem -Path $path -Filter *.lnk -Recurse -ErrorAction Stop
            } catch {
                Write-Log "  Could not scan folder: $($_.Exception.Message)" ([System.Drawing.Color]::Red)
                $failed_count++
            }
        } elseif ($path -like "*.lnk") {
            $targets += Get-Item $path
        } else {
            Write-Log "Skipping (not a shortcut): $path" ([System.Drawing.Color]::Khaki)
            $skipped_count++
        }
    }

    if ($targets.Count -eq 0) {
        Write-Log "No .lnk shortcuts found." ([System.Drawing.Color]::Khaki)
    }

    $progressBar.Maximum = [Math]::Max(1, $targets.Count)
    $processed = 0

    foreach ($t in $targets) {
        $processed++
        $progressBar.Value = [Math]::Min($processed, $progressBar.Maximum)
        $lblStatus.Text = "Updating $processed of $($targets.Count): $($t.Name)"

        if (Update-Shortcut -file_path $t.FullName -new_drive $target_drive -makeBackup $makeBackup) {
            $updated_count++
        } else {
            $failed_count++
        }
    }

    $progressBar.Value = $progressBar.Maximum
    $lblStatus.Text = "Done."
    Write-Log ""
    Write-Log "Update complete." ([System.Drawing.Color]::White)
    Write-Log "  Updated: $updated_count   Failed: $failed_count   Skipped: $skipped_count"

    Set-UiEnabled $true

    [System.Windows.Forms.MessageBox]::Show(
        "Updated: $updated_count`nFailed: $failed_count`nSkipped: $skipped_count",
        "Update Complete", "OK", "Information") | Out-Null
})

foreach ($arg in $args) { Add-ItemToList $arg }

[System.Windows.Forms.Application]::Run($form)
