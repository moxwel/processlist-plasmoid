import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM
import org.kde.iconthemes as KIconThemes

KCM.SimpleKCM {
    id: root

    property alias cfg_icon: iconPicker.currentIcon
    property alias cfg_interval: intervalSpinBox.value
    property alias cfg_count: countSpinBox.value
    property alias cfg_display: displayComboBox.currentIndex
    property alias cfg_showSystemProcesses: showSystemProcessesCheckBox.checked

    property string cfg_iconDefault
    property int cfg_intervalDefault
    property int cfg_countDefault
    property int cfg_displayDefault
    property bool cfg_showSystemProcessesDefault

    readonly property int maxIntervalSec: 600
    readonly property int maxProcessCount: 10
    readonly property real hintOpacity: 0.7

    component IconPicker: RowLayout {
        id: picker

        property string currentIcon
        property string defaultIcon
        readonly property bool isDefault: currentIcon === defaultIcon

        spacing: Kirigami.Units.smallSpacing

        QQC2.Button {
            implicitWidth: Kirigami.Units.iconSizes.large + Kirigami.Units.largeSpacing * 2
            implicitHeight: implicitWidth

            Accessible.name: i18n("Choose icon")
            onClicked: iconDialog.open()

            Kirigami.Icon {
                anchors.centerIn: parent
                width: Kirigami.Units.iconSizes.large
                height: width
                source: picker.currentIcon
            }

            KIconThemes.IconDialog {
                id: iconDialog
                onAccepted: picker.currentIcon = iconName
            }
        }

        QQC2.Button {
            icon.name: "edit-reset"
            display: QQC2.AbstractButton.IconOnly
            text: i18n("Reset to the default icon")
            enabled: !picker.isDefault
            onClicked: picker.currentIcon = picker.defaultIcon

            QQC2.ToolTip.text: text
            QQC2.ToolTip.visible: hovered
            QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
        }
    }

    Kirigami.FormLayout {
        IconPicker {
            id: iconPicker
            Kirigami.FormData.label: i18n("Icon:")
            defaultIcon: root.cfg_iconDefault
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
            to: root.maxProcessCount
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
