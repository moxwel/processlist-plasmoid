import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts

import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM
import org.kde.iconthemes as KIconThemes

KCM.SimpleKCM {
    id: root

    property string cfg_icon: Plasmoid.configuration.icon
    property alias cfg_interval: intervalSpinBox.value
    property alias cfg_count: countSpinBox.value
    property alias cfg_display: displayComboBox.currentIndex
    property alias cfg_showSystemProcesses: showSystemProcessesCheckBox.checked

    property string cfg_iconDefault: ""
    property int cfg_intervalDefault: 3
    property int cfg_countDefault: 5
    property int cfg_displayDefault: 2
    property bool cfg_showSystemProcessesDefault: false

    readonly property int maxIntervalSec: 600
    readonly property real hintOpacity: 0.7

    component IconPicker: QQC2.Button {
        id: picker

        property string currentIcon
        signal picked(string iconName)

        implicitWidth: Kirigami.Units.iconSizes.large + Kirigami.Units.largeSpacing * 2
        implicitHeight: implicitWidth

        onClicked: iconDialog.open()

        Kirigami.Icon {
            anchors.centerIn: parent
            width: Kirigami.Units.iconSizes.large
            height: width
            source: picker.currentIcon
        }

        KIconThemes.IconDialog {
            id: iconDialog
            onIconNameChanged: picker.picked(iconName)
        }
    }

    Kirigami.FormLayout {
        anchors.fill: parent

        RowLayout {
            Kirigami.FormData.label: i18n("Icon:")
            spacing: Kirigami.Units.smallSpacing

            IconPicker {
                currentIcon: root.cfg_icon
                onPicked: iconName => root.cfg_icon = iconName
            }

            QQC2.Button {
                icon.name: "edit-reset"
                display: QQC2.AbstractButton.IconOnly
                text: i18n("Reset to the default icon")
                QQC2.ToolTip.text: text
                QQC2.ToolTip.visible: hovered
                QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
                enabled: root.cfg_icon !== root.cfg_iconDefault
                onClicked: root.cfg_icon = root.cfg_iconDefault
            }
        }

        Item {
            Kirigami.FormData.isSection: true
        }

        QQC2.SpinBox {
            id: intervalSpinBox
            Kirigami.FormData.label: i18n("Update interval:")
            from: 1
            to: root.maxIntervalSec
            textFromValue: value => i18np("%1 second", "%1 seconds", value)
            valueFromText: text => parseInt(text) || from
        }

        QQC2.SpinBox {
            id: countSpinBox
            Kirigami.FormData.label: i18n("Processes count:")
            from: 1
            to: 10
        }

        QQC2.ComboBox {
            id: displayComboBox
            Kirigami.FormData.label: i18n("Display:")
            model: [
                i18n("Icon only"),
                i18n("Percentage only"),
                i18n("Icon and percentage"),
                i18n("Text and percentage"),
            ]
        }

        QQC2.Label {
            text: i18n("With \"Icon only\", the widget stops polling until opened.")
            font: Kirigami.Theme.smallFont
            opacity: root.hintOpacity
            wrapMode: Text.Wrap
        }

        Item {
            Kirigami.FormData.isSection: true
        }

        QQC2.CheckBox {
            id: showSystemProcessesCheckBox
            Kirigami.FormData.label: i18n("Processes:")
            text: i18n("Show system processes")
        }
    }
}
