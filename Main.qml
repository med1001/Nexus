import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Material

ApplicationWindow {
    id: window
    width: 1200
    height: 800
    minimumWidth: 1000
    minimumHeight: 600
    visible: true
    title: "Gestionnaire de Configurations"

    Material.theme: Material.Dark
    Material.accent: Material.Purple
    Material.primary: Material.DeepPurple

    // Palette de couleurs personnalisée
    property color backgroundColor: "#1E1E2E"
    property color cardColor: "#2A2A3A"
    property color highlightColor: "#BB86FC"
    property color textColor: "#E0E0E0"
    property color subtleTextColor: "#A0A0A0"
    property color dangerColor: "#CF6679"

    // État de confirmation de suppression
    property int deleteIndex: -1

    // Filtres de recherche
    property string currentSearchText: ""
    // Dynamic filter support
    property var availableTypes: []
    property var selectedTypes: []

    // Displayed count (kept in sync when model/filter changes)
    property int displayedCount: 0

    // Guard to prevent recursive reloads when we intentionally call setFilter()/select()
    property bool suppressModelReload: false

    // Helper: reload distinct types from the C++ model
    function reloadTypes() {
        console.log("DEBUG: reloadTypes() - previous selectedTypes:", selectedTypes)
        var types = configModel.distinctTypes()
        var newAvailable = []
        var newSelected = []

        if (types && types.length > 0) {
            for (var i = 0; i < types.length; ++i) {
                var t = String(types[i]).trim()
                if (t.length === 0) continue
                newAvailable = newAvailable.concat([t])
                // Preserve previous selection if possible; if nothing was selected yet, select all by default
                if (selectedTypes && selectedTypes.length > 0) {
                    if (selectedTypes.indexOf(t) !== -1) newSelected = newSelected.concat([t])
                } else {
                    newSelected = newSelected.concat([t])
                }
            }
        }
        availableTypes = newAvailable
        selectedTypes = newSelected
        console.log("DEBUG: reloadTypes -> availableTypes=", availableTypes, "selectedTypes=", selectedTypes)
    }

    // Debounce timer for search field (reduces load by avoiding queries on every keystroke)
    Timer {
        id: searchTimer
        interval: 250 // ms
        repeat: false
        onTriggered: {
            currentSearchText = searchField.text
            applyFilters()
        }
    }

    // Arrière-plan avec dégradé subtil
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: backgroundColor }
            GradientStop { position: 1.0; color: Qt.darker(backgroundColor, 1.2) }
        }
    }

    // En-tête avec design moderne
    header: ToolBar {
        Material.background: cardColor
        Material.elevation: 3

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 20
            anchors.rightMargin: 20

            // Titre de l'application avec icône
            Row {
                spacing: 12
                Label {
                    text: "⚙️"
                    font.pixelSize: 24
                    anchors.verticalCenter: parent.verticalCenter
                }
                Label {
                    text: "Gestionnaire de Configurations"
                    font.pixelSize: 20
                    font.bold: true
                    color: textColor
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            Item { Layout.fillWidth: true }

            // Champ de recherche
            Rectangle {
                width: 280
                height: 40
                radius: 20
                color: Qt.lighter(cardColor, 1.2)

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 15
                    anchors.rightMargin: 10
                    spacing: 8

                    Text {
                        text: "🔍"
                        font.pixelSize: 16
                        opacity: 0.7
                    }

                    TextField {
                        id: searchField
                        Layout.fillWidth: true
                        placeholderText: "Rechercher des configurations..."
                        color: textColor
                        background: Item {}
                        selectByMouse: true

                        // Debounced search trigger
                        onTextChanged: {
                            searchTimer.restart()
                        }
                    }
                }
            }

            // Bouton Ajouter avec style moderne
            Button {
                text: "Nouvelle Configuration"
                Material.background: highlightColor
                Material.foreground: "white"
                implicitHeight: 40
                implicitWidth: 180

                onClicked: {
                    var list = templateManager.templates()
                    if (list.length > 0) {
                        addDialog.templateName = list[0]
                        // deep clone to avoid mutating manager-provided object
                        addDialog.template = JSON.parse(JSON.stringify(templateManager.getTemplate(addDialog.templateName)))
                    } else {
                        addDialog.templateName = ""
                        addDialog.template = {}
                    }
                    addDialog.prepareNew()
                    addDialog.open()
                }

                contentItem: Row {
                    spacing: 8
                    Text {
                        text: "+"
                        font.pixelSize: 16
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        text: parent.parent.text
                        font: parent.parent.font
                        color: parent.parent.Material.foreground
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }
        }
    }

    // Zone de contenu principale
    RowLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 20

        // Barre latérale avec filtres et statistiques
        ColumnLayout {
            Layout.preferredWidth: 280
            Layout.fillHeight: true
            spacing: 16

            // Carte de statistiques
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 120
                radius: 12
                color: cardColor

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 16

                    Label {
                        text: "Aperçu"
                        font.pixelSize: 16
                        font.bold: true
                        color: textColor
                    }

                    RowLayout {
                        Layout.fillWidth: true

                        Column {
                            Layout.fillWidth: true
                            spacing: 4

                            Label {
                                // Use displayedCount (keeps in sync)
                                text: displayedCount
                                font.pixelSize: 24
                                font.bold: true
                                color: highlightColor
                            }
                            Label {
                                text: "Configurations"
                                font.pixelSize: 12
                                color: subtleTextColor
                            }
                        }

                        Rectangle {
                            width: 1
                            height: 40
                            color: Qt.lighter(cardColor, 1.5)
                        }

                        Column {
                            Layout.fillWidth: true
                            spacing: 4

                            Label {
                                text: templateManager.templates().length
                                font.pixelSize: 24
                                font.bold: true
                                color: highlightColor
                            }
                            Label {
                                text: "Modèles"
                                font.pixelSize: 12
                                color: subtleTextColor
                            }
                        }
                    }
                }
            }

            // Carte de filtres (dynamic)
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 180
                radius: 12
                color: cardColor

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 12

                    Label {
                        text: "Filtres"
                        font.pixelSize: 16
                        font.bold: true
                        color: textColor
                    }

                    Column {
                        width: parent.width
                        spacing: 8

                        // Dynamic list of types (one checkbox per type)
                        Repeater {
                            model: availableTypes
                            delegate: CheckBox {
                                id: typeCheck
                                text: modelData
                                checked: selectedTypes.indexOf(modelData) !== -1
                                onCheckedChanged: {
                                    if (checked) {
                                        // add (assign new array to trigger bindings)
                                        selectedTypes = selectedTypes.concat([modelData])
                                    } else {
                                        // remove (assign new array)
                                        selectedTypes = selectedTypes.filter(function(x) { return x !== modelData })
                                    }
                                    applyFilters()
                                }
                            }
                        }

                        Label {
                            visible: availableTypes.length === 0
                            text: "(Aucun type trouvé)"
                            color: subtleTextColor
                        }
                    }

                    Item { Layout.fillHeight: true }

                    Button {
                        text: "Réinitialiser les filtres"
                        Layout.fillWidth: true
                        flat: true
                        onClicked: {
                            // Re-query types (in case new configs were added)
                            suppressModelReload = true
                            reloadTypes()
                            // ensure all are selected
                            selectedTypes = []
                            for (var i=0;i<availableTypes.length;++i) selectedTypes = selectedTypes.concat([availableTypes[i]])
                            searchField.text = ""
                            currentSearchText = ""
                            applyFilters()
                            suppressModelReload = false
                        }
                    }
                }
            }

            // Accès rapide aux modèles
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 12
                color: cardColor

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 16

                    Label {
                        text: "Modèles disponibles"
                        font.pixelSize: 16
                        font.bold: true
                        color: textColor
                    }

                    ListView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        model: templateManager.templates()
                        spacing: 8

                        delegate: Rectangle {
                            width: parent.width
                            height: 40
                            radius: 8
                            color: "transparent"
                            border.width: 1
                            border.color: Qt.lighter(cardColor, 1.3)

                            Label {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                text: modelData
                                color: textColor
                                verticalAlignment: Text.AlignVCenter
                                elide: Text.ElideRight
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    addDialog.templateName = modelData
                                    addDialog.template = JSON.parse(JSON.stringify(templateManager.getTemplate(modelData)))
                                    addDialog.prepareNew()
                                    addDialog.open()
                                }
                            }
                        }
                    }
                }
            }
        }

        // Contenu principal - Liste des configurations
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 16

            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                Label {
                    text: "Configurations"
                    font.pixelSize: 18
                    font.bold: true
                    color: textColor
                }

                Item { Layout.fillWidth: true }

                Label {
                    // Use displayedCount so it updates reliably
                    text: displayedCount + " résultat(s)"
                    font.pixelSize: 14
                    color: subtleTextColor
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 12
                color: cardColor

                ListView {
                    id: configList
                    anchors.fill: parent
                    anchors.margins: 1
                    clip: true
                    model: configModel
                    spacing: 8
                    boundsBehavior: Flickable.StopAtBounds

                    ScrollBar.vertical: ScrollBar {
                        policy: ScrollBar.AlwaysOn
                        width: 8
                        background: Rectangle {
                            color: "transparent"
                        }
                        contentItem: Rectangle {
                            implicitWidth: 6
                            radius: 3
                            color: Qt.lighter(cardColor, 1.5)
                        }
                    }

                    delegate: Item {
                        width: configList.width - 20
                        height: 100

                        Rectangle {
                            anchors.fill: parent
                            radius: 8
                            color: cardColor
                            border.width: 1
                            border.color: Qt.lighter(cardColor, 1.3)

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 12
                                spacing: 12

                                // Left column: take remaining space, don't use a fixed pixel width
                                ColumnLayout {
                                    Layout.fillWidth: true    // <-- use available space
                                    Layout.preferredWidth: 0  // <-- helps RowLayout distribute space correctly
                                    spacing: 2

                                    Text {
                                        text: "ID: " + model.id + "   (" + model.type + ")"
                                        color: "lightgray"
                                        font.pixelSize: 12
                                        elide: Text.ElideRight
                                    }
                                    Text {
                                        text: model.name
                                        color: "white"
                                        font { pixelSize: 18; bold: true }
                                        elide: Text.ElideRight
                                        wrapMode: Text.NoWrap
                                    }
                                    Text {
                                        color: "gray"
                                        font.pixelSize: 12
                                        text: {
                                            var s = ""
                                            try {
                                                var obj = JSON.parse(model.data)
                                                var first = true
                                                for (var k in obj) {
                                                    if (!first) s += "  •  "
                                                    s += k + ": " + String(obj[k])
                                                    first = false
                                                }
                                                if (s.length === 0) s = "(vide)"
                                            } catch (e) {
                                                s = "(données non valides)"
                                            }
                                            return s
                                        }
                                        elide: Text.ElideRight
                                        wrapMode: Text.NoWrap
                                    }
                                }

                                // spacer to push buttons to the right
                                Item { Layout.preferredWidth: 8 }

                                // Buttons group - keep them compact and give each a minimum width
                                RowLayout {
                                    spacing: 8
                                    Layout.alignment: Qt.AlignVCenter
                                    // Edit button
                                    Button {
                                        text: "✏️ Modifier"
                                        enabled: index >= 0
                                        implicitHeight: 36
                                        Layout.minimumWidth: 96
                                        onClicked: editDialog.openFor(index, model.type, model.name, model.data)
                                    }

                                    // Delete button
                                    Button {
                                        text: "🗑 Supprimer"
                                        Material.background: dangerColor
                                        implicitHeight: 36
                                        Layout.minimumWidth: 96
                                        onClicked: {
                                            deleteIndex = index
                                            confirmDialog.confirmText = "Voulez-vous vraiment supprimer \"" + model.name + "\" ?"
                                            confirmDialog.open()
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // État vide
                    Label {
                        anchors.centerIn: parent
                        text: "Aucune configuration trouvée"
                        visible: configList.count === 0
                        font.pixelSize: 16
                        color: subtleTextColor
                    }
                }
            }
        }
    }

    // Dialogue d'ajout de configuration
    Dialog {
        id: addDialog
        modal: true
        width: 600
        height: 700
        x: (window.width - width) / 2
        y: (window.height - height) / 2
        title: "Nouvelle Configuration"
        standardButtons: Dialog.Cancel | Dialog.Ok

        Material.background: cardColor
        Material.foreground: textColor
        Material.elevation: 8

        property string templateName: ""
        property var template: ({})
        property var formData: ({})
        property int templateVersion: 0  // Nouvelle propriété pour forcer la mise à jour

        // Properties for dragging
        property point startDragPos
        property bool dragging: false

        // Custom header for dragging
        header: Rectangle {
            height: 40
            color: Qt.darker(cardColor, 1.2)

            Label {
                text: addDialog.title
                color: textColor
                font.bold: true
                anchors.centerIn: parent
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.SizeAllCursor
                onPressed: {
                    addDialog.startDragPos = Qt.point(mouseX, mouseY)
                    addDialog.dragging = true
                }
                onPositionChanged: {
                    if (addDialog.dragging) {
                        addDialog.x += mouseX - addDialog.startDragPos.x
                        addDialog.y += mouseY - addDialog.startDragPos.y
                    }
                }
                onReleased: addDialog.dragging = false
            }
        }

        function prepareNew() {
            // Reset formData and build new defaults from a fresh template reference
            formData = {}
            var tpl = (addDialog.template) ? JSON.parse(JSON.stringify(addDialog.template)) : { fields: [] }

            if (tpl && tpl.fields) {
                for (var i=0; i<tpl.fields.length; ++i) {
                    var f = tpl.fields[i]
                    if (f["default"] !== undefined) {
                        if (f.type === "int") {
                            var numValue = Number(f["default"]);
                            formData[f.id] = isNaN(numValue) ? 0 : numValue;
                        } else {
                            formData[f.id] = f["default"];
                        }
                    }
                    else if (f.type === "int") {
                        formData[f.id] = 0;
                    }
                    else {
                        formData[f.id] = "";
                    }
                }
            }

            // Ensure Repeater sees a fresh array reference: assign a shallow-copied fields array
            if (!tpl.fields) tpl.fields = []
            tpl.fields = tpl.fields.slice()
            addDialog.template = tpl

            // Force update of the form by incrementing templateVersion
            templateVersion = templateVersion + 1
        }

        onAccepted: {
            if (!addDisplayName.text.trim()) {
                showError("Le nom de la configuration est requis.");
                return;
            }

            var tpl = addDialog.template
            var ok = true
            var missingFields = []
            if (tpl && tpl.fields) {
                for (var i=0;i<tpl.fields.length;++i) {
                    var f = tpl.fields[i]
                    if (f.required && (addDialog.formData[f.id] === undefined ||
                                       addDialog.formData[f.id] === "" ||
                                       (f.type === "int" && isNaN(addDialog.formData[f.id])))) {
                        ok = false
                        missingFields.push(f.label)
                    }
                }
            }

            if (!ok) {
                showError("Les champs suivants sont requis : " + missingFields.join(", "));
                return;
            }

            var json = JSON.stringify(addDialog.formData)

            // Prevent the Connections handler from reacting to internal model changes here
            suppressModelReload = true
            configModel.addConfigurationFromJson(addDialog.templateName, addDialog.template.version || 1, addDisplayName.text.trim(), json)
            // Update types & filters and displayed count
            reloadTypes()
            applyFilters()
            suppressModelReload = false
        }

        function showError(message) {
            errorPopup.message = message;
            errorPopup.open();
        }

        contentItem: ColumnLayout {
            spacing: 16

            RowLayout {
                spacing: 12
                Label {
                    text: "Modèle:"
                    font.pixelSize: 14
                    font.bold: true
                    Layout.preferredWidth: 80
                }
                ComboBox {
                    id: tplCombo
                    model: templateManager.templates()
                    Layout.fillWidth: true
                    // use currentText change to be robust with programmatic changes
                    onCurrentTextChanged: {
                        addDialog.templateName = currentText
                        addDialog.template = JSON.parse(JSON.stringify(templateManager.getTemplate(addDialog.templateName)))
                        addDialog.prepareNew()
                    }
                    Component.onCompleted: {
                        if (model.length > 0) {
                            addDialog.templateName = model[0]
                            addDialog.template = JSON.parse(JSON.stringify(templateManager.getTemplate(addDialog.templateName)))
                        }
                    }
                }
            }

            TextField {
                id: addDisplayName
                placeholderText: "Nom de la configuration"
                Layout.fillWidth: true
                selectByMouse: true
            }

            Label {
                text: "Champs de configuration"
                font.pixelSize: 16
                font.bold: true
                topPadding: 10
            }

            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                ScrollBar.vertical.policy: ScrollBar.AlwaysOn

                ColumnLayout {
                    width: parent.width
                    spacing: 12

                    Repeater {
                        // use a copied array to force Repeater to recreate delegates each time
                        model: (addDialog.template && addDialog.template.fields) ? addDialog.template.fields.slice() : []
                        property int triggerUpdate: addDialog.templateVersion

                        delegate: RowLayout {
                            spacing: 12
                            property var fieldDef: modelData
                            Layout.fillWidth: true

                            Label {
                                text: fieldDef.label + (fieldDef.required ? " *" : "") + ":"
                                Layout.preferredWidth: 140
                                wrapMode: Text.Wrap
                            }

                            TextField {
                                visible: fieldDef.type === "string" || fieldDef.type === undefined
                                Layout.fillWidth: true
                                // Use a binding so the text updates whenever formData[fieldDef.id] changes
                                text: (addDialog.formData[fieldDef.id] !== undefined) ? String(addDialog.formData[fieldDef.id]) : ""
                                onTextChanged: addDialog.formData[fieldDef.id] = text
                                placeholderText: fieldDef.placeholder ? fieldDef.placeholder : ""
                                selectByMouse: true
                            }

                            SpinBox {
                                visible: fieldDef.type === "int"
                                from: fieldDef.min !== undefined ? fieldDef.min : -2147483648
                                to: fieldDef.max !== undefined ? fieldDef.max : 2147483647
                                stepSize: fieldDef.step !== undefined ? fieldDef.step : 1
                                value: {
                                    if (addDialog.formData[fieldDef.id] !== undefined) {
                                        var numValue = Number(addDialog.formData[fieldDef.id]);
                                        return isNaN(numValue) ? 0 : numValue;
                                    }
                                    if (fieldDef.default !== undefined) {
                                        var numDefault = Number(fieldDef.default);
                                        return isNaN(numDefault) ? 0 : numDefault;
                                    }
                                    return 0;
                                }
                                onValueModified: addDialog.formData[fieldDef.id] = value
                                Layout.fillWidth: true

                                onValueChanged: {
                                    if (value < from) value = from;
                                    if (value > to) value = to;
                                }
                            }

                            // Basic boolean switch
                            Switch {
                                visible: fieldDef.type === "bool"
                                checked: (addDialog.formData[fieldDef.id] !== undefined) ? Boolean(addDialog.formData[fieldDef.id]) : Boolean(fieldDef.default)
                                onCheckedChanged: addDialog.formData[fieldDef.id] = checked
                            }
                        }
                    }
                }
            }
        }
    }

    // Dialogue de modification de configuration
    Dialog {
        id: editDialog
        modal: true
        width: 600
        height: 700
        x: (window.width - width) / 2
        y: (window.height - height) / 2
        title: "Modifier la Configuration"
        standardButtons: Dialog.Cancel | Dialog.Ok

        Material.background: cardColor
        Material.foreground: textColor
        Material.elevation: 8

        property int editIndex: -1
        property string templateName: ""
        property var template: ({})
        property var formData: ({})
        property int templateVersion: 0  // Nouvelle propriété pour forcer la mise à jour

        // Properties for dragging
        property point startDragPos
        property bool dragging: false

        // Custom header for dragging
        header: Rectangle {
            height: 40
            color: Qt.darker(cardColor, 1.2)

            Label {
                text: editDialog.title
                color: textColor
                font.bold: true
                anchors.centerIn: parent
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.SizeAllCursor
                onPressed: {
                    editDialog.startDragPos = Qt.point(mouseX, mouseY)
                    editDialog.dragging = true
                }
                onPositionChanged: {
                    if (editDialog.dragging) {
                        editDialog.x += mouseX - editDialog.startDragPos.x
                        editDialog.y += mouseY - editDialog.startDragPos.y
                    }
                }
                onReleased: editDialog.dragging = false
            }
        }

        function openFor(rowIndex, typeName, displayName, dataJson) {
            editIndex = rowIndex
            templateName = typeName
            // deep clone to avoid mutating the templateManager's instance
            template = JSON.parse(JSON.stringify(templateManager.getTemplate(templateName)))
            try {
                var parsed = dataJson && dataJson.length ? JSON.parse(dataJson) : {}
            } catch(e) {
                console.warn("JSON invalide dans les données:", e)
                parsed = {}
            }
            formData = {}
            if (template && template.fields) {
                for (var i=0;i<template.fields.length;++i) {
                    var f = template.fields[i]
                    if (parsed[f.id] !== undefined) {
                        if (f.type === "int") {
                            var numValue = Number(parsed[f.id]);
                            formData[f.id] = isNaN(numValue) ? 0 : numValue;
                        } else if (f.type === "bool") {
                            formData[f.id] = Boolean(parsed[f.id])
                        } else {
                            formData[f.id] = parsed[f.id];
                        }
                    }
                    else if (f["default"] !== undefined) {
                        if (f.type === "int") {
                            var numDefault = Number(f["default"]);
                            formData[f.id] = isNaN(numDefault) ? 0 : numDefault;
                        } else if (f.type === "bool") {
                            formData[f.id] = Boolean(f["default"])
                        } else {
                            formData[f.id] = f["default"];
                        }
                    }
                    else if (f.type === "int") {
                        formData[f.id] = 0;
                    }
                    else if (f.type === "bool") {
                        formData[f.id] = false;
                    }
                    else {
                        formData[f.id] = "";
                    }
                }
            }
            editDisplayName.text = displayName

            // Ensure fields array is a fresh reference to force Repeater rebuild
            if (!template.fields) template.fields = []
            template.fields = template.fields.slice()
            templateVersion = templateVersion + 1
            open()
        }

        onAccepted: {
            if (!editDisplayName.text.trim()) {
                showError("Le nom de la configuration est requis.");
                return;
            }

            var tpl = editDialog.template
            var ok = true
            var missingFields = []
            if (tpl && tpl.fields) {
                for (var i=0;i<tpl.fields.length;++i) {
                    var f = tpl.fields[i]
                    if (f.required && (editDialog.formData[f.id] === undefined ||
                                       editDialog.formData[f.id] === "" ||
                                       (f.type === "int" && isNaN(editDialog.formData[f.id])))) {
                        ok = false
                        missingFields.push(f.label)
                    }
                }
            }

            if (!ok) {
                showError("Les champs suivants sont requis : " + missingFields.join(", "));
                return;
            }

            var json = JSON.stringify(editDialog.formData)

            // Guard around internal model changes
            suppressModelReload = true
            configModel.updateConfigurationFromJson(editDialog.editIndex, json)
            configModel.setData(configModel.index(editDialog.editIndex, 3), editDisplayName.text)
            configModel.submitAll()
            // ensure types refreshed and filters applied
            reloadTypes()
            applyFilters()
            suppressModelReload = false
        }

        function showError(message) {
            errorPopup.message = message;
            errorPopup.open();
        }

        contentItem: ColumnLayout {
            spacing: 16

            RowLayout {
                spacing: 12
                Label {
                    text: "Modèle:"
                    font.pixelSize: 14
                    font.bold: true
                    Layout.preferredWidth: 80
                }
                Label {
                    text: editDialog.templateName ? editDialog.templateName : "(aucun)"
                    Layout.fillWidth: true
                }
            }

            TextField {
                id: editDisplayName
                placeholderText: "Nom de la configuration"
                Layout.fillWidth: true
                selectByMouse: true
            }

            Label {
                text: "Champs de configuration"
                font.pixelSize: 16
                font.bold: true
                topPadding: 10
            }

            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                ScrollBar.vertical.policy: ScrollBar.AlwaysOn

                ColumnLayout {
                    width: parent.width
                    spacing: 12

                    Repeater {
                        model: (editDialog.template && editDialog.template.fields) ? editDialog.template.fields.slice() : []
                        property int triggerUpdate: editDialog.templateVersion

                        delegate: RowLayout {
                            spacing: 12
                            property var fieldDef: modelData
                            Layout.fillWidth: true

                            Label {
                                text: fieldDef.label + (fieldDef.required ? " *" : "") + ":"
                                Layout.preferredWidth: 140
                                wrapMode: Text.Wrap
                            }

                            TextField {
                                visible: fieldDef.type === "string" || fieldDef.type === undefined
                                Layout.fillWidth: true
                                text: editDialog.formData[fieldDef.id] !== undefined ? String(editDialog.formData[fieldDef.id]) : ""
                                onTextChanged: editDialog.formData[fieldDef.id] = text
                                selectByMouse: true
                            }

                            SpinBox {
                                visible: fieldDef.type === "int"
                                from: fieldDef.min !== undefined ? fieldDef.min : -2147483648
                                to: fieldDef.max !== undefined ? fieldDef.max : 2147483647
                                stepSize: fieldDef.step !== undefined ? fieldDef.step : 1
                                value: {
                                    if (editDialog.formData[fieldDef.id] !== undefined) {
                                        var numValue = Number(editDialog.formData[fieldDef.id]);
                                        return isNaN(numValue) ? 0 : numValue;
                                    }
                                    if (fieldDef.default !== undefined) {
                                        var numDefault = Number(fieldDef.default);
                                        return isNaN(numDefault) ? 0 : numDefault;
                                    }
                                    return 0;
                                }
                                onValueModified: editDialog.formData[fieldDef.id] = value
                                Layout.fillWidth: true

                                onValueChanged: {
                                    if (value < from) value = from;
                                    if (value > to) value = to;
                                }
                            }

                            Switch {
                                visible: fieldDef.type === "bool"
                                checked: (editDialog.formData[fieldDef.id] !== undefined) ? Boolean(editDialog.formData[fieldDef.id]) : Boolean(fieldDef.default)
                                onCheckedChanged: editDialog.formData[fieldDef.id] = checked
                            }
                        }
                    }
                }
            }
        }
    }

    // Dialogue de confirmation de suppression
    Dialog {
        id: confirmDialog
        modal: true
        width: 400
        x: (window.width - width) / 2
        y: (window.height - height) / 2
        title: "Confirmation de suppression"
        standardButtons: Dialog.Cancel | Dialog.Yes

        Material.background: cardColor
        Material.foreground: textColor
        Material.elevation: 8

        property string confirmText: ""

        // Properties for dragging
        property point startDragPos
        property bool dragging: false

        // Custom header for dragging
        header: Rectangle {
            height: 40
            color: Qt.darker(cardColor, 1.2)

            Label {
                text: confirmDialog.title
                color: textColor
                font.bold: true
                anchors.centerIn: parent
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.SizeAllCursor
                onPressed: {
                    confirmDialog.startDragPos = Qt.point(mouseX, mouseY)
                    confirmDialog.dragging = true
                }
                onPositionChanged: {
                    if (confirmDialog.dragging) {
                        confirmDialog.x += mouseX - confirmDialog.startDragPos.x
                        confirmDialog.y += mouseY - confirmDialog.startDragPos.y
                    }
                }
                onReleased: confirmDialog.dragging = false
            }
        }

        onAccepted: {
            if (deleteIndex >= 0) {
                suppressModelReload = true
                configModel.removeConfiguration(deleteIndex)
                // removeConfiguration already calls select()/submit; now refresh UI
                reloadTypes()
                applyFilters()
                suppressModelReload = false
                deleteIndex = -1
            }
        }

        contentItem: ColumnLayout {
            spacing: 16

            Label {
                text: "⚠️"
                font.pixelSize: 32
                Layout.alignment: Qt.AlignHCenter
            }

            Label {
                text: confirmDialog.confirmText
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
            }

            Label {
                text: "Cette action est irréversible."
                wrapMode: Text.WordWrap
                color: subtleTextColor
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
            }
        }
    }

    // Popup d'erreur
    Popup {
        id: errorPopup
        x: (window.width - width) / 2
        y: (window.height - height) / 2
        width: 400
        height: 150
        modal: true
        focus: true
        closePolicy: Popup.CloseOnEescape | Popup.CloseOnPressOutside

        property string message: ""

        Material.background: cardColor
        Material.elevation: 8

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 16

            Label {
                text: "Erreur"
                font.pixelSize: 18
                font.bold: true
                color: dangerColor
                Layout.alignment: Qt.AlignHCenter
            }

            Label {
                text: errorPopup.message
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
            }

            Button {
                text: "OK"
                Layout.alignment: Qt.AlignHCenter
                onClicked: errorPopup.close()
            }
        }
    }

    // Fonction pour appliquer les filtres
    function applyFilters() {
        var filter = ""

        // Build type IN (...) from selectedTypes
        if (selectedTypes && selectedTypes.length > 0) {
            var esc = []
            for (var i=0; i<selectedTypes.length; ++i) {
                // escape single quotes
                esc.push("'" + selectedTypes[i].replace(/'/g, "''") + "'")
            }
            filter += "type IN (" + esc.join(",") + ")"
        } else {
            // If no types selected, show nothing (user explicitly deselected all)
            filter += "1=0"
        }

        // Search text (case-insensitive for SQLite)
        if (currentSearchText && currentSearchText.length > 0) {
            var escaped = currentSearchText.replace(/'/g, "''").toLowerCase()
            if (filter) filter += " AND "
            filter += "LOWER(name) LIKE '%" + escaped + "%'"
        }

        console.log("DEBUG: applying filter ->", filter)
        // suppress modelReload while we intentionally change the model filter
        suppressModelReload = true
        configModel.setFilter(filter)
        // IMPORTANT : forcer la sélection pour que rowCount() soit à jour
        if (typeof configModel.select === "function") {
            configModel.select()
        }
        // update displayed count after select completed
        displayedCount = configModel.rowCount()
        suppressModelReload = false

        console.log("DEBUG: displayedCount updated to", displayedCount)
    }

    // Fill availableTypes on startup and select all by default
    Component.onCompleted: {
        suppressModelReload = true
        reloadTypes()
        applyFilters()
        // ensure displayedCount initialized (applyFilters already sets it)
        displayedCount = configModel.rowCount()
        suppressModelReload = false
    }

    // Listen to model signals — automatically reload types and reapply filters when model changes
    Connections {
        target: configModel
        onRowsInserted: {
            if (suppressModelReload) return
            console.log("DEBUG: onRowsInserted -> reload types")
            reloadTypes(); applyFilters();
        }
        onRowsRemoved: {
            if (suppressModelReload) return
            console.log("DEBUG: onRowsRemoved -> reload types")
            reloadTypes(); applyFilters();
        }
        onModelReset: {
            if (suppressModelReload) return
            console.log("DEBUG: onModelReset -> reload types")
            reloadTypes(); applyFilters();
        }
    }
}
