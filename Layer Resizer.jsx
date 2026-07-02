#target photoshop

/*
 * ============================================================================
 * Photoshop Layer Resizer
 * ============================================================================
 * Author:  Julibe - Crafting Digital Experiences
 * Year:    2026
 * Website: https://julibe.com
 * Email:   mail@julibe.com
 * ============================================================================
 */


var GLOBAL_targetW, GLOBAL_targetH, GLOBAL_hasW, GLOBAL_hasH, GLOBAL_constrain, GLOBAL_unit, GLOBAL_anchor;
var GLOBAL_noUpscale, GLOBAL_convertSO, GLOBAL_processAll, GLOBAL_processGroups;
var GLOBAL_tempSelectedIDs = [];

/**
 * Initializes the script, captures the initial state, and builds the UI.
 */
function main() {
    if (app.documents.length === 0) {
        alert("It looks like you don't have any documents open right now.\n\nPlease open a file first so we have some layers to work with!");
        return;
    }

    // Capture initially selected layers safely
    GLOBAL_tempSelectedIDs = getSelectedLayerIDs();

    var win = new Window("dialog", "Photoshop Layer Resizer | by Julibe");
    win.orientation = "column";
    win.alignChildren = ["fill", "top"];

    var inputPanel = win.add("panel", undefined, "New Dimensions");
    inputPanel.orientation = "row";
    inputPanel.alignChildren = ["left", "center"];
    inputPanel.margins = 15;

    inputPanel.add("statictext", undefined, "W:");
    var inputW = inputPanel.add("edittext", undefined, "1024");
    inputW.characters = 6;

    inputPanel.add("statictext", undefined, "H:");
    var inputH = inputPanel.add("edittext", undefined, "");
    inputH.characters = 6;

    var unitDropdown = inputPanel.add("dropdownlist", undefined, ["Pixels", "Inches", "Centimeters", "Millimeters", "Points", "Picas"]);
    unitDropdown.selection = 0;

    var presetPanel = win.add("panel", undefined, "Quick Fill from Canvas Size");
    presetPanel.orientation = "row";
    presetPanel.alignChildren = ["center", "center"];
    presetPanel.margins = 15;

    var btn200 = presetPanel.add("button", undefined, "200%");
    var btn150 = presetPanel.add("button", undefined, "150%");
    var btnFull = presetPanel.add("button", undefined, "100%");
    var btnHalf = presetPanel.add("button", undefined, "50%");
    var btnThird = presetPanel.add("button", undefined, "33%");

    var settingsPanel = win.add("panel", undefined, "Settings & Behaviors");
    settingsPanel.orientation = "column";
    settingsPanel.alignChildren = ["left", "top"];
    settingsPanel.margins = 15;

    var anchorGroup = settingsPanel.add("group");
    anchorGroup.add("statictext", undefined, "Resize Anchor:");
    var anchorDropdown = anchorGroup.add("dropdownlist", undefined, [
        "Top Left", "Top Center", "Top Right",
        "Middle Left", "Middle Center", "Middle Right",
        "Bottom Left", "Bottom Center", "Bottom Right"
    ]);
    anchorDropdown.selection = 4;

    var chkConstrain = settingsPanel.add(
        "checkbox",
        undefined,
        "Preserve Aspect Ratio (Fit Within Bounds)"
    );
    chkConstrain.value = true;

    var chkNoUpscale = settingsPanel.add(
        "checkbox",
        undefined,
        "Prevent Upscaling (Don't enlarge smaller layers)"
    );
    chkNoUpscale.value = false;

    var advPanel = win.add("panel", undefined, "Advanced Options");
    advPanel.orientation = "column";
    advPanel.alignChildren = ["left", "top"];
    advPanel.margins = 15;

    var chkSmartObject = advPanel.add(
        "checkbox",
        undefined,
        "Convert layers to Smart Objects before resizing"
    );
    chkSmartObject.value = false;

    var chkProcessGroups = advPanel.add(
        "checkbox",
        undefined,
        "Process layers inside groups (folders)"
    );
    chkProcessGroups.value = false;

    var chkProcessAll = advPanel.add(
        "checkbox",
        undefined,
        "Process all layers in the document (ignores selection)"
    );
    chkProcessAll.value = false;

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

    var btnGroup = win.add("group");
    btnGroup.alignment = ["center", "top"];

    var btnOk = btnGroup.add("button", undefined, "Resize Layers", { name: "ok" });
    var btnCancel = btnGroup.add("button", undefined, "Cancel", { name: "cancel" });

    function getUnitEnum(index) {
        var units = [Units.PIXELS, Units.INCHES, Units.CM, Units.MM, Units.POINTS, Units.PICAS];
        return units[index];
    }

    function getAnchorEnum(index) {
        var anchors = [
            AnchorPosition.TOPLEFT, AnchorPosition.TOPCENTER, AnchorPosition.TOPRIGHT,
            AnchorPosition.MIDDLELEFT, AnchorPosition.MIDDLECENTER, AnchorPosition.MIDDLERIGHT,
            AnchorPosition.BOTTOMLEFT, AnchorPosition.BOTTOMCENTER, AnchorPosition.BOTTOMRIGHT
        ];
        return anchors[index];
    }

    function fillCanvasSize(multiplier) {
        var originalUnits = app.preferences.rulerUnits;
        app.preferences.rulerUnits = getUnitEnum(unitDropdown.selection.index);
        var w = app.activeDocument.width.value * multiplier;
        var h = app.activeDocument.height.value * multiplier;
        inputW.text = (Math.round(w * 100) / 100).toString();
        inputH.text = (Math.round(h * 100) / 100).toString();
        app.preferences.rulerUnits = originalUnits;
    }

    btn200.onClick = function() { fillCanvasSize(2); };
    btn150.onClick = function() { fillCanvasSize(1.5); };
    btnFull.onClick = function() { fillCanvasSize(1); };
    btnHalf.onClick = function() { fillCanvasSize(0.5); };
    btnThird.onClick = function() { fillCanvasSize(1/3); };

    btnOk.onClick = function() {
        var w = parseFloat(inputW.text);
        var h = parseFloat(inputH.text);

        if (isNaN(w) && isNaN(h)) {
            alert("Looks like you forgot to enter the dimensions!\n\nPlease type in at least a width or a height so I know how big to make your layers.");
            return;
        }

        if (!chkProcessAll.value && GLOBAL_tempSelectedIDs.length === 0) {
            alert("Looks like no layers are selected.\n\nPlease select the layers you'd like to resize in the panel, or check \"Process all layers in the document\".");
            return;
        }

        win.close(1);
    };

    if (win.show() !== 1) return;

    GLOBAL_targetW = parseFloat(inputW.text);
    GLOBAL_targetH = parseFloat(inputH.text);
    GLOBAL_hasW = !isNaN(GLOBAL_targetW) && GLOBAL_targetW > 0;
    GLOBAL_hasH = !isNaN(GLOBAL_targetH) && GLOBAL_targetH > 0;
    GLOBAL_constrain = chkConstrain.value;
    GLOBAL_noUpscale = chkNoUpscale.value;
    GLOBAL_convertSO = chkSmartObject.value;
    GLOBAL_processAll = chkProcessAll.value;
    GLOBAL_processGroups = chkProcessGroups.value;
    GLOBAL_unit = getUnitEnum(unitDropdown.selection.index);
    GLOBAL_anchor = getAnchorEnum(anchorDropdown.selection.index);

    app.activeDocument.suspendHistory("Resize Layers (by Julibe)", "processLayers()");
}

