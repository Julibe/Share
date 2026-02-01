# 📂 Julibe's Folder Merger

> **The "Drag-and-Drop" utility for consolidating scattered folders into one.**

![Version](https://img.shields.io/badge/version-2026-yellow) ![Platform](https://img.shields.io/badge/platform-Windows-0078D6) ![Author](https://img.shields.io/badge/author-Julibe-orange)

---

## 📝 Usage Instructions
1.  Download (or save the code as) `Folder Merger.bat`.
2.  **Select multiple folders** that you want to combine in File Explorer.
3.  **Drag and Drop** the selection directly onto the `Folder Merger.bat` icon.
4.  A console window will open.
5.  **Type the name** for the new combined folder (or accept the default) and press Enter.
6.  **Handle Conflicts:** If files have the same name, the script will ask you to `(O)verwrite`, `(R)ename`, or `(S)kip`.
7.  Done! Empty source folders are automatically sent to the Recycle Bin.

---

## 📖 What This Does
**Julibe's Folder Merger** is a powerful hybrid Batch + PowerShell automation tool designed to solve the chaos of **file fragmentation.**

It takes multiple directories and **merges** their contents into a single destination while maintaining the internal subfolder structure.

**Key capabilities:**
1.  **Intelligent Moving:** Moves files from Source A, B, and C into Destination X.
2.  **Conflict Management:** Unlike Windows Explorer (which just asks "Replace?"), this tool offers a **Rename** option (e.g., `Image.jpg` -> `Image (2).jpg`) so you never lose data.
3.  **Auto-Cleanup:** Once a source folder is successfully emptied, it is safely moved to the **Recycle Bin**.

---

## 💎 Why You Need This
**Stop cutting and pasting manually.**

Imagine you have a directory filled with:
*   `Project_Alpha_v1`
*   `Project_Alpha_v2`
*   `Project_Alpha_Final`
*   `Project_Alpha_REAL_FINAL`

You want them all in **one** master folder called `Project Alpha Complete`. Doing this manually means opening every folder, selecting all, cutting, pasting, dealing with "File Exists" errors, and then deleting the empty folders one by one.

**Julibe's Folder Merger** turns 15 minutes of clicking into **5 seconds**.

It is the essential tool for:
*   **Photographers** consolidating SD card dumps.
*   **Data Hoarders** merging downloaded parts or seasons.
*   **Organizers** cleaning up messy Desktops and Download folders.

---

## ⚙️ How It Works (The Solution)
This tool utilizes a "Polyglot" Hybrid Scripting technique.

1.  **The Interface (Batch):** Sets the visual theme (Construction Yellow) and handles the Drag-and-Drop logic.
2.  **The Logic (PowerShell):**
    *   Uses `.NET` libraries to create a GUI Input Box for naming.
    *   Calculates **Relative Paths** to ensure that if you merge complex folder structures, they are recreated perfectly in the destination.
    *   **Safety First:** It uses `Microsoft.VisualBasic.FileIO` to delete empty folders to the **Recycle Bin** rather than permanently deleting them. If you make a mistake, you can just "Restore."

---

## 🐞 Known Bugs & Limitations
1.  **Path Length:** Windows has a standard limit of 260 characters for file paths. Deeply nested folders might trigger errors if the path becomes too long during the merge.
2.  **Locked Files:** If a file inside a folder is currently open in another program (like Word or Photoshop), the script cannot move it, and the parent folder will not be recycled.
3.  **Name Collisions:** The "Rename" function appends `(2)`, `(3)`, etc. If you have thousands of files with the exact same name, processing might slow down slightly as it finds a free number.
4.  **UI:** The conflict resolution prompt (`Overwrite/Rename/Skip`) happens inside the console window. You need to keep an eye on the black window during the process.

---

## 👨‍💻 Credits
*   **Created By:** Julibe
*   **Website:** [https://julibe.com](https://julibe.com)
*   **Copyright:** 2026
*   **Mission:** Crafting Amazing Digital Experiences.

---

*Disclaimer: This tool moves and modifies files. While it includes safety checks (like using the Recycle Bin), always backup your data before running batch operations on critical system files.*