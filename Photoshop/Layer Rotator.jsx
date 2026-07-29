#target photoshop

/*
 * ============================================================================
 * Photoshop Layer Rotator
 * ============================================================================
 * Author: Julibe - Crafting Digital Experiences
 * Year: 2026
 * Website: https://julibe.com
 * Email: mail@julibe.com
 * ============================================================================
 */


var GLOBAL_angle, GLOBAL_flipH, GLOBAL_flipV, GLOBAL_anchor;
var GLOBAL_convertSO, GLOBAL_processAll, GLOBAL_processGroups;
var GLOBAL_tempSelectedIDs = [];

/**
 * Initializes the script, captures the initial state, and builds the UI.
 */
function main() {
    if (app.documents.length === 0) {
        alert("Whoops! It looks like you don't have any documents open right now.\n\nPlease open a file first so we have some layers to work with!");
        return;
    }

    // Capture initially selected layers safely
    GLOBAL_tempSelectedIDs = getSelectedLayerIDs();

    var win = new Window("dialog", "Photoshop Layer Rotator | by Julibe");
    win.orientation = "column";
    win.alignChildren = ["fill", "top"];

    // --- ROTATION PANEL ---
    var inputPanel = win.add("panel", undefined, "Rotation Angle (Degrees)");
    inputPanel.orientation = "row";
    inputPanel.alignChildren = ["left", "center"];
    inputPanel.margins = 15;

    inputPanel.add("statictext", undefined, "Angle:");
    var inputAngle = inputPanel.add("edittext", undefined, "0");
    inputAngle.characters = 6;
    inputPanel.add("statictext", undefined, "°");

    // --- QUICK PRESETS PANEL ---
    var presetPanel = win.add("panel", undefined, "Quick Angles");
    presetPanel.orientation = "row";
    presetPanel.alignChildren = ["center", "center"];
    presetPanel.margins = 15;

    var btn90CW = presetPanel.add("button", undefined, "+ 90° (CW)");
    var btn90CCW = presetPanel.add("button", undefined, "- 90° (CCW)");
    var btn180 = presetPanel.add("button", undefined, "180°");
    var btn0 = presetPanel.add("button", undefined, "Reset (0°)");

    // --- FLIPPING PANEL ---
    var flipPanel = win.add("panel", undefined, "Flipping");
    flipPanel.orientation = "row";
    flipPanel.alignChildren = ["center", "center"];
    flipPanel.margins = 15;

    var chkFlipH = flipPanel.add("checkbox", undefined, "Flip Horizontally");
    var chkFlipV = flipPanel.add("checkbox", undefined, "Flip Vertically");

    // --- SETTINGS PANEL ---
    var settingsPanel = win.add("panel", undefined, "Settings & Behaviors");
    settingsPanel.orientation = "column";
    settingsPanel.alignChildren = ["left", "top"];
    settingsPanel.margins = 15;

    var anchorGroup = settingsPanel.add("group");
    anchorGroup.add("statictext", undefined, "Transform Anchor:");
    var anchorDropdown = anchorGroup.add("dropdownlist", undefined, [
        "Top Left", "Top Center", "Top Right",
        "Middle Left", "Middle Center", "Middle Right",
        "Bottom Left", "Bottom Center", "Bottom Right"
    ]);
    anchorDropdown.selection = 4; // Default to Middle Center

    // --- ADVANCED PANEL ---
    var advPanel = win.add("panel", undefined, "Advanced Options");
    advPanel.orientation = "column";
    advPanel.alignChildren = ["left", "top"];
    advPanel.margins = 15;

    var chkSmartObject = advPanel.add(
        "checkbox",
        undefined,
        "Convert layers to Smart Objects before rotating (Prevents quality loss)"
    );
    chkSmartObject.value = true; // Default ON for rotation to preserve pixels!

    var chkProcessGroups = advPanel.add(
        "checkbox",
        undefined,
        "Process individual layers inside groups (folders)"
    );
    chkProcessGroups.value = false;

    var chkProcessAll = advPanel.add(
        "checkbox",
        undefined,
        "Process all layers in the document (ignores selection)"
    );
    chkProcessAll.value = false;

    // --- CREDITS PANEL ---
    var creditPanel = win.add("panel", undefined, "About");
    creditPanel.orientation = "column";
    creditPanel.alignChildren = ["center", "center"];
    creditPanel.margins = 15;

    var cr1 = creditPanel.add(
        "statictext",
        undefined,
        "Julibe | Crafting Digital Experiences"
    );
    cr1.graphics.font = ScriptUI.newFont("dialog", "bold", 13);

    var cr2 = creditPanel.add(
        "statictext",
        undefined,
        "https://julibe.com   |   mail@julibe.com"
    );
    cr2.graphics.font = ScriptUI.newFont("dialog", "regular", 11);

    // --- BUTTONS ---
    var btnGroup = win.add("group");
    btnGroup.alignment = ["center", "top"];

    var btnOk = btnGroup.add("button", undefined, "Rotate & Flip Layers", { name: "ok" });
    var btnCancel = btnGroup.add("button", undefined, "Cancel", { name: "cancel" });

    // Button Logic
    btn90CW.onClick = function() { inputAngle.text = "90"; };
    btn90CCW.onClick = function() { inputAngle.text = "-90"; };
    btn180.onClick = function() { inputAngle.text = "180"; };
    btn0.onClick = function() { inputAngle.text = "0"; };

    function getAnchorEnum(index) {
        var anchors = [
            AnchorPosition.TOPLEFT, AnchorPosition.TOPCENTER, AnchorPosition.TOPRIGHT,
            AnchorPosition.MIDDLELEFT, AnchorPosition.MIDDLECENTER, AnchorPosition.MIDDLERIGHT,
            AnchorPosition.BOTTOMLEFT, AnchorPosition.BOTTOMCENTER, AnchorPosition.BOTTOMRIGHT
        ];
        return anchors[index];
    }

    btnOk.onClick = function() {
        var angle = parseFloat(inputAngle.text);

        if (isNaN(angle)) {
            alert("Looks like you entered an invalid angle!\n\nPlease type a number (e.g., 45, 90, -30) so I know how much to rotate your layers.");
            return;
        }

        if (angle === 0 && !chkFlipH.value && !chkFlipV.value) {
            alert("Wait a second, nothing is set to change!\n\nPlease enter an angle or check one of the flipping boxes.");
            return;
        }

        if (!chkProcessAll.value && GLOBAL_tempSelectedIDs.length === 0) {
            alert("Looks like no layers are selected.\n\nPlease select the layers you'd like to process in the panel, or check \"Process all layers in the document\".");
            return;
        }

        win.close(1);
    };

    if (win.show() !== 1) return;

    // Set globals for processing
    GLOBAL_angle = parseFloat(inputAngle.text);
    GLOBAL_flipH = chkFlipH.value;
    GLOBAL_flipV = chkFlipV.value;
    GLOBAL_convertSO = chkSmartObject.value;
    GLOBAL_processAll = chkProcessAll.value;
    GLOBAL_processGroups = chkProcessGroups.value;
    GLOBAL_anchor = getAnchorEnum(anchorDropdown.selection.index);

    app.activeDocument.suspendHistory("Rotate & Flip Layers (by Julibe)", "processLayers()");
}

