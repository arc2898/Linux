import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "palette.js" as Theme

ShellRoot {
    id: shell
    property var moods: [Theme.palettes.voidpulse, Theme.palettes.phosphor, Theme.palettes.ultraviolet, Theme.palettes.toxicpetal]
    property int moodIndex: 0
    property var mood: moods[moodIndex]
    property bool deckOpen: false
    property bool glass: true
    property bool glow: true
    property bool scanlines: true
    property bool angular: false
    property bool compact: false
    property bool bottomDock: false
    property bool showWorkspaces: true
    property bool use24Hour: true
    property bool showSeconds: false
    property real scaleFactor: 1.0
    property date now: new Date()

    Timer { interval: shell.showSeconds ? 1000 : 15000; running: true; repeat: true; onTriggered: shell.now = new Date() }

    function launch(command) { Quickshell.execDetached(["sh", "-lc", command]) }
    function terminal(command) {
        launch("if command -v kitty >/dev/null 2>&1; then exec kitty --title 'EVERLUMEN // UPLINK' sh -lc " + JSON.stringify(command) +
               "; elif command -v foot >/dev/null 2>&1; then exec foot -T 'EVERLUMEN // UPLINK' -e sh -lc " + JSON.stringify(command) +
               "; elif command -v alacritty >/dev/null 2>&1; then exec alacritty -t 'EVERLUMEN // UPLINK' -e sh -lc " + JSON.stringify(command) +
               "; else notify-send 'EVERLUMEN' 'Install Kitty, Foot, or Alacritty.' 2>/dev/null || true; fi")
    }
    function upm() {
        terminal("export PATH=\"$HOME/.local/bin:$HOME/.nix-profile/bin:$PATH\"; printf '\\033[38;2;59;247;238m EVERLUMEN // PACKAGE UPLINK\\033[0m\\n'; if command -v everlumen-upm >/dev/null 2>&1; then everlumen-upm -h; elif command -v upm >/dev/null 2>&1; then upm -h; else echo 'UPM missing. Run ./install.sh --bootstrap-upm or visit https://github.com/arc2898/Universal-Package-Manager'; fi")
    }
    function apps() {
        launch("RASI=\"$HOME/.local/share/everlumen/applications/rofi/everlumen.rasi\"; if command -v rofi >/dev/null 2>&1; then exec rofi -show drun -theme \"$RASI\"; elif command -v fuzzel >/dev/null 2>&1; then exec fuzzel; elif command -v wofi >/dev/null 2>&1; then exec wofi --show drun; else notify-send 'EVERLUMEN' 'Install Rofi, Fuzzel or Wofi.' 2>/dev/null || true; fi")
    }

    PanelWindow {
        id: hud
        anchors { top: !shell.bottomDock; bottom: shell.bottomDock; left: true; right: true }
        margins { top: shell.bottomDock ? 0 : 10; bottom: shell.bottomDock ? 10 : 0; left: 12; right: 12 }
        implicitHeight: shell.compact ? 54 : 66
        exclusiveZone: shell.compact ? 60 : 72
        color: "transparent"
        aboveWindows: true
        Rectangle {
            anchors.fill: parent
            radius: shell.angular ? 7 : 20
            color: shell.glass ? "#e9080811" : shell.mood.background
            border.width: 1
            border.color: shell.glow ? shell.mood.cyan : shell.mood.line
            clip: true
            Rectangle {
                x: 0; y: 0; width: parent.width * .48; height: 2
                gradient: Gradient {
                    GradientStop { position: 0; color: shell.mood.cyan }
                    GradientStop { position: .55; color: shell.mood.violet }
                    GradientStop { position: 1; color: shell.mood.pink }
                }
                opacity: shell.glow ? 1 : .3
            }
            Repeater {
                model: shell.scanlines ? 8 : 0
                delegate: Rectangle {
                    required property int index
                    x: 100 + index * 132; y: 0; width: 1; height: parent.height
                    color: shell.mood.cyan; opacity: .035
                }
            }
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: shell.compact ? 12 : 18
                anchors.rightMargin: shell.compact ? 12 : 18
                spacing: 11
                Rectangle {
                    Layout.preferredWidth: shell.compact ? 30 : 38
                    Layout.preferredHeight: shell.compact ? 30 : 38
                    radius: shell.angular ? 5 : width / 2
                    color: shell.mood.raised; border.width: 1; border.color: shell.mood.pink
                    Text { anchors.centerIn: parent; text: "✳"; color: shell.mood.acid; font.pixelSize: 23 }
                    MouseArea { anchors.fill: parent; onClicked: shell.deckOpen = !shell.deckOpen; cursorShape: Qt.PointingHandCursor }
                }
                ColumnLayout {
                    spacing: 1
                    Text { text: "EVERLUMEN"; color: shell.mood.text; font.family: "monospace"; font.bold: true; font.pixelSize: (shell.compact ? 10 : 12) * shell.scaleFactor; font.letterSpacing: 2 }
                    Text { visible: !shell.compact; text: "NEUROGLASS // SIGNAL GARDEN"; color: shell.mood.cyan; font.family: "monospace"; font.pixelSize: 8 * shell.scaleFactor; font.letterSpacing: .8 }
                }
                Rectangle { Layout.preferredWidth: 1; Layout.preferredHeight: 30; color: shell.mood.line }
                RowLayout {
                    visible: shell.showWorkspaces
                    Layout.fillWidth: true
                    spacing: 5
                    Repeater {
                        model: Hyprland.workspaces
                        delegate: Rectangle {
                            required property var modelData
                            Layout.preferredWidth: modelData.active ? 42 : 34
                            Layout.preferredHeight: shell.compact ? 27 : 32
                            radius: shell.angular ? 4 : 10
                            color: modelData.active ? shell.mood.cyan : shell.mood.raised
                            border.width: modelData.focused ? 2 : 1
                            border.color: modelData.focused ? shell.mood.acid : shell.mood.line
                            Text {
                                anchors.centerIn: parent
                                text: modelData.name && modelData.name.length ? modelData.name : String(modelData.id)
                                color: modelData.active ? shell.mood.background : shell.mood.text
                                font.family: "monospace"; font.bold: modelData.active; font.pixelSize: 10 * shell.scaleFactor
                            }
                            MouseArea { anchors.fill: parent; onClicked: modelData.activate(); cursorShape: Qt.PointingHandCursor }
                        }
                    }
                    Text { visible: Hyprland.workspaces.length === 0; text: "NO SIGNAL"; color: shell.mood.muted; font.family: "monospace"; font.pixelSize: 9 }
                }
                Item { Layout.fillWidth: true; visible: !shell.showWorkspaces }
                Repeater {
                    model: [
                        { label: "UPM", accent: shell.mood.cyan, action: 0 },
                        { label: ">_", accent: shell.mood.violet, action: 1 },
                        { label: "⌕", accent: shell.mood.pink, action: 2 }
                    ]
                    delegate: Rectangle {
                        required property var modelData
                        Layout.preferredWidth: modelData.action === 0 ? 56 : 42
                        Layout.preferredHeight: shell.compact ? 28 : 34
                        radius: shell.angular ? 4 : 10
                        color: shell.mood.raised; border.width: 1; border.color: modelData.accent
                        Text { anchors.centerIn: parent; text: modelData.label; color: shell.mood.text; font.family: "monospace"; font.bold: true; font.pixelSize: 11 }
                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: { if (modelData.action === 0) shell.upm(); else if (modelData.action === 1) shell.terminal("exec sh"); else shell.apps() }
                        }
                    }
                }
                Rectangle {
                    Layout.preferredWidth: 92; Layout.preferredHeight: 39
                    radius: shell.angular ? 4 : 10; color: "transparent"; border.width: 1; border.color: shell.mood.line
                    Column {
                        anchors.centerIn: parent; spacing: 1
                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: Qt.formatTime(shell.now, shell.use24Hour ? (shell.showSeconds ? "HH:mm:ss" : "HH:mm") : (shell.showSeconds ? "h:mm:ss AP" : "h:mm AP")); color: shell.mood.text; font.family: "monospace"; font.bold: true; font.pixelSize: 12 * shell.scaleFactor }
                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: Qt.formatDate(shell.now, "ddd / dd MMM").toUpperCase(); color: shell.mood.muted; font.family: "monospace"; font.pixelSize: 8 }
                    }
                }
                Rectangle {
                    Layout.preferredWidth: 38; Layout.preferredHeight: 38
                    radius: shell.angular ? 4 : 10; color: shell.mood.pink
                    Text { anchors.centerIn: parent; text: shell.deckOpen ? "×" : "≡"; color: shell.mood.background; font.pixelSize: 20 }
                    MouseArea { anchors.fill: parent; onClicked: shell.deckOpen = !shell.deckOpen; cursorShape: Qt.PointingHandCursor }
                }
            }
        }
    }

    PanelWindow {
        id: lab
        visible: shell.deckOpen
        anchors { top: true; right: true }
        margins { top: shell.bottomDock ? 12 : 88; right: 14; bottom: 14; left: 0 }
        implicitWidth: 460
        implicitHeight: 650
        color: "transparent"
        exclusiveZone: 0
        aboveWindows: true
        Rectangle {
            anchors.fill: parent
            radius: shell.angular ? 8 : 22
            color: shell.glass ? "#f20a0c18" : shell.mood.background
            border.width: 1; border.color: shell.glow ? shell.mood.pink : shell.mood.line
            clip: true
            Rectangle { x: 0; y: 0; width: parent.width; height: 2; color: shell.mood.cyan }
            ColumnLayout {
                anchors.fill: parent; anchors.margins: 16; spacing: 8
                RowLayout {
                    Layout.fillWidth: true
                    ColumnLayout {
                        spacing: 2
                        Text { text: "NEUROGLASS / LAB"; color: shell.mood.text; font.family: "monospace"; font.bold: true; font.pixelSize: 15; font.letterSpacing: 1.1 }
                        Text { text: "CONFIGURE YOUR SIGNAL"; color: shell.mood.cyan; font.family: "monospace"; font.pixelSize: 8; font.letterSpacing: .7 }
                    }
                    Item { Layout.fillWidth: true }
                    Text { text: "● LIVE"; color: shell.mood.acid; font.family: "monospace"; font.pixelSize: 9 }
                }
                Rectangle { Layout.fillWidth: true; height: 1; color: shell.mood.line }
                Text { text: "01 // CHROMATIC REALITY"; color: shell.mood.muted; font.family: "monospace"; font.pixelSize: 9; font.letterSpacing: 1 }
                GridLayout {
                    Layout.fillWidth: true; columns: 2; rowSpacing: 6; columnSpacing: 6
                    Repeater {
                        model: shell.moods
                        delegate: Rectangle {
                            required property var modelData
                            required property int index
                            Layout.fillWidth: true; Layout.preferredHeight: 43
                            radius: shell.angular ? 4 : 11
                            color: modelData.raised; border.width: shell.moodIndex === index ? 2 : 1
                            border.color: shell.moodIndex === index ? modelData.acid : modelData.line
                            RowLayout {
                                anchors.fill: parent; anchors.leftMargin: 9; spacing: 6
                                Rectangle { Layout.preferredWidth: 6; Layout.preferredHeight: 24; radius: 3; color: modelData.cyan }
                                Rectangle { Layout.preferredWidth: 6; Layout.preferredHeight: 18; radius: 3; color: modelData.pink }
                                Rectangle { Layout.preferredWidth: 6; Layout.preferredHeight: 12; radius: 3; color: modelData.acid }
                                Text { Layout.fillWidth: true; text: modelData.name; color: modelData.text; font.family: "monospace"; font.pixelSize: 8; font.bold: true }
                            }
                            MouseArea { anchors.fill: parent; onClicked: shell.moodIndex = index; cursorShape: Qt.PointingHandCursor }
                        }
                    }
                }
                Text { text: "02 // OPTICS & GEOMETRY"; color: shell.mood.muted; font.family: "monospace"; font.pixelSize: 9; font.letterSpacing: 1 }
                GridLayout {
                    Layout.fillWidth: true; columns: 2; rowSpacing: 6; columnSpacing: 6
                    Repeater {
                        model: [
                            { label: "GLASS", key: "glass" }, { label: "NEON GLOW", key: "glow" },
                            { label: "SCANLINES", key: "scanlines" }, { label: "ANGULAR", key: "angular" },
                            { label: "COMPACT", key: "compact" }, { label: "WORKSPACES", key: "showWorkspaces" }
                        ]
                        delegate: Rectangle {
                            required property var modelData
                            Layout.fillWidth: true; Layout.preferredHeight: 36
                            radius: shell.angular ? 4 : 9
                            color: shell[modelData.key] ? shell.mood.raised : shell.mood.background
                            border.width: 1; border.color: shell[modelData.key] ? shell.mood.cyan : shell.mood.line
                            RowLayout {
                                anchors.fill: parent; anchors.leftMargin: 9; anchors.rightMargin: 7; spacing: 5
                                Rectangle { Layout.preferredWidth: 6; Layout.preferredHeight: 6; radius: 3; color: shell[modelData.key] ? shell.mood.acid : shell.mood.muted }
                                Text { Layout.fillWidth: true; text: modelData.label; color: shell.mood.text; font.family: "monospace"; font.pixelSize: 8 }
                                Text { text: shell[modelData.key] ? "ON" : "OFF"; color: shell[modelData.key] ? shell.mood.cyan : shell.mood.muted; font.family: "monospace"; font.pixelSize: 8 }
                            }
                            MouseArea {
                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (modelData.key === "glass") shell.glass = !shell.glass
                                    else if (modelData.key === "glow") shell.glow = !shell.glow
                                    else if (modelData.key === "scanlines") shell.scanlines = !shell.scanlines
                                    else if (modelData.key === "angular") shell.angular = !shell.angular
                                    else if (modelData.key === "compact") shell.compact = !shell.compact
                                    else shell.showWorkspaces = !shell.showWorkspaces
                                }
                            }
                        }
                    }
                }
                Text { text: "03 // TIME PROTOCOL"; color: shell.mood.muted; font.family: "monospace"; font.pixelSize: 9; font.letterSpacing: 1 }
                RowLayout {
                    Layout.fillWidth: true; spacing: 6
                    Repeater {
                        model: [
                            { label: shell.use24Hour ? "24-HOUR" : "12-HOUR", key: "clock" },
                            { label: shell.showSeconds ? "SECONDS ON" : "SECONDS OFF", key: "seconds" },
                            { label: shell.bottomDock ? "DOCK: BOTTOM" : "DOCK: TOP", key: "dock" }
                        ]
                        delegate: Rectangle {
                            required property var modelData
                            Layout.fillWidth: true; Layout.preferredHeight: 33
                            radius: shell.angular ? 4 : 9
                            color: shell.mood.raised; border.width: 1; border.color: shell.mood.line
                            Text { anchors.centerIn: parent; text: modelData.label; color: shell.mood.text; font.family: "monospace"; font.pixelSize: 8 }
                            MouseArea {
                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                onClicked: { if (modelData.key === "clock") shell.use24Hour = !shell.use24Hour; else if (modelData.key === "seconds") shell.showSeconds = !shell.showSeconds; else shell.bottomDock = !shell.bottomDock }
                            }
                        }
                    }
                }
                RowLayout {
                    Layout.fillWidth: true; spacing: 7
                    Text { text: "TYPE SCALE"; color: shell.mood.muted; font.family: "monospace"; font.pixelSize: 9 }
                    Item { Layout.fillWidth: true }
                    Rectangle { width: 29; height: 28; radius: 7; color: shell.mood.raised; border.color: shell.mood.line; Text { anchors.centerIn: parent; text: "−"; color: shell.mood.text; font.pixelSize: 16 }; MouseArea { anchors.fill: parent; onClicked: shell.scaleFactor = Math.max(.8, Math.round((shell.scaleFactor - .05) * 100) / 100) } }
                    Text { text: Math.round(shell.scaleFactor * 100) + "%"; color: shell.mood.text; font.family: "monospace"; font.pixelSize: 10 }
                    Rectangle { width: 29; height: 28; radius: 7; color: shell.mood.raised; border.color: shell.mood.line; Text { anchors.centerIn: parent; text: "+"; color: shell.mood.text; font.pixelSize: 16 }; MouseArea { anchors.fill: parent; onClicked: shell.scaleFactor = Math.min(1.3, Math.round((shell.scaleFactor + .05) * 100) / 100) } }
                }
                RowLayout {
                    Layout.fillWidth: true; spacing: 7
                    Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 34; radius: shell.angular ? 4 : 9; color: shell.mood.raised; border.color: shell.mood.cyan; Text { anchors.centerIn: parent; text: "UPM // PACKAGE UPLINK"; color: shell.mood.text; font.family: "monospace"; font.pixelSize: 9 }; MouseArea { anchors.fill: parent; onClicked: shell.upm() } }
                    Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 34; radius: shell.angular ? 4 : 9; color: shell.mood.raised; border.color: shell.mood.pink; Text { anchors.centerIn: parent; text: "CLOSE LAB"; color: shell.mood.text; font.family: "monospace"; font.pixelSize: 9 }; MouseArea { anchors.fill: parent; onClicked: shell.deckOpen = false } }
                }
                Item { Layout.fillHeight: true }
                Text { Layout.fillWidth: true; text: "LOCAL SESSION // RELOAD TO RESET"; color: shell.mood.muted; horizontalAlignment: Text.AlignHCenter; font.family: "monospace"; font.pixelSize: 8 }
            }
        }
    }
}
