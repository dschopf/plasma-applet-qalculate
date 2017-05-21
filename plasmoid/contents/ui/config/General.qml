/*
    Copyright 2016 Daniel Schopf <schopfdan@gmail.com>

    This library is free software; you can redistribute it and/or
    modify it under the terms of the GNU Lesser General Public
    License as published by the Free Software Foundation; either
    version 2.1 of the License, or (at your option) version 3, or any
    later version accepted by the membership of KDE e.V. (or its
    successor approved by the membership of KDE e.V.), which shall
    act as a proxy defined in Section 6 of version 3 of the license.

    This library is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
    Lesser General Public License for more details.

    You should have received a copy of the GNU Lesser General Public
    License along with this library.  If not, see <http://www.gnu.org/licenses/>.
*/

import QtQuick 2.0
import QtQuick.Controls 1.0
import QtQuick.Layouts 1.0

import org.kde.plasma.components 2.0 as PlasmaComponents
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.kquickcontrolsaddons 2.0 as KQuickAddons

import "../../code/tools.js" as Tools

Item {
  property string cfg_qalculateIcon:                plasmoid.configuration.qalculateIcon
  property alias cfg_copyResultToClipboard:         chbCopyResultToClipboard.checked
  property alias cfg_writeResultsInInputLineEdit:   chbWriteResultsInInputLineEdit.checked
  property alias cfg_liveEvaluation:                chbLiveEvaluation.checked
  property alias cfg_timeout:                       tfTimeout.text
  property alias cfg_historyDisabled:               chbHistoryDisabled.checked
  property alias cfg_historySize:                   sbHistorySize.value

  GridLayout {
    anchors.left: parent.left
    anchors.right: parent.right
    columns: 2

    CheckBox {
      id: chbCopyResultToClipboard
      text: i18n("Copy result to clipboard")
      tooltip: i18n("Only works when pressing Return")
      Layout.columnSpan: 2
    }

    CheckBox {
      id: chbWriteResultsInInputLineEdit
      text: i18n("Write results in input line edit")
      tooltip: i18n("Only works when pressing Return")
      Layout.columnSpan: 2
    }

    CheckBox {
      id: chbLiveEvaluation
      text: i18n("Live evaluation")
      Layout.columnSpan: 2
    }

    Label {
      text: i18n('Calculation timeout') + " (ms) :"
      Layout.alignment: Qt.AlignVCenter|Qt.AlignRight
    }

    PlasmaComponents.TextField {
      id: tfTimeout
      validator: IntValidator { bottom: 0; top: 9999999; }
    }

    RowLayout {
      spacing: units.smallSpacing
      Layout.alignment: Qt.AlignVCenter|Qt.AlignRight

      Label {
        text: i18n("Icon") + ":"
      }

      Button {
        id: iconButton
        Layout.minimumWidth: previewFrame.width + units.smallSpacing * 2
        Layout.maximumWidth: Layout.minimumWidth
        Layout.minimumHeight: previewFrame.height + units.smallSpacing * 2
        Layout.maximumHeight: Layout.minimumWidth

        KQuickAddons.IconDialog {
          id: iconDialog
          onIconNameChanged: cfg_qalculateIcon = iconName
        }

        // just to provide some visual feedback, cannot have checked without checkable enabled
        checkable: true
        onClicked: {
          checked = Qt.binding(function() { // never actually allow it being checked
            return iconMenu.status === PlasmaComponents.DialogStatus.Open
          })

          iconMenu.open(0, height)
        }

        PlasmaCore.FrameSvgItem {
          id: previewFrame
          anchors.centerIn: parent
          imagePath: plasmoid.location === PlasmaCore.Types.Vertical || plasmoid.location === PlasmaCore.Types.Horizontal
            ? "widgets/panel-background" : "widgets/background"
          width: units.iconSizes.large + fixedMargins.left + fixedMargins.right
          height: units.iconSizes.large + fixedMargins.top + fixedMargins.bottom

          PlasmaCore.IconItem {
            anchors.centerIn: parent
            width: units.iconSizes.large
            height: width
            source: cfg_qalculateIcon
          }
        }
      }

      // QQC Menu can only be opened at cursor position, not a random one
      PlasmaComponents.ContextMenu {
        id: iconMenu
        visualParent: iconButton

        PlasmaComponents.MenuItem {
          text: i18nc("Open icon chooser dialog", "Choose Icon")
          icon: "document-open-folder"
          onClicked: iconDialog.open()
        }
        PlasmaComponents.MenuItem {
          text: i18nc("Reset icon to default", "Clear Icon")
          icon: "edit-clear"
          onClicked: cfg_qalculateIcon = Tools.stripProtocol(Qt.resolvedUrl('../../images/Qalculate.svg'))
        }
      }
    }

    GroupBox {
      title: i18n("Input history")
      flat: false
      checkable: false
      Layout.fillWidth: true
      Layout.columnSpan: 2

      GridLayout {
        anchors.left: parent.left
        anchors.right: parent.right
        columns: 2

        Item {
          Layout.columnSpan: 2
          height: 5
        }

        CheckBox {
          id: chbHistoryDisabled
          text: i18n("Disable input history")
          tooltip: i18n("Only works when pressing Return")
          Layout.columnSpan: 2
        }

        Label {
          text: i18n("History size") + ':'
          Layout.alignment: Qt.AlignVCenter|Qt.AlignRight
          enabled: !chbHistoryDisabled.checked
        }

        SpinBox {
          id: sbHistorySize
          decimals: 0
          stepSize: 1
          minimumValue: 1
          maximumValue: 1e7
          enabled: !chbHistoryDisabled.checked
        }
      }
    }
  }
}
