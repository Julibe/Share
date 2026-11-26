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
# 1. Force Windows language list to English (US) + Latin American keyboard ONLY
$LangList = New-WinUserLanguageList "en-US"
$LangList[0].InputMethodTips.Clear()
$LangList[0].InputMethodTips.Add("0409:0000080a")
Set-WinUserLanguageList $LangList -Force

# 2. Clear and set Current User Preload to Latin American (0000080a)
Remove-Item -Path "HKCU:\Keyboard Layout\Preload" -Recurse -Force -ErrorAction SilentlyContinue
New-Item -Path "HKCU:\Keyboard Layout\Preload" -Force | Out-Null
New-ItemProperty -Path "HKCU:\Keyboard Layout\Preload" -Name "1" -Value "0000080a" -PropertyType String -Force | Out-Null

# 3. Clear and set System Default (Login Screen) Preload to Latin American (0000080a)
Remove-Item -Path "Registry::HKEY_USERS\.DEFAULT\Keyboard Layout\Preload" -Recurse -Force -ErrorAction SilentlyContinue
New-Item -Path "Registry::HKEY_USERS\.DEFAULT\Keyboard Layout\Preload" -Force | Out-Null
New-ItemProperty -Path "Registry::HKEY_USERS\.DEFAULT\Keyboard Layout\Preload" -Name "1" -Value "0000080a" -PropertyType String -Force | Out-Null

```

## **Available keyboard layouts**

To switch layouts, modify the `$Keyboard` variable:

- **Latin American Spanish:** `"0000080a"`
- **English (United States):** `"00000409"`

**Note:** This script replaces existing keyboard layouts and the current user's preferred language list. It does not uninstall Windows language packs. Back up your registry settings before executing it.
