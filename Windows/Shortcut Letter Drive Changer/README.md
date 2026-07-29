# Julibe's Item Organizer

> **The simplest "Drag-and-Drop" utility for instantly grouping, naming, and
> organizing files and folders.**

## ![Version](https://img.shields.io/badge/version-2026-brightgreen) ![Platform](https://img.shields.io/badge/platform-Windows-0078D6) ![Author](https://img.shields.io/badge/author-Julibe-orange)

## Usage Instructions

1.  Download `Julibe_Organizer.bat`.
2.  **Select** the files and/or folders you want to group together in File
    Explorer.
3.  **Drag and Drop** them directly onto the `Julibe_Organizer.bat` icon.
    - _(Alternatively, double-click the script to manually paste a folder
      path)._
4.  A pop-up window will appear suggesting a beautifully cleaned-up folder name
    based on the first item you dropped.
5.  **Edit or confirm** the new folder name and press **OK**.
6.  A console window handles the rest, safely moving all items into your new
    folder.
7.  Done!

---

## What This Does

**Julibe's Item Organizer** is a hybrid Batch + PowerShell utility designed to
solve a very common desktop and download-folder headache: **Scattered Files.**

When you drag and drop a chaotic mix of files and folders onto this tool, it
automatically:

1.  **Smart-Names:** Reads the name of the first dropped item, strips away ugly
    punctuation (like `.`, `_`, `-`), and formats it into clean **Title Case**
    (e.g., `my_project.v2.final` becomes `My Project V2 Final`).
2.  **Prompts You:** Opens a visual input box letting you approve or tweak the
    generated name.
3.  **Creates & Moves:** Creates the new master folder and instantly moves all
    dropped items inside it.
4.  **Handles Conflicts:** If a file with the same name already exists in the
    destination, it elegantly pauses to ask if you want to **Overwrite, Rename,
    or Skip** (with "Apply to All" options for massive batches).

---

## Why You Need This

**Stop creating new folders, naming them, and dragging things manually.**

Imagine your Desktop or Downloads folder is a mess. You have 15 different
images, documents, and sub-folders all related to "Project X". Normally, you'd
have to right-click -> New -> Folder, type the name, select all 15 items, and
drag them inside.

**Julibe's Item Organizer** is the magic tool that turns a multi-step chore into
a **single drag-and-drop motion.**

It is the essential tool for:

- **Digital Hoarders** trying to quickly group downloaded assets.
- **Creative Professionals** bundling project files together.
- **Anyone** who wants a perfectly clean desktop in a matter of seconds.

---

## Known Bugs & Limitations

1.  **Cross-Drive Moving:** If you enter a manual path that is on a different
    drive than the script, Windows handles "Moves" as "Copy then Delete". For
    massive files (like 50GB videos), this will take time.
2.  **Path Length Limits:** Windows has a historical 260-character path limit.
    If nesting these items inside the new folder pushes the file path over this
    limit, the move might fail.
3.  **Admin Rights:** If you are trying to organize files located in protected
    system directories (like `C:\Program Files`), you will need to run the
    script as **Administrator**.
4.  **Temp File:** The script creates a temporary `.ps1` file in your `%temp%`
    folder during execution. It attempts to delete it automatically, but a hard
    crash might leave a harmless residue file.

---

## 👨Credits

- **Created By:** Julibe
- **Website:** [https://julibe.com](https://julibe.com)
- **Copyright:** 2026
- **Mission:** Crafting Amazing Digital Experiences.

---

_Disclaimer: This tool modifies and moves files. While it includes extensive
safety checks (like preventing moving a folder into itself), always backup your
data before running bulk file operations._
