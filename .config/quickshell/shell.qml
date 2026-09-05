import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.I3

PanelWindow {
    id: bar

    // Dock across the top edge of the screen
    anchors {
        top: true
        left: true
        right: true
    }

    implicitHeight: 34
    color: "#1e1e2e" // Background color (Catppuccin Mocha Base)

    // Layer-shell setup to ensure tiled windows do not overlap
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    // Main 3-column layout: Left, Center, Right
    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12

        // LEFT: Sway Workspaces
        Row {
            Layout.alignment: Qt.AlignLeft
            spacing: 6

            Repeater {
                model: I3.workspaces

                Rectangle {
                    width: 26
                    height: 24
                    radius: 5
                    color: modelData.focused ? "#89b4fa" : "#313244"

                    Text {
                        anchors.centerIn: parent
                        text: modelData.name
                        color: modelData.focused ? "#11111b" : "#cdd6f4"
                        font.bold: modelData.focused
                        font.pixelSize: 13
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: I3.dispatch(`workspace ${modelData.name}`)
                    }
                }
            }
        }

        // CENTER: Focused Window Title
        Text {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignCenter
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            text: I3.focusedWindow ? I3.focusedWindow.title : ""
            color: "#a6adc8"
            font.pixelSize: 13
        }

        // RIGHT: System Clock
        Row {
            Layout.alignment: Qt.AlignRight
            spacing: 8

            Text {
                id: clockText
                color: "#cdd6f4"
                font.pixelSize: 13
                font.bold: true

                Timer {
                    interval: 1000
                    running: true
                    repeat: true
                    triggeredOnStart: true
                    onTriggered: {
                        clockText.text = Qt.formatDateTime(new Date(), "ddd dd MMM  hh:mm:ss")
                    }
                }
            }
        }
    }
}
