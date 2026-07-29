# Julibe's Photoshop Layer Rotator

> **The ultimate utility for batch-rotating and flipping multiple layers
> independently, precisely, and effortlessly in Adobe Photoshop.**

## ![Version](https://img.shields.io/badge/version-2026-brightgreen) ![Platform](https://img.shields.io/badge/platform-Photoshop_JSX-001E36) ![Author](https://img.shields.io/badge/author-Julibe-orange)

## Usage Instructions

1. Download the `Layer Rotator.jsx` script file.
2. Open your document in **Adobe Photoshop**.
3. **Select** the layers you want to rotate or flip in the Layers panel (skip
   this if you plan to process every layer in the document).
4. Go to **File > Scripts > Browse...** and select the `.jsx` file.
    - _(Pro-tip: Place the script in
      `C:\Program Files\Adobe\Adobe Photoshop 202X\Presets\Scripts` so it always
      appears in your **File > Scripts** menu!)_
5. Enter the desired **rotation angle**, or use one of the **Quick Angle**
   preset buttons.
6. Optionally enable **Horizontal Flip**, **Vertical Flip**, choose the
   **Transform Anchor**, and configure the advanced options.
7. Click **Rotate & Flip Layers**.
8. Done!

---

## What This Does

**Photoshop Layer Rotator** is a powerful JSX automation script built to solve
another frustrating Photoshop limitation: **Applying identical rotations and
flips to multiple independent layers without transforming them as a single
group.**

Normally, Photoshop treats multiple selected layers as one combined object
during Free Transform. While this works for some situations, it becomes a major
problem when each layer needs to rotate around its own center or anchor point.

This script processes every selected layer individually while maintaining
complete control over each transformation.

**Key Features Include:**

1. **Independent Layer Rotation:** Rotate every selected layer by the exact same
   angle without grouping them together.
2. **Quick Rotation Presets:** Instantly apply common angles like **90° CW**,
   **90° CCW**, **180°**, or reset to **0°** with a single click.
3. **Horizontal & Vertical Flipping:** Mirror layers individually without
   affecting neighboring artwork.
4. **Transform Anchor Control:** Rotate or flip around any of Photoshop's nine
   anchor positions.
5. **Smart Object Auto-Conversion:** Optionally convert layers into Smart
   Objects before transforming to preserve maximum image quality.
6. **Flexible Processing:** Rotate only selected layers, every layer in the
   document, or even recursively process layers inside groups.

---

## Why You Need This

**Stop rotating layers one by one.**

Imagine you're designing a game sprite sheet, social media graphics, mockups, or
UI assets. You need dozens of elements rotated exactly 90°, mirrored, or turned
upside down.

Normally, you would:

- Select a layer.
- Press `Ctrl+T`.
- Rotate or flip it.
- Confirm.
- Repeat dozens or even hundreds of times.

**Layer Rotator** transforms this repetitive workflow into a **single
operation**.

It is the perfect companion for:

- **UI/UX Designers** creating interface variations.
- **Digital Artists** preparing assets for animation or games.
- **Graphic Designers** producing layouts with repeated rotated elements.
- **Photographers** creating mirrored compositions or stylized effects.
- **Content Creators** generating multiple asset orientations in seconds.

---

## Known Bugs & Limitations

1. **Background & Locked Layers:** Locked and Background layers are skipped
   automatically to prevent Photoshop errors.
2. **Empty Layers:** Layers containing no pixel information are ignored.
3. **Text Layers:** Rotating native text layers generally works well, but using
   **Convert to Smart Object** first is recommended for maximum consistency.
4. **Performance:** Processing hundreds of layers, especially while converting
   each one into a Smart Object, may temporarily freeze Photoshop. Simply allow
   the script to finish.
5. **Layer Groups:** Layers inside folders are only processed when the **Process
   individual layers inside groups** option is enabled.

---

## Credits

- **Created By:** Julibe
- **Website:** https://julibe.com
- **Email:** mail@julibe.com
- **Copyright:** 2026
- **Mission:** Crafting Amazing Digital Experiences.

---

_Disclaimer: This script modifies your document history. Every operation is
wrapped into a single Undo state ("Rotate & Flip Layers (by Julibe)"), but it's
always recommended to save your document before running any bulk automation
script._
