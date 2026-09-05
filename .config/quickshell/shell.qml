import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.I3
import Quickshell.Services.Pipewire
import Quickshell.Bluetooth

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

    // Track default audio sink for volume controls
    PwObjectTracker {
        objects: [ Pipewire.defaultAudioSink ]
    }

    readonly property var audioSink: Pipewire.defaultAudioSink
    readonly property var audio: audioSink ? audioSink.audio : null

    // Bluetooth properties
    readonly property var btAdapter: Bluetooth.defaultAdapter
    readonly property bool btEnabled: btAdapter ? btAdapter.enabled : false
    readonly property var btConnectedDevice: {
        if (!Bluetooth.devices) return null;
        for (var i = 0; i < Bluetooth.devices.values.length; i++) {
            var dev = Bluetooth.devices.values[i];
            if (dev && dev.connected) return dev;
        }
        return null;
    }

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
                        font.family: "JetBrainsMono Nerd Font"
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
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 13
        }

        // RIGHT: Controls, Clock, and Power
        Row {
            Layout.alignment: Qt.AlignRight
            spacing: 10

            // Volume Control Button
            Rectangle {
                id: volButton
                anchors.verticalCenter: parent.verticalCenter
                height: 24
                width: volRow.implicitWidth + 16
                radius: 5
                color: volMouseArea.containsMouse ? "#45475a" : "#313244"

                Row {
                    id: volRow
                    anchors.centerIn: parent
                    spacing: 6

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: {
                            if (!bar.audio) return "󰝟";
                            if (bar.audio.muted) return "󰝟";
                            var pct = Math.round(bar.audio.volume * 100);
                            if (pct >= 66) return "󰕾";
                            if (pct >= 33) return "󰖀";
                            return "󰕿";
                        }
                        color: (bar.audio && bar.audio.muted) ? "#f38ba8" : "#89b4fa"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 13
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: {
                            if (!bar.audio) return "0%";
                            if (bar.audio.muted) return "Muted";
                            return Math.round(bar.audio.volume * 100) + "%";
                        }
                        color: (bar.audio && bar.audio.muted) ? "#f38ba8" : "#cdd6f4"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 13
                        font.bold: true
                    }
                }

                MouseArea {
                    id: volMouseArea
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    hoverEnabled: true

                    onClicked: mouse => {
                        if (!bar.audio) return;
                        if (mouse.button === Qt.LeftButton) {
                            bar.audio.muted = !bar.audio.muted;
                        } else if (mouse.button === Qt.RightButton) {
                            I3.dispatch("exec pavucontrol");
                        }
                    }

                    onWheel: wheel => {
                        if (!bar.audio) return;
                        if (wheel.angleDelta.y > 0) {
                            var newVol = Math.min(1.0, (Math.round(bar.audio.volume * 100) + 5) / 100);
                            bar.audio.volume = newVol;
                            if (bar.audio.muted) bar.audio.muted = false;
                        } else if (wheel.angleDelta.y < 0) {
                            var newVol = Math.max(0.0, (Math.round(bar.audio.volume * 100) - 5) / 100);
                            bar.audio.volume = newVol;
                        }
                    }
                }
            }

            // Bluetooth Control Button
            Rectangle {
                id: btButton
                anchors.verticalCenter: parent.verticalCenter
                height: 24
                width: btRow.implicitWidth + 16
                radius: 5
                color: btMouseArea.containsMouse ? "#45475a" : "#313244"

                Row {
                    id: btRow
                    anchors.centerIn: parent
                    spacing: 6

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: {
                            if (!bar.btAdapter || !bar.btEnabled) return "󰂲";
                            if (bar.btConnectedDevice) return "󰂱";
                            return "󰂯";
                        }
                        color: (!bar.btAdapter || !bar.btEnabled) ? "#6c7086" : (bar.btConnectedDevice ? "#a6e3a1" : "#89b4fa")
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 13
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: {
                            if (!bar.btAdapter || !bar.btEnabled) return "Off";
                            if (bar.btConnectedDevice) return bar.btConnectedDevice.name || "Connected";
                            return "On";
                        }
                        color: (!bar.btAdapter || !bar.btEnabled) ? "#6c7086" : (bar.btConnectedDevice ? "#a6e3a1" : "#cdd6f4")
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 13
                        font.bold: true
                        elide: Text.ElideRight
                    }
                }

                MouseArea {
                    id: btMouseArea
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    hoverEnabled: true

                    onClicked: mouse => {
                        if (mouse.button === Qt.LeftButton) {
                            if (bar.btAdapter) {
                                bar.btAdapter.enabled = !bar.btAdapter.enabled;
                            }
                        } else if (mouse.button === Qt.RightButton) {
                            I3.dispatch("exec which blueman-manager >/dev/null 2>&1 && blueman-manager || env XDG_CURRENT_DESKTOP=GNOME gnome-control-center bluetooth");
                        }
                    }
                }
            }

            // System Clock
            Text {
                id: clockText
                anchors.verticalCenter: parent.verticalCenter
                color: "#cdd6f4"
                font.family: "JetBrainsMono Nerd Font"
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

            // Power Button
            Rectangle {
                id: pwrButton
                anchors.verticalCenter: parent.verticalCenter
                width: 26
                height: 24
                radius: 5
                color: pwrMouseArea.containsMouse ? "#f38ba8" : "#313244"

                Text {
                    anchors.centerIn: parent
                    text: ""
                    color: pwrMouseArea.containsMouse ? "#11111b" : "#f38ba8"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 13
                    font.bold: true
                }

                MouseArea {
                    id: pwrMouseArea
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    hoverEnabled: true

                    onClicked: mouse => {
                        if (mouse.button === Qt.LeftButton) {
                            I3.dispatch("exec pkill swaynag || swaynag -t warning -m 'Power Menu' -Z 'Lock' 'swaylock -f' -Z 'Suspend' 'systemctl suspend' -Z 'Hibernate' 'systemctl hibernate' -Z 'Reboot' 'systemctl reboot' -Z 'Shutdown' 'systemctl poweroff'");
                        } else if (mouse.button === Qt.RightButton) {
                            I3.dispatch("exec swaylock");
                        }
                    }
                }
            }
        }
    }
}
