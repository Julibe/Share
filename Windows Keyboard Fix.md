# Change Windows Keyboard Layout

1. Open **Registry Editor** (`Win + R`, type `regedit`).
2. Go to:
   - `HKEY_USERS\.DEFAULT\Keyboard Layout\Preload`
   - `HKEY_CURRENT_USER\Keyboard Layout\Preload`
3. Set the value:
   - **Latin America**: `0000080a`
   - **USA English**: `00000409`
4. Restart your computer.
