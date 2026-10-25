import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland

PanelWindow {
    id: root
    implicitWidth: 86
    anchors { left: true; top: true; bottom: true }
    color: "transparent"

    Rectangle {
        anchors { fill: parent; topMargin: 18; bottomMargin: 18; leftMargin: 12; rightMargin: 4 }
        radius: 28
        color: "#d90b1020"
        border.width: 1
        border.color: "#508fffd8"

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 12

            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                width: 44; height: 44; radius: 18
                color: "#278fffd8"
                border.color: "#b38fffd8"
                Text { anchors.centerIn: parent; text: "✿"; color: "#8fffd8"; font.pixelSize: 25 }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: "#334b6276" }

            Repeater {
                model: Hyprland.workspaces
                delegate: Rectangle {
                    required property var modelData
                    Layout.alignment: Qt.AlignHCenter
                    width: 44; height: 42; radius: 15
                    color: modelData.active ? "#558fffd8" : "#26151c2e"
                    border.width: 1
                    border.color: modelData.active ? "#8fffd8" : "#33455668"
                    Text {
                        anchors.centerIn: parent
                        text: modelData.name
                        color: modelData.active ? "#e8f4f4" : "#9aabc1"
                        font.pixelSize: 13
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: modelData.activate()
                    }
                }
            }

            Item { Layout.fillHeight: true }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: Qt.formatDateTime(new Date(), "hh:mm")
                color: "#e8f4f4"
                font.pixelSize: 12
            }
        }
    }
}
