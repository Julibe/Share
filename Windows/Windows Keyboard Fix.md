# **Change Windows Keyboard Layout**

## **Method 1: Registry Editor**

1. Press `Win + R`, type `regedit`, and press Enter.
2. Navigate to the following registry paths:
   - `HKEY_USERS\.DEFAULT\Keyboard Layout\Preload`
   - `HKEY_CURRENT_USER\Keyboard Layout\Preload`
3. Set the string value named `1` to your preferred keyboard layout:

   \| Keyboard layout | Registry value |\
   \|---|---|\
   \| Latin American Spanish | `0000080a` |\
   \| English (United States) | `00000409` |
4. Restart your computer to apply the changes.

## **Method 2: PowerShell (Automatic)**

Open **PowerShell as Administrator** and execute the following script to configure English (US) as the preferred user language while using the Latin American keyboard layout exclusively, including on the Windows login screen.

```
# Keyboard layout configuration
$Language = "en-US"
$Keyboard = "0000080a"

# 1. Configure Windows user language and keyboard
$LangList = New-WinUserLanguageList $Language
$LangList[0].InputMethodTips.Clear()
$LangList[0].InputMethodTips.Add("0409:$Keyboard")
Set-WinUserLanguageList $LangList -Force

# 2. Configure Current User and System Default
$RegistryPaths = @(
    "HKCU:\Keyboard Layout\Preload",
    "Registry::HKEY_USERS\.DEFAULT\Keyboard Layout\Preload"
)

foreach ($Path in $RegistryPaths) {
    Remove-Item -Path $Path -Recurse -Force -ErrorAction SilentlyContinue
    New-Item -Path $Path -Force | Out-Null

    New-ItemProperty `
        -Path $Path `
        -Name "1" `
        -Value $Keyboard `
        -PropertyType String `
        -Force | Out-Null
}

Write-Host "Keyboard layout successfully configured." -ForegroundColor Green
Write-Host "Restart Windows to apply all changes."
```

## **Available keyboard layouts**

To switch layouts, modify the `$Keyboard` variable:

- **Latin American Spanish:** `"0000080a"`
- **English (United States):** `"00000409"`

**Note:** This script replaces existing keyboard layouts and the current user's preferred language list. It does not uninstall Windows language packs. Back up your registry settings before executing it.
