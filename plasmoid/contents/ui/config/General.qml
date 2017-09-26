//  Copyright (c) 2016 - 2017 Daniel Schopf <schopfdan@gmail.com>
//
//  Permission is hereby granted, free of charge, to any person obtaining
//  a copy of this software and associated documentation files (the "Software"),
//  to deal in the Software without restriction, including without limitation
//  the rights to use, copy, modify, merge, publish, distribute, sublicense,
//  and/or sell copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
//  IN THE SOFTWARE.

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
