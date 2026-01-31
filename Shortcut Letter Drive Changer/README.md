# 🚀 Julibe's Shortcut Drive Changer

> **The simplest "Drag-and-Drop" utility for batch-updating Windows shortcuts leter PATHS.**

![Version](https://img.shields.io/badge/version-2026-brightgreen) ![Platform](https://img.shields.io/badge/platform-Windows-0078D6) ![Author](https://img.shields.io/badge/author-Julibe-orange)
---

## 📝 Usage Instructions
1.  Download `Shortcut Letter Drive Changer.bat`.
2.  **Select** the shortcuts or folders you want to fix in File Explorer.
3.  **Drag and Drop** them directly onto the `Shortcut Letter Drive Changer.bat` icon.
4.  A console window will open.
5.  Type the **New Drive Letter** (e.g., `G`) and press **Enter**.
6.  Watch the magic happen.
7.  Done!
---

## 📖 What This Does
**Julibe's Shortcut Drive Changer** is a hybrid Batch + PowerShell utility designed to solve a specific, frustrating Windows headache: **Broken Shortcuts.**

When you move files from one drive to another (e.g., migrating games from `C:` to `D:`), every shortcut pointing to those files breaks immediately. This tool allows you to:

1.  **Drag and drop** individual shortcuts (`.lnk`) or entire folders containing shortcuts onto the script file.
2.  **Enter a new drive letter** (e.g., `E`).
3.  Automatically **update the Target Path, Working Directory, and Icon Location** for every shortcut instantly.

---

## 💎 Why You Need This
**Stop fixing shortcuts manually.**

Imagine you just upgraded your PC. You bought a massive new 400TB SSD and moved your entire Game or Project library from Drive `C:` to Drive `D:`. You click your favorite application, and... **Error.** *Windows cannot find the file.*

Now imagine doing that for **5000 shortcuts**.

**Julibe's Shortcut Drive Changer** is the magic tool that fixes this nightmare. It turns hours of tedious right-clicking, selecting "Properties," and typing new paths into a **5-second drag-and-drop operation**.

It is the essential tool for:
*   **Power Users** optimizing their storage.
*   **IT Admins** deploying drive mapping changes.
*   **Digital Hoarders** organizing massive file collections.

---

## 🐞 Known Bugs & Limitations
1.  **UNC Paths:** This tool is strictly designed for **Drive Letters** (e.g., `C:\Folder`). It may not function correctly if the source path is a network share starting with `\\ServerName\`.
2.  **Web Shortcuts:** It specifically targets `.lnk` files. It does not update `.url` (Internet Shortcuts).
3.  **Admin Rights:** If you are trying to update shortcuts located in protected system folders (like `C:\Program Files` or the Start Menu), you may need to run the script as **Administrator**.
4.  **Temp File:** The script creates a temporary `.ps1` file in your `%temp%` folder during execution. It attempts to delete it automatically, but a hard crash might leave a harmless residue file.

---

## 👨‍💻 Credits
*   **Created By:** Julibe
*   **Website:** [https://julibe.com](https://julibe.com)
*   **Copyright:** 2026
*   **Mission:** Crafting Amazing Digital Experiences.

---
*Disclaimer: This tool modifies files. While it includes safety checks, always backup your data before running batch operations on critical system files.*