/**
 * Executes the core layer logic based on the user's defined global settings.
 */
function processLayers() {
    try {
        var finalLayerIDs = [];

        if (GLOBAL_processAll) {
            collectAllStandardLayers(app.activeDocument, finalLayerIDs);
        } else {
            for (var i = 0; i < GLOBAL_tempSelectedIDs.length; i++) {
                selectLayerByID(GLOBAL_tempSelectedIDs[i], false);
                processLayerNode(app.activeDocument.activeLayer, finalLayerIDs);
            }
        }

        if (finalLayerIDs.length === 0) {
            alert("Hmm, I couldn't find any valid layers to process!\n\nJust a heads-up: locked layers, background layers, and completely empty layers are skipped automatically.");
            return;
        }

        for (var j = 0; j < finalLayerIDs.length; j++) {
            selectLayerByID(finalLayerIDs[j], false);
            var layer = app.activeDocument.activeLayer;

            // 1. Convert to Smart Object (Highly recommended for rotations)
            if (GLOBAL_convertSO && layer.kind !== LayerKind.SMARTOBJECT) {
                try {
                    executeAction(stringIDToTypeID("newPlacedLayer"), undefined, DialogModes.NO);
                    layer = app.activeDocument.activeLayer;
                } catch(e) {}
            }

            // 2. Apply Flipping
            var scaleX = GLOBAL_flipH ? -100 : 100;
            var scaleY = GLOBAL_flipV ? -100 : 100;

            if (scaleX === -100 || scaleY === -100) {
                layer.resize(scaleX, scaleY, GLOBAL_anchor);
            }

            // 3. Apply Rotation
            if (GLOBAL_angle !== 0) {
                layer.rotate(GLOBAL_angle, GLOBAL_anchor);
            }
        }

        // Restore initial selection
        if (!GLOBAL_processAll) {
            for (var k = 0; k < GLOBAL_tempSelectedIDs.length; k++) {
                selectLayerByID(GLOBAL_tempSelectedIDs[k], k !== 0);
            }
        } else {
            app.activeDocument.selection.deselect();
        }

        var successMsg = "All done! I successfully rotated and/or flipped " + finalLayerIDs.length + " layer(s) for you.\n\n";
        successMsg += "Thank you for using the Photoshop Layer Rotator. I hope this tool perfectly complements your workflow!\n\n";
        successMsg += "If you'd like to see more of my work or need other custom tools, I'd love for you to drop by:\n\n";
        successMsg += "Julibe | Crafting Digital Experiences\n";
        successMsg += "https://julibe.com\n";
        successMsg += "mail@julibe.com\n\n";
        successMsg += "Happy designing!";

        alert(successMsg);

    } catch(e) {
        alert("Oops, something went wrong!\n\n" + e.message + "\n\nIf this keeps happening, feel free to reach out to mail@julibe.com.");
    }
}

