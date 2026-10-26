import QtQuick

import org.kde.plasma.plasma5support as Plasma5Support

import "../tools/parser.js" as Parser

Item {
    id: monitor

    // what to sample, set by main.qml
    required property bool isCpu
    required property bool isListNeeded
    required property bool isPercentDisplayed
    required property bool isShowingSystemProcesses
    required property bool shouldConfirmStop
    required property int processCount
    required property int intervalSec

    // latest sample, written by applySample()
    property real usagePercent: 0
    property var processes: []
    property string memoryText: ""
    property string lastError: i18n("Waiting for the first sample...")
    property var previousCpuJiffies: null
    property real listUptimeSec: 0

    // stopping a process
    property string stopError: ""
    readonly property bool hasStopError: stopError !== ""
    property var pendingStop: null
    readonly property bool hasPendingStop: pendingStop !== null
    readonly property string stopQuestion: pendingStop ? i18n("Stop %1 (%2)?", pendingStop.name, pendingStop.pid) : ""
    readonly property bool isBusy: runner.isBusy

    function refresh(): void {
        runner.refresh();
    }

    function openSystemMonitor(): void {
        runner.connectSource("plasma-systemmonitor >/dev/null 2>&1 &");
    }

    function requestStop(process): void {
        stopError = "";
        const stop = { pid: process.pid, name: process.name, listUptimeSec: listUptimeSec };
        if (shouldConfirmStop) {
            pendingStop = stop;
            return;
        }
        runner.stopProcess(stop);
    }

    function confirmStop(): void {
        const stop = pendingStop;
        pendingStop = null;
        runner.stopProcess(stop);
    }

    function cancelStop(): void {
        pendingStop = null;
    }

    function clearStop(): void {
        stopError = "";
        pendingStop = null;
    }

    function applyProcessList(output, errorOutput): void {
        const sample = Parser.parseTopOutput(output, monitor.isCpu, monitor.processCount);
        monitor.processes = sample.processes;
        monitor.listUptimeSec = sample.uptimeSec;
        const hasProcesses = sample.processes.length > 0;
        const errorText = errorOutput || i18n("top produced no parsable rows");
        monitor.lastError = hasProcesses ? "" : errorText;
    }

    function applySample(source, data): void {
        const output = data.stdout || "";
        const isListSample = source.indexOf("top ") >= 0;
        if (isListSample) applyProcessList(output, data.stderr);
        if (monitor.isCpu) {
            const jiffies = Parser.parseCpuJiffies(output);
            if (!jiffies) return;
            const previous = monitor.previousCpuJiffies || { total: 0, idle: 0 };
            const canComputeUsage = jiffies.total > previous.total;
            if (canComputeUsage) {
                const idleShare = (jiffies.idle - previous.idle) / (jiffies.total - previous.total);
                monitor.usagePercent = 100 * (1 - idleShare);
            }
            monitor.previousCpuJiffies = jiffies;
            return;
        }
        const memory = Parser.parseMemInfo(output);
        if (!memory) return;
        monitor.usagePercent = memory.usagePercent;
        monitor.memoryText = memory.memoryText;
    }

    Plasma5Support.DataSource {
        id: poller

        readonly property real topDelaySec: 0.2
        readonly property int topWidthColumns: 512

        // ignore the user's toprc, so top always prints the layout the parser expects
        readonly property string topEnvironment: "HOME=/nonexistent XDG_CONFIG_HOME=/nonexistent LC_ALL=C"

        readonly property string userFilter: monitor.isShowingSystemProcesses ? "" : "-u $(id -un) "
        readonly property string sortColumn: monitor.isCpu ? "%CPU" : "%MEM"
        readonly property string topOptions: `-d ${topDelaySec} -w ${topWidthColumns} -c ${userFilter}-o ${sortColumn}`
        readonly property string topCommand: topEnvironment + " top -bn2 " + topOptions

        readonly property string cpuCommand: "head -1 /proc/stat"
        readonly property string memoryCommand: "grep -E '^Mem(Total|Available)' /proc/meminfo"
        readonly property string usageCommand: monitor.isCpu ? cpuCommand : memoryCommand

        readonly property string listCommand: topCommand + "; cat /proc/uptime; " + usageCommand

        readonly property string command: monitor.isListNeeded ? listCommand : usageCommand
        readonly property bool isIdle: !monitor.isListNeeded && !monitor.isPercentDisplayed

        engine: "executable"
        interval: isIdle ? 0 : Math.max(1, monitor.intervalSec) * 1000
        connectedSources: isIdle ? [] : [command]
        onNewData: (source, data) => monitor.applySample(source, data)
    }

    Plasma5Support.DataSource {
        id: runner

        property string refreshSource: ""
        readonly property bool isBusy: connectedSources.length > 0

        // a stop only kills a process that already existed when the list was taken, so a reused PID is spared
        readonly property string stopMarker: " # stop"
        readonly property int otherProcessExitCode: 3

        engine: "executable"
        onNewData: (source, data) => {
            disconnectSource(source);
            const isRefresh = source === refreshSource;
            if (isRefresh) {
                monitor.applySample(source, data);
                return;
            }
            const isStop = source.endsWith(stopMarker);
            if (!isStop) return;
            const exitCode = data["exit code"];
            const hasFailed = exitCode !== 0;
            const isOtherProcess = exitCode === otherProcessExitCode;
            const failureText = (data.stderr || "").trim() || i18n("Could not stop the process");
            const otherProcessText = i18n("The process ended or changed since the list was taken");
            const errorText = isOtherProcess ? otherProcessText : failureText;
            if (hasFailed) monitor.stopError = errorText;
            refresh();
        }

        function refresh(): void {
            refreshSource = poller.listCommand + " # " + Date.now();
            connectSource(refreshSource);
        }

        function stopProcess(stop): void {
            const listCentisec = Math.round(stop.listUptimeSec * 100);
            const startJiffies = `$(sed 's/.*) //' /proc/${stop.pid}/stat 2>/dev/null | cut -d' ' -f20)`;
            const listJiffies = `$((${listCentisec} * $(getconf CLK_TCK) / 100))`;
            const startCheck = `[ -n "$start" ] && [ "$start" -le ${listJiffies} ] || exit ${otherProcessExitCode}`;
            connectSource(`start=${startJiffies}; ${startCheck}; kill ${stop.pid}${stopMarker}`);
        }
    }
}
