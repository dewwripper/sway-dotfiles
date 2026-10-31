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

    // Input method properties
    property string currentIm: "keyboard-us"
    property bool imAvailable: false
    readonly property bool isVietnamese: currentIm.indexOf("unikey") !== -1 || currentIm.indexOf("bamboo") !== -1

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

    // Input method monitoring process
    Process {
        id: imProc
        // Prints "__none__" when fcitx5 is missing or not running
        command: ["sh", "-c", "fcitx5-remote -n 2>/dev/null || echo __none__"]
        stdout: SplitParser {
            onRead: data => {
                var im = data ? data.trim() : "";
                bar.imAvailable = im !== "" && im !== "__none__";
                if (bar.imAvailable) bar.currentIm = im;
            }
        }
        Component.onCompleted: running = true
    }

    // Toggle between the first (keyboard) and active (Vietnamese) IM in the current group.
    // Refresh the label only after the switch has actually finished.
    Process {
        id: imToggleProc
        command: ["fcitx5-remote", "-t"]
        onExited: {
            if (!imProc.running) imProc.running = true;
        }
    }

    // Toggle the CopyQ window centered on screen. `copyq toggle`/`visible`
    // are unreliable on Wayland (the bar click never focuses CopyQ, and it
    // reports "visible" while sitting on another workspace), so let sway
    // decide: if it's on the focused workspace, stash it in the scratchpad;
    // otherwise pull it to the current workspace, centered and focused.
    // --start-server launches CopyQ if it isn't running.
    Process {
        id: clipToggleProc
        command: ["sh", "-c",
            "c='app_id=\"com.github.hluk.copyq\"'; " +
            "swaymsg \"[$c workspace=__focused__] move to scratchpad\" >/dev/null && exit; " +
            "copyq --start-server show 2>/dev/null; " +
            "for i in 1 2 3 4 5 6 7 8 9 10; do " +
            "swaymsg \"[$c] move to scratchpad, scratchpad show, move position center, focus\" >/dev/null && exit; " +
            "sleep 0.1; done"]
    }

    // Periodic input method status check every 1 second
    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            if (!imProc.running) imProc.running = true;
        }
    }

    // Network properties (NetworkManager via nmcli)
    property bool netWifiEnabled: false
    property string netWifiDevice: ""
    property string netWifiState: ""
    property string netWifiSsid: ""
    property int netWifiSignal: 0
    property bool netEthConnected: false
    property string netEthName: ""
    property var wifiNetworks: []
    property string wifiPendingSsid: ""
    property var _netScratch: ({})
    property var _wifiScratch: ({ saved: [], aps: [] })

    // Split an `nmcli -t` line on unescaped colons, unescaping "\:" and "\\"
    function splitTerse(line) {
        var fields = [], cur = "";
        for (var i = 0; i < line.length; i++) {
            var c = line[i];
            if (c === "\\" && i + 1 < line.length) { cur += line[++i]; }
            else if (c === ":") { fields.push(cur); cur = ""; }
            else cur += c;
        }
        fields.push(cur);
        return fields;
    }

    function wifiIcon(signal) {
        if (signal >= 75) return "󰤨";
        if (signal >= 50) return "󰤥";
        if (signal >= 25) return "󰤢";
        return "󰤟";
    }

    function refreshNet() {
        if (!netProc.running) netProc.running = true;
    }

    function refreshWifiList(rescan) {
        if (wifiListProc.running) return;
        wifiListProc.command = ["sh", "-c",
            "nmcli -t -f NAME,TYPE con show | sed -n 's/:802-11-wireless$//p' | sed 's/^/saved:/'; " +
            "nmcli -t -f IN-USE,SIGNAL,SECURITY,SSID dev wifi list --rescan \"$1\" 2>/dev/null | sed 's/^/ap:/'",
            "sh", rescan ? "yes" : "auto"];
        wifiListProc.running = true;
    }

    function runNetCmd(cmd, ssid) {
        if (netCmdProc.running) return;
        bar.wifiPendingSsid = ssid || "";
        netCmdProc.command = cmd;
        netCmdProc.running = true;
    }

    function activateNetwork(net) {
        if (net.inUse) {
            runNetCmd(["nmcli", "dev", "disconnect", bar.netWifiDevice], net.ssid);
        } else if (net.saved) {
            runNetCmd(["nmcli", "con", "up", "id", net.ssid], net.ssid);
        } else if (!net.secured) {
            runNetCmd(["nmcli", "dev", "wifi", "connect", net.ssid], net.ssid);
        } else {
            // Secured and unknown: ask for the password in nmtui
            netMenu.visible = false;
            Quickshell.execDetached(["ghostty", "-e", "nmtui", "connect", net.ssid]);
        }
    }

    // Network status process
    Process {
        id: netProc
        command: ["sh", "-c",
            "echo \"radio:$(nmcli radio wifi)\"; " +
            "nmcli -t -f DEVICE,TYPE,STATE,CONNECTION dev | sed 's/^/dev:/'; " +
            "nmcli -t -f ACTIVE,SIGNAL,SSID dev wifi list --rescan no 2>/dev/null | grep '^yes:' | sed 's/^/wifi:/'"]
        onStarted: bar._netScratch = { radio: false, wifiDev: "", wifiState: "", ssid: "", signal: 0, eth: false, ethName: "" }
        stdout: SplitParser {
            onRead: data => {
                if (!data) return;
                var f = bar.splitTerse(data.trim());
                var s = bar._netScratch;
                if (f[0] === "radio") {
                    s.radio = f[1] === "enabled";
                } else if (f[0] === "dev") {
                    if (f[2] === "wifi" && !s.wifiDev) {
                        s.wifiDev = f[1];
                        s.wifiState = f[3];
                    } else if (f[2] === "ethernet" && f[3] === "connected" && !s.eth) {
                        s.eth = true;
                        s.ethName = f[4];
                    }
                } else if (f[0] === "wifi") {
                    s.signal = parseInt(f[2]) || 0;
                    s.ssid = f.slice(3).join(":");
                }
            }
        }
        onExited: {
            var s = bar._netScratch;
            bar.netWifiEnabled = s.radio;
            bar.netWifiDevice = s.wifiDev;
            bar.netWifiState = s.wifiState;
            bar.netWifiSsid = s.wifiState === "connected" ? s.ssid : "";
            bar.netWifiSignal = s.signal;
            bar.netEthConnected = s.eth;
            bar.netEthName = s.ethName;
        }
        Component.onCompleted: running = true
    }

    // Available Wi-Fi networks (used by the dropdown)
    Process {
        id: wifiListProc
        onStarted: bar._wifiScratch = { saved: [], aps: [] }
        stdout: SplitParser {
            onRead: data => {
                if (!data) return;
                var f = bar.splitTerse(data);
                if (f[0] === "saved") {
                    bar._wifiScratch.saved.push(f.slice(1).join(":"));
                } else if (f[0] === "ap") {
                    var ssid = f.slice(4).join(":");
                    if (!ssid) return; // hidden network
                    bar._wifiScratch.aps.push({
                        inUse: f[1] === "*",
                        signal: parseInt(f[2]) || 0,
                        secured: f[3] !== "" && f[3] !== "--",
                        ssid: ssid
                    });
                }
            }
        }
        onExited: {
            var saved = bar._wifiScratch.saved;
            var bySsid = {};
            bar._wifiScratch.aps.forEach(ap => {
                var prev = bySsid[ap.ssid];
                if (!prev || ap.inUse || (!prev.inUse && ap.signal > prev.signal)) bySsid[ap.ssid] = ap;
            });
            var list = Object.keys(bySsid).map(k => {
                var ap = bySsid[k];
                ap.saved = saved.indexOf(ap.ssid) !== -1;
                return ap;
            });
            list.sort((a, b) => (b.inUse - a.inUse) || (b.saved - a.saved) || (b.signal - a.signal));
            bar.wifiNetworks = list;
        }
    }

    // Runs connect / disconnect / radio toggle commands
    Process {
        id: netCmdProc
        stderr: StdioCollector { id: netCmdErr }
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) {
                var msg = netCmdErr.text.trim() || "Command failed";
                Quickshell.execDetached(["notify-send", "-a", "Network", "Network", msg]);
            }
            bar.wifiPendingSsid = "";
            bar.refreshNet();
            bar.refreshWifiList(false);
        }
    }

    // Periodic network status check every 5 seconds
    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: bar.refreshNet()
    }

    // Refresh the network list while the dropdown is open
    Timer {
        interval: 5000
        running: netMenu.visible
        repeat: true
        onTriggered: bar.refreshWifiList(false)
    }

    // Twingate properties (twingate CLI)
    property string tgStatus: ""
    property var tgResources: []
    property int tgHiddenCount: 0
    property bool tgIpcStuck: false
    property string tgFilter: ""
    readonly property var tgFiltered: {
        var q = tgFilter.trim().toLowerCase();
        if (!q) return tgResources;
        return tgResources.filter(r => (r.name + " " + r.address + " " + r.alias).toLowerCase().indexOf(q) !== -1);
    }
    property var _tgScratch: ({ list: [], hidden: 0, header: false })
    readonly property bool tgOnline: tgStatus === "online"
    // twingated serves its IPC socket on a single thread and wedges under frequent
    // CLI calls (`twingate status` then prints "unknown"), so status is read from
    // systemd + the sdwan0 tunnel instead, and resources only on demand.
    // A `twingate resources` call that returns nothing means the IPC is wedged.
    readonly property bool tgUnknown: tgOnline && tgIpcStuck
    readonly property bool tgInstalled: tgStatus !== "" && tgStatus !== "__none__"

    function refreshTwingate() {
        if (!tgStatusProc.running) tgStatusProc.running = true;
    }

    function refreshTgResources() {
        if (!tgResProc.running) tgResProc.running = true;
    }

    // Resources whose auth lapsed need `twingate auth <name>` (browser flow)
    function tgNeedsAuth(res) {
        return /required|expired|locked|not auth/i.test(res.auth);
    }

    // start/stop go through sudo, so run them in a terminal for the password prompt
    function tgToggleConnection() {
        twingateMenu.visible = false;
        var cmd = bar.tgUnknown ? "sudo systemctl restart twingate && sleep 3 && twingate status"
            : bar.tgOnline ? "twingate stop" : "twingate start";
        Quickshell.execDetached(["ghostty", "-e", "sh", "-c", cmd + "; echo; read -p 'Press Enter to close' _"]);
    }

    function tgActivateResource(res) {
        if (bar.tgNeedsAuth(res)) {
            twingateMenu.visible = false;
            Quickshell.execDetached(["ghostty", "-e", "sh", "-c", "twingate auth \"$1\"; echo; read -p 'Press Enter to close' _", "sh", res.name]);
        } else {
            var addr = res.alias !== "-" ? res.alias : res.address;
            Quickshell.execDetached(["wl-copy", addr]);
            Quickshell.execDetached(["notify-send", "-a", "Twingate", "Twingate", "Copied " + addr]);
        }
    }

    // Twingate status process
    Process {
        id: tgStatusProc
        // Prints "__none__" when the CLI is missing; never talks to the daemon
        command: ["sh", "-c",
            "command -v twingate >/dev/null || { echo __none__; exit; }; " +
            "if ! systemctl is-active --quiet twingate; then echo not-running; " +
            "elif ip -4 -o addr show dev sdwan0 2>/dev/null | grep -q inet; then echo online; " +
            "else echo offline; fi"]
        stdout: SplitParser {
            onRead: data => {
                var s = data ? data.trim() : "";
                if (s) bar.tgStatus = s;
            }
        }
        Component.onCompleted: running = true
    }

    // Twingate resource list (tab-separated: name, address, alias, auth status)
    Process {
        id: tgResProc
        command: ["twingate", "resources"]
        onStarted: bar._tgScratch = { list: [], hidden: 0, header: false }
        stdout: SplitParser {
            onRead: data => {
                if (!data || !data.trim()) return;
                var f = data.split("\t").map(x => x.trim());
                if (f.length < 4) {
                    var m = data.match(/^(\d+) background resources/);
                    if (m) bar._tgScratch.hidden = parseInt(m[1]);
                    return;
                }
                if (f[0] === "RESOURCE NAME") { bar._tgScratch.header = true; return; }
                bar._tgScratch.list.push({ name: f[0], address: f[1], alias: f[2], auth: f[3] });
            }
        }
        onExited: {
            var list = bar._tgScratch.list;
            list.sort((a, b) => (bar.tgNeedsAuth(b) - bar.tgNeedsAuth(a)) || a.name.localeCompare(b.name));
            bar.tgResources = list;
            bar.tgHiddenCount = bar._tgScratch.hidden;
            bar.tgIpcStuck = !bar._tgScratch.header;
        }
    }

    // Periodic Twingate status check every 5 seconds
    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: bar.refreshTwingate()
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

            // Network Button (NetworkManager)
            Rectangle {
                id: netButton
                anchors.verticalCenter: parent.verticalCenter
                height: 24
                width: netRow.implicitWidth + 16
                radius: 5
                color: (netMenu.visible || netMouseArea.containsMouse) ? "#45475a" : "#313244"

                readonly property bool wifiUp: bar.netWifiSsid !== ""
                readonly property bool connecting: bar.netWifiState.indexOf("connecting") === 0

                Row {
                    id: netRow
                    anchors.centerIn: parent
                    spacing: 6

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: {
                            if (netButton.wifiUp) return bar.wifiIcon(bar.netWifiSignal);
                            if (bar.netEthConnected) return "󰈀";
                            if (netButton.connecting) return "󰤩";
                            if (!bar.netWifiEnabled) return "󰤮";
                            return "󰤯";
                        }
                        color: (netButton.wifiUp || bar.netEthConnected) ? "#94e2d5" : "#6c7086"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 13
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        width: Math.min(implicitWidth, 120)
                        text: {
                            if (netButton.wifiUp) return bar.netWifiSsid;
                            if (bar.netEthConnected) return "Wired";
                            if (netButton.connecting) return "Connecting…";
                            if (!bar.netWifiEnabled) return "Off";
                            return "Offline";
                        }
                        color: (netButton.wifiUp || bar.netEthConnected) ? "#cdd6f4" : "#6c7086"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 13
                        font.bold: true
                        elide: Text.ElideRight
                    }
                }

                MouseArea {
                    id: netMouseArea
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    hoverEnabled: true

                    onClicked: mouse => {
                        if (mouse.button === Qt.LeftButton) {
                            netMenu.visible = !netMenu.visible;
                            if (netMenu.visible) bar.refreshWifiList(false);
                        } else if (mouse.button === Qt.RightButton) {
                            I3.dispatch("exec nm-connection-editor");
                        }
                    }
                }
            }

            // Twingate Button
            Rectangle {
                id: tgButton
                anchors.verticalCenter: parent.verticalCenter
                height: 24
                width: tgRow.implicitWidth + 16
                radius: 5
                visible: bar.tgInstalled
                color: (twingateMenu.visible || tgMouseArea.containsMouse) ? "#45475a" : "#313244"

                readonly property color stateColor: bar.tgUnknown ? "#f9e2af"
                    : bar.tgOnline ? "#a6e3a1"
                    : "#6c7086"

                Row {
                    id: tgRow
                    anchors.centerIn: parent
                    spacing: 6

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: bar.tgUnknown ? "󰒙" : bar.tgOnline ? "󰒃" : "󰦞"
                        color: tgButton.stateColor
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 13
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: bar.tgUnknown ? "TG?" : bar.tgOnline ? "TG" : "Off"
                        color: (bar.tgOnline && !bar.tgUnknown) ? "#cdd6f4" : tgButton.stateColor
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 13
                        font.bold: true
                    }
                }

                MouseArea {
                    id: tgMouseArea
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    hoverEnabled: true

                    onClicked: mouse => {
                        if (mouse.button === Qt.LeftButton) {
                            twingateMenu.visible = !twingateMenu.visible;
                            if (twingateMenu.visible) {
                                bar.refreshTwingate();
                                bar.refreshTgResources();
                            }
                        } else if (mouse.button === Qt.RightButton) {
                            bar.tgToggleConnection();
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

            // Input Method Button (Fcitx5: Vietnamese / English)
            Rectangle {
                id: imButton
                anchors.verticalCenter: parent.verticalCenter
                height: 24
                width: imRow.implicitWidth + 16
                radius: 5
                color: imMouseArea.containsMouse ? "#45475a" : "#313244"

                Row {
                    id: imRow
                    anchors.centerIn: parent
                    spacing: 6

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "󰌌"
                        color: bar.isVietnamese ? "#f9e2af" : "#89b4fa"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 13
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: !bar.imAvailable ? "N/A" : bar.isVietnamese ? "VIE" : "ENG"
                        color: !bar.imAvailable ? "#6c7086" : bar.isVietnamese ? "#f9e2af" : "#cdd6f4"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 13
                        font.bold: true
                    }
                }

                MouseArea {
                    id: imMouseArea
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    hoverEnabled: true

                    onClicked: mouse => {
                        if (mouse.button === Qt.LeftButton) {
                            if (!bar.imAvailable) I3.dispatch("exec fcitx5 -d --replace");
                            else if (!imToggleProc.running) imToggleProc.running = true;
                        } else if (mouse.button === Qt.RightButton) {
                            I3.dispatch("exec fcitx5-configtool");
                        }
                    }
                }
            }

            // Clipboard Manager Button (CopyQ)
            Rectangle {
                id: clipButton
                anchors.verticalCenter: parent.verticalCenter
                width: 26
                height: 24
                radius: 5
                color: clipMouseArea.containsMouse ? "#45475a" : "#313244"

                Text {
                    anchors.centerIn: parent
                    text: "󰆒"
                    color: clipMouseArea.containsMouse ? "#f9e2af" : "#cdd6f4"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 13
                }

                MouseArea {
                    id: clipMouseArea
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    hoverEnabled: true

                    onClicked: mouse => {
                        if (mouse.button === Qt.LeftButton) {
                            if (!clipToggleProc.running) clipToggleProc.running = true;
                        } else if (mouse.button === Qt.RightButton) {
                            I3.dispatch("exec copyq --start-server menu");
                        }
                    }
                }
            }

            // Screenshot Button (Flameshot)
            Rectangle {
                id: shotButton
                anchors.verticalCenter: parent.verticalCenter
                width: 26
                height: 24
                radius: 5
                color: shotMouseArea.containsMouse ? "#45475a" : "#313244"

                Text {
                    anchors.centerIn: parent
                    text: "󰹑"
                    color: shotMouseArea.containsMouse ? "#94e2d5" : "#cdd6f4"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 13
                }

                MouseArea {
                    id: shotMouseArea
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    hoverEnabled: true

                    onClicked: mouse => {
                        if (mouse.button === Qt.LeftButton) {
                            // Short delay so the pointer/hover state isn't in the capture
                            I3.dispatch("exec flameshot gui -d 200");
                        } else if (mouse.button === Qt.RightButton) {
                            I3.dispatch("exec flameshot full -c");
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

    // Network / Wi-Fi Dropdown Menu
    PopupWindow {
        id: netMenu
        anchor.window: bar
        anchor.item: netButton
        anchor.edges: Edges.Bottom | Edges.Right
        anchor.gravity: Edges.Bottom | Edges.Left
        anchor.margins.top: 6
        visible: false

        implicitWidth: 300
        implicitHeight: netCol.implicitHeight + 16
        color: "transparent"

        onClosed: visible = false

        Rectangle {
            anchors.fill: parent
            radius: 8
            color: "#181825"
            border.color: "#313244"
            border.width: 1

            Column {
                id: netCol
                anchors.fill: parent
                anchors.margins: 8
                spacing: 6

                // Header: title, rescan, Wi-Fi toggle
                Item {
                    width: netCol.width
                    height: 24

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 4
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Wi-Fi"
                        color: "#cdd6f4"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 13
                        font.bold: true
                    }

                    Row {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 8

                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 24
                            height: 22
                            radius: 5
                            visible: bar.netWifiEnabled
                            color: rescanMouse.containsMouse ? "#313244" : "transparent"

                            Text {
                                anchors.centerIn: parent
                                text: "󰑐"
                                color: wifiListProc.running ? "#6c7086" : "#89b4fa"
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 13
                            }

                            MouseArea {
                                id: rescanMouse
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                hoverEnabled: true
                                onClicked: bar.refreshWifiList(true)
                            }
                        }

                        // Toggle switch
                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 36
                            height: 20
                            radius: 10
                            color: bar.netWifiEnabled ? "#94e2d5" : "#45475a"

                            Rectangle {
                                width: 16
                                height: 16
                                radius: 8
                                y: 2
                                x: bar.netWifiEnabled ? parent.width - width - 2 : 2
                                color: bar.netWifiEnabled ? "#11111b" : "#a6adc8"
                                Behavior on x { NumberAnimation { duration: 120 } }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: bar.runNetCmd(["nmcli", "radio", "wifi", bar.netWifiEnabled ? "off" : "on"], "")
                            }
                        }
                    }
                }

                // Wired connection status
                Rectangle {
                    width: netCol.width
                    height: 28
                    radius: 5
                    visible: bar.netEthConnected
                    color: "#1e1e2e"

                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        spacing: 10

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "󰈀"
                            color: "#94e2d5"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 13
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Wired · " + bar.netEthName
                            color: "#cdd6f4"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 13
                        }
                    }
                }

                Rectangle {
                    width: netCol.width
                    height: 1
                    color: "#313244"
                }

                // Empty / off state
                Text {
                    width: netCol.width
                    visible: !bar.netWifiEnabled || bar.wifiNetworks.length === 0
                    horizontalAlignment: Text.AlignHCenter
                    topPadding: 6
                    bottomPadding: 6
                    text: !bar.netWifiEnabled ? "Wi-Fi is off" : (wifiListProc.running ? "Scanning…" : "No networks found")
                    color: "#6c7086"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 13
                }

                // Network list
                Flickable {
                    width: netCol.width
                    height: Math.min(netListCol.implicitHeight, 280)
                    visible: bar.netWifiEnabled && bar.wifiNetworks.length > 0
                    contentHeight: netListCol.implicitHeight
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    Column {
                        id: netListCol
                        width: parent.width
                        spacing: 2

                        Repeater {
                            model: bar.netWifiEnabled ? bar.wifiNetworks : []

                            Rectangle {
                                width: netListCol.width
                                height: 28
                                radius: 5
                                color: apMouse.containsMouse ? "#313244" : "transparent"

                                readonly property bool pending: bar.wifiPendingSsid === modelData.ssid

                                Text {
                                    id: apIcon
                                    anchors.left: parent.left
                                    anchors.leftMargin: 10
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: bar.wifiIcon(modelData.signal)
                                    color: modelData.inUse ? "#94e2d5" : "#89b4fa"
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 13
                                }

                                Text {
                                    anchors.left: apIcon.right
                                    anchors.leftMargin: 10
                                    anchors.right: apStatus.left
                                    anchors.rightMargin: 8
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: modelData.ssid
                                    color: modelData.inUse ? "#94e2d5" : "#cdd6f4"
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 13
                                    font.bold: modelData.inUse
                                    elide: Text.ElideRight
                                }

                                Text {
                                    id: apStatus
                                    anchors.right: parent.right
                                    anchors.rightMargin: 10
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: {
                                        if (parent.pending) return "…";
                                        var s = modelData.inUse ? "󰄬" : (modelData.saved ? "󰆓" : "");
                                        if (modelData.secured) s += (s ? " " : "") + "󰌾";
                                        return s;
                                    }
                                    color: "#6c7086"
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 12
                                }

                                MouseArea {
                                    id: apMouse
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    hoverEnabled: true
                                    enabled: !netCmdProc.running
                                    onClicked: bar.activateNetwork(modelData)
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    width: netCol.width
                    height: 1
                    color: "#313244"
                }

                // Footer: open full settings
                Rectangle {
                    width: netCol.width
                    height: 28
                    radius: 5
                    color: settingsMouse.containsMouse ? "#313244" : "transparent"

                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        spacing: 10

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "󰒓"
                            color: "#b4befe"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 13
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Network settings"
                            color: "#cdd6f4"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 13
                        }
                    }

                    MouseArea {
                        id: settingsMouse
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                        onClicked: {
                            netMenu.visible = false;
                            I3.dispatch("exec nm-connection-editor");
                        }
                    }
                }
            }
        }
    }

    // Twingate Dropdown Menu
    // Sway never gives keyboard focus to popups of a bar that doesn't take focus
    // itself, so this is a full-screen overlay layer surface instead: it grabs the
    // keyboard for the search field, and a click outside the menu closes it.
    PanelWindow {
        id: twingateMenu
        screen: bar.screen
        visible: false
        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "quickshell-twingate"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

        // Right edge of the bar button, captured when the menu opens
        property real anchorRight: 0

        onVisibleChanged: {
            if (!visible) return;
            anchorRight = tgButton.mapToItem(null, tgButton.width, 0).x;
            bar.tgFilter = "";
            tgSearchInput.forceActiveFocus();
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
            onClicked: twingateMenu.visible = false
        }

        Rectangle {
            x: Math.max(0, twingateMenu.anchorRight - width)
            y: bar.implicitHeight + 6
            width: 380
            height: tgCol.implicitHeight + 16
            radius: 8
            color: "#181825"
            border.color: "#313244"
            border.width: 1

            // Keep clicks inside the menu from reaching the close-on-outside-click area
            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.AllButtons
            }

            Column {
                id: tgCol
                anchors.fill: parent
                anchors.margins: 8
                spacing: 6

                // Header: title, status, refresh
                Item {
                    width: tgCol.width
                    height: 24

                    Row {
                        anchors.left: parent.left
                        anchors.leftMargin: 4
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 8

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Twingate"
                            color: "#cdd6f4"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 13
                            font.bold: true
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "● " + bar.tgStatus
                            color: tgButton.stateColor
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 12
                        }
                    }

                    Rectangle {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        width: 24
                        height: 22
                        radius: 5
                        visible: bar.tgOnline
                        color: tgRefreshMouse.containsMouse ? "#313244" : "transparent"

                        Text {
                            anchors.centerIn: parent
                            text: "󰑐"
                            color: tgResProc.running ? "#6c7086" : "#89b4fa"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 13
                        }

                        MouseArea {
                            id: tgRefreshMouse
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            hoverEnabled: true
                            onClicked: bar.refreshTgResources()
                        }
                    }
                }

                Rectangle {
                    width: tgCol.width
                    height: 1
                    color: "#313244"
                }

                // Search field: filters by name, address or alias
                Rectangle {
                    width: tgCol.width
                    height: 30
                    radius: 5
                    visible: bar.tgOnline && bar.tgResources.length > 0
                    color: "#1e1e2e"
                    border.color: tgSearchInput.activeFocus ? "#89b4fa" : "#313244"
                    border.width: 1

                    Text {
                        id: tgSearchIcon
                        anchors.left: parent.left
                        anchors.leftMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        text: "󰍉"
                        color: "#6c7086"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 13
                    }

                    TextInput {
                        id: tgSearchInput
                        anchors.left: tgSearchIcon.right
                        anchors.leftMargin: 8
                        anchors.right: tgSearchClear.left
                        anchors.rightMargin: 6
                        anchors.verticalCenter: parent.verticalCenter
                        text: bar.tgFilter
                        onTextEdited: bar.tgFilter = text
                        color: "#cdd6f4"
                        selectionColor: "#45475a"
                        selectedTextColor: "#cdd6f4"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 13
                        clip: true

                        // Enter acts on the top match, Escape clears then closes
                        Keys.onReturnPressed: if (bar.tgFiltered.length > 0) bar.tgActivateResource(bar.tgFiltered[0])
                        Keys.onEnterPressed: if (bar.tgFiltered.length > 0) bar.tgActivateResource(bar.tgFiltered[0])
                        Keys.onEscapePressed: {
                            if (bar.tgFilter) bar.tgFilter = "";
                            else twingateMenu.visible = false;
                        }

                        Text {
                            anchors.fill: parent
                            verticalAlignment: Text.AlignVCenter
                            visible: !parent.text
                            text: "Search resources…"
                            color: "#6c7086"
                            font: parent.font
                        }
                    }

                    Text {
                        id: tgSearchClear
                        anchors.right: parent.right
                        anchors.rightMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        visible: bar.tgFilter !== ""
                        text: "󰅖"
                        color: tgClearMouse.containsMouse ? "#f38ba8" : "#6c7086"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 13

                        MouseArea {
                            id: tgClearMouse
                            anchors.fill: parent
                            anchors.margins: -4
                            cursorShape: Qt.PointingHandCursor
                            hoverEnabled: true
                            onClicked: {
                                bar.tgFilter = "";
                                tgSearchInput.forceActiveFocus();
                            }
                        }
                    }
                }

                // Empty / offline state
                Text {
                    width: tgCol.width
                    visible: !bar.tgOnline || bar.tgFiltered.length === 0
                    horizontalAlignment: Text.AlignHCenter
                    topPadding: 6
                    bottomPadding: 6
                    text: bar.tgUnknown ? "Twingate daemon is not responding"
                        : !bar.tgOnline ? "Twingate is " + bar.tgStatus
                        : tgResProc.running ? "Loading…"
                        : bar.tgResources.length > 0 ? "No matching resources"
                        : "No resources"
                    color: "#6c7086"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 13
                }

                // Resource list: click copies the address, or re-authenticates a locked resource
                Flickable {
                    width: tgCol.width
                    height: Math.min(tgListCol.implicitHeight, 360)
                    visible: bar.tgOnline && bar.tgFiltered.length > 0
                    contentHeight: tgListCol.implicitHeight
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    Column {
                        id: tgListCol
                        width: parent.width
                        spacing: 2

                        Repeater {
                            model: bar.tgOnline ? bar.tgFiltered : []

                            Rectangle {
                                width: tgListCol.width
                                height: 40
                                radius: 5
                                color: resMouse.containsMouse ? "#313244" : "transparent"

                                readonly property bool needsAuth: bar.tgNeedsAuth(modelData)

                                Text {
                                    id: resIcon
                                    anchors.left: parent.left
                                    anchors.leftMargin: 10
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: parent.needsAuth ? "󰌾" : "󰖟"
                                    color: parent.needsAuth ? "#f9e2af" : "#89b4fa"
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 13
                                }

                                Column {
                                    anchors.left: resIcon.right
                                    anchors.leftMargin: 10
                                    anchors.right: resAuth.left
                                    anchors.rightMargin: 8
                                    anchors.verticalCenter: parent.verticalCenter

                                    Text {
                                        width: parent.width
                                        text: modelData.name
                                        color: "#cdd6f4"
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pixelSize: 13
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        width: parent.width
                                        text: modelData.alias !== "-" ? modelData.alias : modelData.address
                                        visible: text !== modelData.name
                                        color: "#6c7086"
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pixelSize: 11
                                        elide: Text.ElideRight
                                    }
                                }

                                Text {
                                    id: resAuth
                                    anchors.right: parent.right
                                    anchors.rightMargin: 10
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: modelData.auth.replace(/^Auth expires in /, "")
                                    color: parent.needsAuth ? "#f9e2af" : "#6c7086"
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 11
                                }

                                MouseArea {
                                    id: resMouse
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    hoverEnabled: true
                                    onClicked: bar.tgActivateResource(modelData)
                                }
                            }
                        }
                    }
                }

                Text {
                    width: tgCol.width
                    visible: bar.tgOnline && bar.tgHiddenCount > 0
                    horizontalAlignment: Text.AlignHCenter
                    text: bar.tgHiddenCount + " background resources hidden"
                    color: "#6c7086"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 11
                }

                Rectangle {
                    width: tgCol.width
                    height: 1
                    color: "#313244"
                }

                // Footer: connect / disconnect
                Rectangle {
                    width: tgCol.width
                    height: 28
                    radius: 5
                    color: tgConnMouse.containsMouse ? "#313244" : "transparent"

                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        spacing: 10

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: bar.tgUnknown ? "󰜉" : bar.tgOnline ? "󰅙" : "󰐥"
                            color: bar.tgUnknown ? "#f9e2af" : bar.tgOnline ? "#f38ba8" : "#a6e3a1"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 13
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: bar.tgUnknown ? "Restart Twingate service" : bar.tgOnline ? "Disconnect" : "Connect"
                            color: "#cdd6f4"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 13
                        }
                    }

                    MouseArea {
                        id: tgConnMouse
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                        onClicked: bar.tgToggleConnection()
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
