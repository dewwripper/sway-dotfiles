import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.I3
import Quickshell.Services.Pipewire
import Quickshell.Bluetooth
import Quickshell.Io

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

    // System resource monitor properties
    property int cpuUsage: 0
    property int memUsage: 0
    property string memUsedGb: "0.0"
    property string memTotalGb: "0.0"
    property var lastCpuIdle: 0
    property var lastCpuTotal: 0
    property bool showRamDetailed: false

    // Resource monitoring process
    Process {
        id: sysProc
        command: ["awk", "/^cpu /{print $0; nextfile} /^MemTotal:/{t=$2} /^MemAvailable:/{a=$2} END{print \"mem\",t,a}", "/proc/stat", "/proc/meminfo"]
        stdout: SplitParser {
            onRead: data => {
                if (!data) return;
                var p = data.trim().split(/\s+/);
                if (p[0] === "cpu") {
                    var user = parseInt(p[1]) || 0;
                    var nice = parseInt(p[2]) || 0;
                    var system = parseInt(p[3]) || 0;
                    var idle = parseInt(p[4]) || 0;
                    var iowait = parseInt(p[5]) || 0;
                    var irq = parseInt(p[6]) || 0;
                    var softirq = parseInt(p[7]) || 0;
                    var steal = parseInt(p[8]) || 0;

                    var idleTime = idle + iowait;
                    var totalTime = user + nice + system + idle + iowait + irq + softirq + steal;

                    if (bar.lastCpuTotal > 0) {
                        var diffTotal = totalTime - bar.lastCpuTotal;
                        var diffIdle = idleTime - bar.lastCpuIdle;
                        if (diffTotal > 0) {
                            var usage = Math.round(100 * (1.0 - diffIdle / diffTotal));
                            bar.cpuUsage = Math.max(0, Math.min(100, usage));
                        }
                    }
                    bar.lastCpuTotal = totalTime;
                    bar.lastCpuIdle = idleTime;
                } else if (p[0] === "mem") {
                    var totalKb = parseInt(p[1]) || 1;
                    var availKb = parseInt(p[2]) || 0;
                    var usedKb = Math.max(0, totalKb - availKb);
                    bar.memUsage = Math.max(0, Math.min(100, Math.round(100 * usedKb / totalKb)));
                    bar.memUsedGb = (usedKb / 1048576).toFixed(1);
                    bar.memTotalGb = (totalKb / 1048576).toFixed(1);
                }
            }
        }
        Component.onCompleted: running = true
    }

    // Fast initial reading for CPU delta
    Timer {
        interval: 400
        running: true
        repeat: false
        onTriggered: {
            if (!sysProc.running) sysProc.running = true;
        }
    }

    // Periodic system stats refresh every 2 seconds
    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: {
            if (!sysProc.running) sysProc.running = true;
        }
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

            // CPU Status Button
            Rectangle {
                id: cpuButton
                anchors.verticalCenter: parent.verticalCenter
                height: 24
                width: cpuRow.implicitWidth + 16
                radius: 5
                color: cpuMouseArea.containsMouse ? "#45475a" : "#313244"

                Row {
                    id: cpuRow
                    anchors.centerIn: parent
                    spacing: 6

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: ""
                        color: bar.cpuUsage >= 80 ? "#f38ba8" : "#fab387"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 13
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: bar.cpuUsage + "%"
                        color: bar.cpuUsage >= 80 ? "#f38ba8" : "#cdd6f4"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 13
                        font.bold: true
                    }
                }

                MouseArea {
                    id: cpuMouseArea
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    hoverEnabled: true

                    onClicked: {
                        I3.dispatch("exec ghostty -e btop");
                    }
                }
            }

            // RAM Status Button
            Rectangle {
                id: ramButton
                anchors.verticalCenter: parent.verticalCenter
                height: 24
                width: ramRow.implicitWidth + 16
                radius: 5
                color: ramMouseArea.containsMouse ? "#45475a" : "#313244"

                Row {
                    id: ramRow
                    anchors.centerIn: parent
                    spacing: 6

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "󰍛"
                        color: bar.memUsage >= 85 ? "#f38ba8" : "#cba6f7"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 13
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: bar.showRamDetailed ? (bar.memUsedGb + "G") : (bar.memUsage + "%")
                        color: bar.memUsage >= 85 ? "#f38ba8" : "#cdd6f4"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 13
                        font.bold: true
                    }
                }

                MouseArea {
                    id: ramMouseArea
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    hoverEnabled: true

                    onClicked: mouse => {
                        if (mouse.button === Qt.LeftButton) {
                            I3.dispatch("exec ghostty -e btop");
                        } else if (mouse.button === Qt.RightButton) {
                            bar.showRamDetailed = !bar.showRamDetailed;
                        }
                    }
                }
            }

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
                            } else {
                                I3.dispatch("exec bluetoothctl power on");
                            }
                        } else if (mouse.button === Qt.RightButton) {
                            I3.dispatch("exec blueman-manager");
                        }
                    }
                }
            }

            // Notification Center Button (SwayNC)
            Rectangle {
                id: notifButton
                anchors.verticalCenter: parent.verticalCenter
                width: 26
                height: 24
                radius: 5
                color: notifMouseArea.containsMouse ? "#45475a" : "#313244"

                Text {
                    anchors.centerIn: parent
                    text: "󰂚"
                    color: notifMouseArea.containsMouse ? "#89b4fa" : "#cdd6f4"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 13
                }

                MouseArea {
                    id: notifMouseArea
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    hoverEnabled: true

                    onClicked: mouse => {
                        if (mouse.button === Qt.LeftButton) {
                            I3.dispatch("exec swaync-client -t -sw");
                        } else if (mouse.button === Qt.RightButton) {
                            I3.dispatch("exec swaync-client -d -sw");
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
                color: (powerMenu.visible || pwrMouseArea.containsMouse) ? "#f38ba8" : "#313244"

                Text {
                    anchors.centerIn: parent
                    text: ""
                    color: (powerMenu.visible || pwrMouseArea.containsMouse) ? "#11111b" : "#f38ba8"
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
                            powerMenu.visible = !powerMenu.visible;
                        } else if (mouse.button === Qt.RightButton) {
                            I3.dispatch("exec swaylock");
                        }
                    }
                }
            }
        }
    }

    // Shutdown / Power Dropdown Menu
    PopupWindow {
        id: powerMenu
        anchor.window: bar
        anchor.item: pwrButton
        anchor.edges: Edges.Bottom | Edges.Right
        anchor.gravity: Edges.Bottom | Edges.Left
        anchor.margins.top: 6
        visible: false

        implicitWidth: 150
        implicitHeight: menuCol.implicitHeight + 12
        color: "transparent"

        onClosed: visible = false

        Rectangle {
            anchors.fill: parent
            radius: 8
            color: "#181825"
            border.color: "#313244"
            border.width: 1

            Column {
                id: menuCol
                anchors.fill: parent
                anchors.margins: 6
                spacing: 3

                Repeater {
                    model: [
                        { icon: "", label: "Lock", cmd: "swaylock", iconColor: "#89b4fa" },
                        { icon: "󰒲", label: "Suspend", cmd: "systemctl suspend", iconColor: "#b4befe" },
                        { icon: "󰒄", label: "Hibernate", cmd: "systemctl hibernate", iconColor: "#fab387" },
                        { icon: "󰜉", label: "Reboot", cmd: "systemctl reboot", iconColor: "#f9e2af" },
                        { icon: "", label: "Shutdown", cmd: "systemctl poweroff", iconColor: "#f38ba8" }
                    ]

                    Rectangle {
                        width: menuCol.width
                        height: 28
                        radius: 5
                        color: itemMouse.containsMouse ? (modelData.label === "Shutdown" ? "#f38ba8" : "#313244") : "transparent"

                        Row {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            spacing: 10

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData.icon
                                color: (itemMouse.containsMouse && modelData.label === "Shutdown") ? "#11111b" : modelData.iconColor
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 13
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData.label
                                color: (itemMouse.containsMouse && modelData.label === "Shutdown") ? "#11111b" : "#cdd6f4"
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 13
                                font.bold: true
                            }
                        }

                        MouseArea {
                            id: itemMouse
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            hoverEnabled: true
                            onClicked: {
                                powerMenu.visible = false;
                                I3.dispatch("exec " + modelData.cmd);
                            }
                        }
                    }
                }
            }
        }
    }
}