function collectAllStandardLayers(parent, idArray) {
    for (var i = 0; i < parent.layers.length; i++) {
        processLayerNode(parent.layers[i], idArray);
    }
}

function processLayerNode(layer, idArray) {
    if (layer.isBackgroundLayer || layer.allLocked) return;

    if (layer.typename === "LayerSet" && GLOBAL_processGroups) {
        for (var i = 0; i < layer.layers.length; i++) {
            processLayerNode(layer.layers[i], idArray);
        }
    } else {
        var exists = false;
        for (var k = 0; k < idArray.length; k++) {
            if (idArray[k] === layer.id) {
                exists = true;
                break;
            }
        }
        if (!exists) {
            idArray.push(layer.id);
        }
    }
}

/**
 * Bulletproof way to get exact layer IDs.
 * Bypasses the Photoshop "Background Layer Offset" bug.
 */
function getSelectedLayerIDs() {
    var selectedIDs = [];

    // METHOD 1: Try modern targetLayersIDs
    try {
        var ref = new ActionReference();
        ref.putProperty(stringIDToTypeID("property"), stringIDToTypeID("targetLayersIDs"));
        ref.putEnumerated(charIDToTypeID("Dcmn"), charIDToTypeID("Ordn"), charIDToTypeID("Trgt"));
        var desc = executeActionGet(ref);

        if (desc.hasKey(stringIDToTypeID("targetLayersIDs"))) {
            var list = desc.getList(stringIDToTypeID("targetLayersIDs"));
            for (var i = 0; i < list.count; i++) {
                selectedIDs.push(list.getInteger(i));
            }
            if (selectedIDs.length > 0) return selectedIDs;
        }
    } catch(e) {}

    // METHOD 2: Fallback for older Photoshop versions
    try {
        var ref = new ActionReference();
        ref.putProperty(stringIDToTypeID("property"), stringIDToTypeID("targetLayers"));
        ref.putEnumerated(charIDToTypeID("Dcmn"), charIDToTypeID("Ordn"), charIDToTypeID("Trgt"));
        var desc = executeActionGet(ref);

        var hasBackground = false;
        try { hasBackground = app.activeDocument.backgroundLayer !== null; } catch(e) {}

        if (desc.hasKey(stringIDToTypeID("targetLayers"))) {
            var targetLayers = desc.getList(stringIDToTypeID("targetLayers"));
            for (var i = 0; i < targetLayers.count; i++) {
                var index = targetLayers.getReference(i).getIndex();

                if (hasBackground) index += 1;

                var ref2 = new ActionReference();
                ref2.putProperty(stringIDToTypeID("property"), stringIDToTypeID("layerID"));
                ref2.putIndex(charIDToTypeID("Lyr "), index);
                var id = executeActionGet(ref2).getInteger(stringIDToTypeID("layerID"));
                selectedIDs.push(id);
            }
        } else {
            var ref3 = new ActionReference();
            ref3.putProperty(stringIDToTypeID("property"), stringIDToTypeID("layerID"));
            ref3.putEnumerated(charIDToTypeID("Lyr "), charIDToTypeID("Ordn"), charIDToTypeID("Trgt"));
            selectedIDs.push(executeActionGet(ref3).getInteger(stringIDToTypeID("layerID")));
        }
    } catch (e) {}

    // METHOD 3: Absolute Failsafe
    if (selectedIDs.length === 0) {
        try {
            if (app.activeDocument && app.activeDocument.activeLayer) {
                selectedIDs.push(app.activeDocument.activeLayer.id);
            }
        } catch(e) {}
    }

    return selectedIDs;
}

/**
 * Safely select layers by ID to prevent crashes
 */
function selectLayerByID(id, add) {
    try {
        var desc = new ActionDescriptor();
        var ref = new ActionReference();
        ref.putIdentifier(charIDToTypeID("Lyr "), id);
        desc.putReference(charIDToTypeID("null"), ref);
        if (add) {
            desc.putEnumerated(stringIDToTypeID("selectionModifier"), stringIDToTypeID("selectionModifierType"), stringIDToTypeID("addToSelection"));
        }
        desc.putBoolean(charIDToTypeID("MkVs"), false);
        executeAction(charIDToTypeID("slct"), desc, DialogModes.NO);
    } catch (e) { }
}

main();