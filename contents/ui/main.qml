import QtQuick
import QtQuick.Layouts

import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.extras as PlasmaExtras
import org.kde.plasma.plasma5support as Plasma5Support
import org.kde.kirigami as Kirigami

import "../tools/parser.js" as Parser

PlasmoidItem {
    id: root

    // values of "display" setting
    readonly property int displayIconOnly: 0
    readonly property int displayPercentOnly: 1
    readonly property int displayIconAndPercent: 2
    readonly property int displayNameAndPercent: 3

    // look of the popup
    readonly property real secondaryOpacity: 0.6
    readonly property real headerHeightUnits: 4
    readonly property real rowHeightUnits: 2.6
    readonly property real tooltipWidthUnits: 30
    readonly property int tooltipDelayMs: 250

    // latest sample, written by applySample()
    property real usagePercent: 0
    property var processes: []
    property string memoryText: ""
    property string lastError: i18n("Waiting for the first sample...")
    property var previousCpuJiffies: null

    // state of the list
    property bool isPaused: false
    property string stopError: ""
    readonly property bool hasStopError: stopError !== ""

    // widget mode, filled in by install.sh, CPU or RAM
    readonly property bool isCpu: "@MODE@" === "cpu"
    readonly property string appIcon: Plasmoid.configuration.icon || (isCpu ? "cpu" : "memory")
    readonly property string resourceName: isCpu ? i18n("CPU") : i18n("RAM")
    readonly property int processCount: Plasmoid.configuration.count
    readonly property real popupHeightUnits: headerHeightUnits + rowHeightUnits * processCount

    // on desktop the list is always on screen; in a panel only while the popup is open
    readonly property bool isOnDesktop: Plasmoid.formFactor === PlasmaCore.Types.Planar
    readonly property bool isListNeeded: !isPaused && (expanded || isOnDesktop)

    // settings
    readonly property int displayMode: Plasmoid.configuration.display
    readonly property bool isIconDisplayed: displayMode === displayIconOnly || displayMode === displayIconAndPercent
    readonly property bool isPercentDisplayed: displayMode !== displayIconOnly
    readonly property bool isNameDisplayed: displayMode === displayNameAndPercent
    readonly property bool isShowingSystemProcesses: Plasmoid.configuration.showSystemProcesses

    // figures as text
    readonly property string usageTextDecimal: usagePercent.toFixed(1) + "%"
    readonly property string usageTextRounded: Math.round(usagePercent) + "%"
    readonly property string intervalText: Plasmoid.configuration.interval + "s"

    // popup header
    readonly property string processSourceText: isShowingSystemProcesses ? i18n("Sys") : i18n("User")
    readonly property string memorySuffix: isCpu ? "" : "  (" + memoryText + ")"
    readonly property string headerTitle: resourceName + " [" + processSourceText + "]"
    readonly property string headerFigures: usageTextDecimal + " (" + intervalText + ")" + memorySuffix
    readonly property string headerText: headerTitle + " — " + headerFigures

    // tooltip, polling stops while the popup is closed
    readonly property string tooltipUsageSuffix: isPercentDisplayed ? ": " + usageTextDecimal : ""
    readonly property string tooltipText: resourceName + tooltipUsageSuffix

    // text next to the panel icon
    readonly property string compactNamePrefix: isNameDisplayed ? resourceName + ": " : ""
    readonly property string compactText: compactNamePrefix + usageTextRounded

    function applySample(source, data): void {
        const output = data.stdout || "";
        const isListSample = source.indexOf("top ") >= 0;
        if (isListSample) {
            const sample = Parser.parseTopOutput(output, root.isCpu, root.processCount);
            root.usagePercent = sample.usagePercent;
            root.memoryText = sample.memoryText;
            root.processes = sample.processes;
            const hasProcesses = sample.processes.length > 0;
            const errorText = data.stderr || i18n("top produced no parsable rows");
            root.lastError = hasProcesses ? "" : errorText;
            return;
        }
        if (root.isCpu) {
            const jiffies = Parser.parseCpuJiffies(output);
            const previous = root.previousCpuJiffies;
            const canComputeUsage = previous !== null && jiffies.total > previous.total;
            if (canComputeUsage) {
                const idleShare = (jiffies.idle - previous.idle) / (jiffies.total - previous.total);
                root.usagePercent = 100 * (1 - idleShare);
            }
            root.previousCpuJiffies = jiffies;
            return;
        }
        const memory = Parser.parseMemInfo(output);
        if (!memory) return;
        root.usagePercent = memory.usagePercent;
        root.memoryText = memory.memoryText;
    }

    Plasma5Support.DataSource {
        id: poller

        readonly property real topDelaySec: 0.2
        readonly property int topWidthColumns: 512

        // ignore the user's toprc, so top always prints the layout the parser expects
        readonly property string topEnvironment: "HOME=/nonexistent XDG_CONFIG_HOME=/nonexistent LC_ALL=C"

        readonly property string userFilter: root.isShowingSystemProcesses ? "" : "-u $(id -un) "
        readonly property string sortColumn: root.isCpu ? "%CPU" : "%MEM"
        readonly property string topOptions: `-d ${topDelaySec} -w ${topWidthColumns} -c ${userFilter}-o ${sortColumn}`
        readonly property string listCommand: topEnvironment + " top -bn2 " + topOptions

        readonly property string cpuCommand: "head -1 /proc/stat"
        readonly property string memoryCommand: "grep -E '^Mem(Total|Available)' /proc/meminfo"
        readonly property string cheapCommand: root.isCpu ? cpuCommand : memoryCommand

        readonly property string command: root.isListNeeded ? listCommand : cheapCommand
        readonly property bool isIdle: !root.isListNeeded && !root.isPercentDisplayed

        engine: "executable"
        interval: isIdle ? 0 : Math.max(1, Plasmoid.configuration.interval) * 1000
        connectedSources: isIdle ? [] : [command]
        onNewData: (source, data) => root.applySample(source, data)
        onConnectedSourcesChanged: root.previousCpuJiffies = null
    }

    Plasma5Support.DataSource {
        id: runner

        property string refreshSource: ""
        readonly property bool isBusy: connectedSources.length > 0

        engine: "executable"
        onNewData: (source, data) => {
            disconnectSource(source);
            const isRefresh = source === refreshSource;
            if (isRefresh) {
                root.applySample(source, data);
                return;
            }
            const isStop = source.startsWith("kill ");
            if (!isStop) return;
            const hasFailed = data["exit code"] !== 0;
            const errorText = (data.stderr || "").trim() || i18n("Could not stop the process");
            if (hasFailed) root.stopError = errorText;
            refresh();
        }

        function refresh(): void {
            refreshSource = poller.listCommand + " # " + Date.now();
            connectSource(refreshSource);
        }

        function stopProcess(pid): void {
            root.stopError = "";
            connectSource("kill " + pid);
        }
    }

    Plasmoid.icon: appIcon
    toolTipMainText: tooltipText
    onExpandedChanged: if (!expanded) stopError = ""

    compactRepresentation: MouseArea {
        Layout.minimumWidth: layout.implicitWidth
        onClicked: root.expanded = !root.expanded

        RowLayout {
            id: layout
            anchors.fill: parent
            spacing: Kirigami.Units.smallSpacing

            Kirigami.Icon {
                source: root.appIcon
                visible: root.isIconDisplayed
                Layout.fillHeight: true
                Layout.preferredWidth: height
            }
            PlasmaComponents.Label {
                text: root.compactText
                visible: root.isPercentDisplayed
            }
        }
    }

    fullRepresentation: PlasmaExtras.Representation {
        Layout.minimumWidth: Kirigami.Units.gridUnit * 22
        Layout.minimumHeight: Kirigami.Units.gridUnit * 12
        Layout.preferredWidth: Kirigami.Units.gridUnit * 26
        Layout.preferredHeight: Kirigami.Units.gridUnit * root.popupHeightUnits
        collapseMarginsHint: true

        header: PlasmaExtras.PlasmoidHeading {
            contentItem: RowLayout {
                PlasmaExtras.Heading {
                    Layout.fillWidth: true
                    level: 3
                    text: root.headerText
                }
                PlasmaComponents.ToolButton {
                    icon.name: "utilities-system-monitor"
                    display: PlasmaComponents.AbstractButton.IconOnly
                    text: i18n("Open System Monitor")
                    PlasmaComponents.ToolTip.text: text
                    PlasmaComponents.ToolTip.visible: hovered
                    onClicked: runner.connectSource("plasma-systemmonitor >/dev/null 2>&1 &")
                }
                PlasmaComponents.ToolButton {
                    icon.name: "media-playback-pause"
                    checkable: true
                    checked: root.isPaused
                    display: PlasmaComponents.AbstractButton.IconOnly
                    text: root.isPaused ? i18n("Resume list updates") : i18n("Pause list updates")
                    PlasmaComponents.ToolTip.text: text
                    PlasmaComponents.ToolTip.visible: hovered
                    onToggled: {
                        root.isPaused = checked;
                        checked = Qt.binding(() => root.isPaused);
                    }
                }
                PlasmaComponents.ToolButton {
                    icon.name: "view-refresh"
                    display: PlasmaComponents.AbstractButton.IconOnly
                    text: i18n("Refresh now")
                    PlasmaComponents.ToolTip.text: text
                    PlasmaComponents.ToolTip.visible: hovered
                    enabled: !runner.isBusy
                    onClicked: runner.refresh()
                }
                PlasmaComponents.ToolButton {
                    icon.name: "window-pin"
                    checkable: true
                    display: PlasmaComponents.AbstractButton.IconOnly
                    text: i18n("Keep open")
                    PlasmaComponents.ToolTip.text: text
                    PlasmaComponents.ToolTip.visible: hovered
                    onCheckedChanged: root.hideOnWindowDeactivate = !checked
                }
            }
        }

        PlasmaComponents.ScrollView {
            anchors.fill: parent
            PlasmaComponents.ScrollBar.horizontal.policy: PlasmaComponents.ScrollBar.AlwaysOff

            contentItem: ListView {
                id: list
                leftMargin: Kirigami.Units.smallSpacing
                rightMargin: Kirigami.Units.smallSpacing
                model: root.processes
                clip: true
                spacing: Kirigami.Units.smallSpacing
                reuseItems: true

                delegate: RowLayout {
                    id: row

                    required property var modelData

                    width: list.width - list.leftMargin - list.rightMargin
                    spacing: Kirigami.Units.smallSpacing

                    HoverHandler { id: rowHover }

                    PlasmaComponents.ToolTip {
                        id: commandTip
                        text: row.modelData.command
                        delay: root.tooltipDelayMs
                        visible: rowHover.hovered && !stopButton.hovered

                        contentItem: Item {
                            implicitWidth: Math.min(tipLabel.maxWidth, tipLabel.contentWidth)
                            implicitHeight: tipLabel.implicitHeight

                            PlasmaComponents.Label {
                                id: tipLabel
                                readonly property real maxWidth: Kirigami.Units.gridUnit * root.tooltipWidthUnits
                                text: commandTip.text
                                wrapMode: Text.Wrap
                                onLineLaidOut: line => {
                                    const isTooWide = line.implicitWidth > maxWidth;
                                    if (isTooWide) line.width = maxWidth;
                                }
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        PlasmaComponents.Label {
                            Layout.fillWidth: true
                            text: row.modelData.name
                            elide: Text.ElideRight
                        }
                        PlasmaComponents.Label {
                            Layout.fillWidth: true
                            text: row.modelData.command
                            font: Kirigami.Theme.smallFont
                            opacity: root.secondaryOpacity
                            elide: Text.ElideRight
                        }
                    }

                    PlasmaComponents.Label {
                        text: row.modelData.pid
                        opacity: root.secondaryOpacity
                    }
                    PlasmaComponents.Label {
                        text: row.modelData.usageText
                    }
                    PlasmaComponents.ToolButton {
                        id: stopButton
                        icon.name: "media-playback-stop"
                        display: PlasmaComponents.AbstractButton.IconOnly
                        text: i18n("Stop %1 (%2)", row.modelData.name, row.modelData.pid)
                        PlasmaComponents.ToolTip.text: text
                        PlasmaComponents.ToolTip.visible: hovered
                        enabled: !root.isPaused
                        onClicked: runner.stopProcess(row.modelData.pid)
                    }
                }

                PlasmaExtras.PlaceholderMessage {
                    anchors.centerIn: parent
                    width: parent.width - Kirigami.Units.gridUnit * 4
                    visible: list.count === 0
                    text: i18n("No data")
                    explanation: root.lastError
                }
            }
        }

        footer: Kirigami.InlineMessage {
            type: Kirigami.MessageType.Error
            text: root.stopError
            visible: root.hasStopError
        }
    }
}
