import QtQuick

import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore

PlasmoidItem {
    id: root

    // values of "display" setting
    readonly property int displayIconOnly: 0
    readonly property int displayPercentOnly: 1
    readonly property int displayIconAndPercent: 2
    readonly property int displayNameAndPercent: 3

    // state of the list
    property bool isPaused: false

    // widget mode, filled in by install.sh, CPU or RAM
    readonly property bool isCpu: "@MODE@" === "cpu"
    readonly property string appIcon: Plasmoid.configuration.icon || (isCpu ? "cpu" : "memory")
    readonly property string resourceName: isCpu ? i18n("CPU") : i18n("RAM")

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
    readonly property string usageTextDecimal: processMonitor.usagePercent.toFixed(1) + "%"
    readonly property string usageTextRounded: Math.round(processMonitor.usagePercent) + "%"
    readonly property string intervalText: Plasmoid.configuration.interval + "s"

    // popup header
    readonly property string processSourceText: isShowingSystemProcesses ? i18n("Sys") : i18n("User")
    readonly property string memorySuffix: isCpu ? "" : "  (" + processMonitor.memoryText + ")"
    readonly property string headerTitle: resourceName + " [" + processSourceText + "]"
    readonly property string headerFigures: usageTextDecimal + " (" + intervalText + ")" + memorySuffix
    readonly property string headerText: headerTitle + " — " + headerFigures

    // tooltip, polling stops while the popup is closed
    readonly property string tooltipUsageSuffix: isPercentDisplayed ? ": " + usageTextDecimal : ""
    readonly property string tooltipText: resourceName + tooltipUsageSuffix

    // text next to the panel icon
    readonly property string compactNamePrefix: isNameDisplayed ? resourceName + ": " : ""
    readonly property string compactText: compactNamePrefix + usageTextRounded

    function togglePopup(): void {
        expanded = !expanded;
    }

    ProcessMonitor {
        id: processMonitor
        isCpu: root.isCpu
        isListNeeded: root.isListNeeded
        isPercentDisplayed: root.isPercentDisplayed
        isShowingSystemProcesses: root.isShowingSystemProcesses
        shouldConfirmStop: Plasmoid.configuration.confirmStop
        processCount: Plasmoid.configuration.count
        intervalSec: Plasmoid.configuration.interval
    }

    Plasmoid.icon: appIcon
    toolTipMainText: tooltipText
    onExpandedChanged: if (!expanded) processMonitor.clearStop()

    compactRepresentation: CompactRepresentation {
        plasmoidItem: root
    }

    fullRepresentation: FullRepresentation {
        plasmoidItem: root
        monitor: processMonitor
    }
}