/**
 * Executes the core layer resizing logic based on the user's defined global settings.
 */
function processLayers() {
    var originalRulerUnits = app.preferences.rulerUnits;
    app.preferences.rulerUnits = GLOBAL_unit;

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
            alert("Hmm, I couldn't find any valid layers to resize!\n\nJust a heads-up: locked layers, background layers, and completely empty layers are skipped automatically.");
            return;
        }

        for (var j = 0; j < finalLayerIDs.length; j++) {
            selectLayerByID(finalLayerIDs[j], false);
            var layer = app.activeDocument.activeLayer;

            if (GLOBAL_convertSO && layer.kind !== LayerKind.SMARTOBJECT) {
                try {
                    executeAction(stringIDToTypeID("newPlacedLayer"), undefined, DialogModes.NO);
                    layer = app.activeDocument.activeLayer;
                } catch(e) {}
            }

            var bounds = layer.bounds;
            var currentW = bounds[2].value - bounds[0].value;
            var currentH = bounds[3].value - bounds[1].value;

            if (currentW <= 0 || currentH <= 0) continue;

            var scaleX = 100, scaleY = 100;

            if (GLOBAL_hasW && GLOBAL_hasH) {
                scaleX = (GLOBAL_targetW / currentW) * 100;
                scaleY = (GLOBAL_targetH / currentH) * 100;
                if (GLOBAL_constrain) {
                    var minScale = Math.min(scaleX, scaleY);
                    scaleX = minScale;
                    scaleY = minScale;
                }
            } else if (GLOBAL_hasW) {
                scaleX = (GLOBAL_targetW / currentW) * 100;
                scaleY = GLOBAL_constrain ? scaleX : 100;
            } else if (GLOBAL_hasH) {
                scaleY = (GLOBAL_targetH / currentH) * 100;
                scaleX = GLOBAL_constrain ? scaleY : 100;
            }

            if (GLOBAL_noUpscale) {
                if (scaleX > 100) scaleX = 100;
                if (scaleY > 100) scaleY = 100;
            }

            if (scaleX !== 100 || scaleY !== 100) {
                layer.resize(scaleX, scaleY, GLOBAL_anchor);
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

        var successMsg = "All done! I successfully resized " + finalLayerIDs.length + " layer(s) for you.\n\n";
        successMsg += "Thank you for using the Photoshop Layer Resizer. I hope this tool speeds up your workflow and saves you some valuable time!\n\n";
        successMsg += "If you'd like to see more of my work or need other custom tools, I'd love for you to drop by:\n\n";
        successMsg += "Julibe | Crafting Digital Experiences\n";
        successMsg += "https://julibe.com\n";
        successMsg += "mail@julibe.com\n\n";
        successMsg += "Happy designing!";

        alert(successMsg);

    } catch(e) {
        alert("Oops, something went wrong!\n\n" + e.message + "\n\nIf this keeps happening, feel free to reach out to mail@julibe.com.");
    } finally {
        app.preferences.rulerUnits = originalRulerUnits;
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

    // METHOD 1: Try modern targetLayersIDs (Fast & accurate, avoids index offset entirely)
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

        // Check if document has a Background layer (this causes the index shift bug)
        var hasBackground = false;
        try { hasBackground = app.activeDocument.backgroundLayer !== null; } catch(e) {}

        if (desc.hasKey(stringIDToTypeID("targetLayers"))) {
            var targetLayers = desc.getList(stringIDToTypeID("targetLayers"));
            for (var i = 0; i < targetLayers.count; i++) {
                var index = targetLayers.getReference(i).getIndex();

                // CRITICAL FIX: Compensate for the offset bug
                if (hasBackground) index += 1;

                var ref2 = new ActionReference();
                ref2.putProperty(stringIDToTypeID("property"), stringIDToTypeID("layerID"));
                ref2.putIndex(charIDToTypeID("Lyr "), index);
                var id = executeActionGet(ref2).getInteger(stringIDToTypeID("layerID"));
                selectedIDs.push(id);
            }
        } else {
            // Only 1 layer is selected
            var ref3 = new ActionReference();
            ref3.putProperty(stringIDToTypeID("property"), stringIDToTypeID("layerID"));
            ref3.putEnumerated(charIDToTypeID("Lyr "), charIDToTypeID("Ordn"), charIDToTypeID("Trgt"));
            selectedIDs.push(executeActionGet(ref3).getInteger(stringIDToTypeID("layerID")));
        }
    } catch (e) {}

    // METHOD 3: Absolute Failsafe (Grabs the currently clicked layer)
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
    } catch (e) {
        // Skip safely if ID doesn't exist
    }
}

main();