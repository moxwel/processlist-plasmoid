import QtQuick
import QtQuick.Layouts

import org.kde.plasma.plasmoid
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami

MouseArea {
    id: compactArea

    required property PlasmoidItem plasmoidItem

    Layout.minimumWidth: layout.implicitWidth
    hoverEnabled: true
    onClicked: plasmoidItem.togglePopup()

    activeFocusOnTab: true
    Accessible.name: Plasmoid.title
    Accessible.description: plasmoidItem.tooltipText
    Accessible.role: Accessible.Button
    Accessible.onPressAction: plasmoidItem.togglePopup()

    Keys.onPressed: event => {
        const isActivationKey = [Qt.Key_Space, Qt.Key_Enter, Qt.Key_Return, Qt.Key_Select].includes(event.key);
        if (!isActivationKey) return;
        compactArea.plasmoidItem.togglePopup();
        event.accepted = true;
    }

    RowLayout {
        id: layout
        anchors.fill: parent
        spacing: Kirigami.Units.smallSpacing

        Kirigami.Icon {
            source: compactArea.plasmoidItem.appIcon
            active: compactArea.containsMouse || compactArea.activeFocus
            visible: compactArea.plasmoidItem.isIconDisplayed
            Layout.fillHeight: true
            Layout.preferredWidth: height
        }
        PlasmaComponents.Label {
            text: compactArea.plasmoidItem.compactText
            visible: compactArea.plasmoidItem.isPercentDisplayed
        }
    }
}
