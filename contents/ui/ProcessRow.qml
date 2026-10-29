import QtQuick
import QtQuick.Layouts

import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami

RowLayout {
    id: row

    required property var modelData
    required property ProcessMonitor monitor

    // look of the row
    readonly property real secondaryOpacity: 0.6
    readonly property real tooltipWidthUnits: 30
    readonly property int tooltipDelayMs: 250

    spacing: Kirigami.Units.smallSpacing

    HoverHandler { id: rowHover }

    PlasmaComponents.ToolTip {
        id: commandTip
        text: row.modelData.command
        delay: row.tooltipDelayMs
        visible: rowHover.hovered && !stopButton.hovered

        contentItem: Item {
            implicitWidth: Math.min(tipLabel.maxWidth, tipLabel.contentWidth)
            implicitHeight: tipLabel.implicitHeight

            PlasmaComponents.Label {
                id: tipLabel
                readonly property real maxWidth: Kirigami.Units.gridUnit * row.tooltipWidthUnits
                text: commandTip.text
                wrapMode: Text.Wrap
                Kirigami.Theme.colorSet: Kirigami.Theme.Tooltip
                Kirigami.Theme.inherit: false
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
            opacity: row.secondaryOpacity
            elide: Text.ElideRight
        }
    }

    PlasmaComponents.Label {
        text: row.modelData.pid
        opacity: row.secondaryOpacity
    }
    PlasmaComponents.Label {
        text: row.modelData.usageText
    }
    PlasmaComponents.ToolButton {
        id: stopButton
        icon.name: "media-playback-stop"
        display: PlasmaComponents.AbstractButton.IconOnly
        text: i18n("Stop '%1' (PID: %2)", row.modelData.name, row.modelData.pid)
        PlasmaComponents.ToolTip.text: text
        PlasmaComponents.ToolTip.visible: hovered
        onClicked: row.monitor.requestStop(row.modelData)
    }
}
