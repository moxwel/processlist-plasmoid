import QtQuick
import QtQuick.Layouts

import org.kde.plasma.plasmoid
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.extras as PlasmaExtras
import org.kde.kirigami as Kirigami

PlasmaExtras.Representation {
    id: fullRepresentation

    required property PlasmoidItem plasmoidItem
    required property ProcessMonitor monitor

    // size of the popup, in grid units
    readonly property real headerHeightUnits: 4
    readonly property real rowHeightUnits: 2.6
    readonly property real popupHeightUnits: headerHeightUnits + rowHeightUnits * monitor.processCount

    Layout.minimumWidth: Kirigami.Units.gridUnit * 22
    Layout.minimumHeight: Kirigami.Units.gridUnit * 12
    Layout.preferredWidth: Kirigami.Units.gridUnit * 26
    Layout.preferredHeight: Kirigami.Units.gridUnit * popupHeightUnits
    collapseMarginsHint: true

    header: PlasmaExtras.PlasmoidHeading {
        contentItem: RowLayout {
            PlasmaExtras.Heading {
                Layout.fillWidth: true
                level: 3
                text: fullRepresentation.plasmoidItem.headerText
            }
            PlasmaComponents.ToolButton {
                icon.name: "utilities-system-monitor"
                display: PlasmaComponents.AbstractButton.IconOnly
                text: i18n("Open System Monitor")
                PlasmaComponents.ToolTip.text: text
                PlasmaComponents.ToolTip.visible: hovered
                onClicked: fullRepresentation.monitor.openSystemMonitor()
            }
            PlasmaComponents.ToolButton {
                icon.name: "media-playback-pause"
                checkable: true
                checked: fullRepresentation.plasmoidItem.isPaused
                display: PlasmaComponents.AbstractButton.IconOnly
                text: checked ? i18n("Resume list updates") : i18n("Pause list updates")
                PlasmaComponents.ToolTip.text: text
                PlasmaComponents.ToolTip.visible: hovered
                onToggled: {
                    fullRepresentation.plasmoidItem.isPaused = checked;
                    checked = Qt.binding(() => fullRepresentation.plasmoidItem.isPaused);
                }
            }
            PlasmaComponents.ToolButton {
                icon.name: "view-refresh"
                display: PlasmaComponents.AbstractButton.IconOnly
                text: i18n("Refresh now")
                PlasmaComponents.ToolTip.text: text
                PlasmaComponents.ToolTip.visible: hovered
                enabled: !fullRepresentation.monitor.isBusy
                onClicked: fullRepresentation.monitor.refresh()
            }
            PlasmaComponents.ToolButton {
                icon.name: "window-pin"
                checkable: true
                display: PlasmaComponents.AbstractButton.IconOnly
                text: i18n("Keep open")
                PlasmaComponents.ToolTip.text: text
                PlasmaComponents.ToolTip.visible: hovered
                onCheckedChanged: fullRepresentation.plasmoidItem.hideOnWindowDeactivate = !checked
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
            model: fullRepresentation.monitor.processes
            clip: true
            spacing: Kirigami.Units.smallSpacing
            reuseItems: true

            delegate: ProcessRow {
                width: list.width - list.leftMargin - list.rightMargin
                monitor: fullRepresentation.monitor
            }

            PlasmaExtras.PlaceholderMessage {
                anchors.centerIn: parent
                width: parent.width - Kirigami.Units.gridUnit * 4
                visible: list.count === 0
                text: i18n("No data")
                explanation: fullRepresentation.monitor.lastError
            }
        }
    }

    footer: ColumnLayout {
        spacing: 0
        visible: fullRepresentation.monitor.hasPendingStop || fullRepresentation.monitor.hasStopError

        Kirigami.InlineMessage {
            Layout.fillWidth: true
            type: Kirigami.MessageType.Warning
            text: fullRepresentation.monitor.stopQuestion
            visible: fullRepresentation.monitor.hasPendingStop
            actions: [
                Kirigami.Action {
                    icon.name: "media-playback-stop"
                    text: i18n("Stop")
                    onTriggered: fullRepresentation.monitor.confirmStop()
                },
                Kirigami.Action {
                    icon.name: "dialog-cancel"
                    text: i18n("Cancel")
                    onTriggered: fullRepresentation.monitor.cancelStop()
                }
            ]
        }

        Kirigami.InlineMessage {
            Layout.fillWidth: true
            type: Kirigami.MessageType.Error
            text: fullRepresentation.monitor.stopError
            visible: fullRepresentation.monitor.hasStopError
        }
    }
}
