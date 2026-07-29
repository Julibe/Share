# Julibe's Photoshop Layer Resizer

> **The ultimate utility for batch-resizing multiple layers precisely and
> effortlessly in Adobe Photoshop.**

## ![Version](https://img.shields.io/badge/version-2026-brightgreen) ![Platform](https://img.shields.io/badge/platform-Photoshop_JSX-001E36) ![Author](https://img.shields.io/badge/author-Julibe-orange)

## Usage Instructions

1.  Download the `Julibe_Layer_Resizer.jsx` script file.
2.  Open your document in **Adobe Photoshop**.
3.  **Select** the layers you want to resize in the Layers panel (skip this if
    you plan to resize _all_ layers).
4.  Go to **File > Scripts > Browse...** and select the `.jsx` file.
    - _(Pro-tip: Place the script in
      `C:\Program Files\Adobe\Adobe Photoshop 202X\Presets\Scripts` so it always
      appears in your File > Scripts menu!)_
5.  A custom interface will appear. Enter your desired **Width / Height**, or
    use the **Quick Fill** canvas percentage buttons.
6.  Tweak your settings (Anchor point, Aspect Ratio, Smart Object conversion).
7.  Click **Resize Layers**.
8.  Done!

---

## What This Does

**Julibe's Photoshop Layer Resizer** is an advanced JSX automation script
designed to solve a major workflow bottleneck in Photoshop: **Resizing multiple
independent layers to exact dimensions at the same time.**

Normally, Photoshop's transform tool resizes layers _relative_ to their current
size. If you select 10 layers of different sizes and type "1024px", it stretches
them as a single group. This tool treats every layer individually.

**Key Features Include:**

1.  **Exact Dimensions:** Force multiple layers to be exactly `1024px` wide,
    regardless of their starting size.
2.  **Preserve Aspect Ratio:** Enter just a Width (or just a Height), and the
    script perfectly scales the other side.
3.  **Smart Object Auto-Conversion:** Optionally convert every layer to a Smart
    Object _before_ resizing to preserve pristine image quality.
4.  **Prevent Upscaling:** A safety toggle that ensures smaller icons/images
    aren't blown up and pixelated if they are smaller than your target size.
5.  **Anchor Control:** Choose exactly how the layer scales (e.g., pin to Top
    Left, scale from Center).
6.  **Deep Processing:** Can dive into Layer Groups (folders) or just process
    the entire document in one click.

---

## Why You Need This

**Stop transforming layers one by one.**

Imagine you are designing a UI, a collage, or a sprite sheet. You just dropped
50 different icons or images into your document, and they are all massive,
random sizes.

Normally, you would have to click Layer 1, press `Ctrl+T`, type a percentage,
hit enter, and repeat 50 times.

**Julibe's Layer Resizer** turns this 10-minute nightmare into a **3-second
task**.

It is the essential tool for:

- **UI/UX Designers** standardizing icon sets and buttons.
- **Photographers** quickly creating exact-sized watermark layers or photo
  grids.
- **Digital Artists** prepping assets for game engines or web delivery.

---

## Known Bugs & Limitations

1.  **Background Layers & Locked Layers:** The script will intentionally skip
    the locked "Background" layer and any layer that has its pixels/position
    locked to prevent Photoshop from throwing critical errors.
2.  **Empty Layers:** Layers with absolutely no pixel data (0x0 bounds) are
    automatically skipped.
3.  **Text Layers:** Resizing raw text layers via bounds can sometimes yield
    unpredictable font-size scaling. Using the "Convert to Smart Object" toggle
    first is highly recommended for text.
4.  **Performance:** Processing _hundreds_ of layers at once, especially if
    converting them all to Smart Objects, may cause Photoshop to freeze for a
    few moments. Let it process!

---

## Credits

- **Created By:** Julibe
- **Website:** [https://julibe.com](https://julibe.com)
- **Email:** mail@julibe.com
- **Copyright:** 2026
- **Mission:** Crafting Amazing Digital Experiences.

---

_Disclaimer: This script modifies your document history. While everything is
wrapped into a single Undo state ("Resize Layers (by Julibe)"), it is always
recommended to save your document before running bulk automation scripts._
