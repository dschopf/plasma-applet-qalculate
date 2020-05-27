//  Copyright (c) 2016 - 2020 Daniel Schopf <schopfdan@gmail.com>
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
import QtQuick.Controls 2.2
import QtQuick.Dialogs 1.2
import QtQuick.Layouts 1.0

import org.kde.plasma.components 2.0 as PlasmaComponents
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.kquickcontrolsaddons 2.0 as KQuickAddons

import org.kde.private.qalculate 1.0

import "../../code/tools.js" as Tools

Item {
  property string cfg_qalculateIcon:                plasmoid.configuration.qalculateIcon
  property alias cfg_copyResultToClipboard:         chbCopyResultToClipboard.checked
  property alias cfg_writeResultsInInputLineEdit:   chbWriteResultsInInputLineEdit.checked
  property alias cfg_liveEvaluation:                chbLiveEvaluation.checked
  property alias cfg_timeout:                       tfTimeout.text
  property alias cfg_launcherEnabled:               chbEnableLauncher.checked
  property alias cfg_launcherExecutable:            tfExecutable.text
  property alias cfg_launcherArgsEnabled:           chbCmdlinArgs.checked
  property alias cfg_launcherArguments:             tfArguments.text
  property alias cfg_historyDisabled:               chbHistoryDisabled.checked
  property alias cfg_historySize:                   sbHistorySize.value

  QWrapper {
    id: qwr
  }

  GridLayout {
    id: grid
    anchors.left: parent.left
    anchors.right: parent.right
    columns: 2

    CheckBox {
      id: chbCopyResultToClipboard
      text: i18n("Copy result to clipboard")
      Layout.columnSpan: 2

      PlasmaCore.ToolTipArea {
        anchors.fill: parent
        subText: i18n("Only works when pressing Return")
      }
    }

    CheckBox {
      id: chbWriteResultsInInputLineEdit
      text: i18n("Write results in input line edit")
      Layout.columnSpan: 2

      PlasmaCore.ToolTipArea {
        anchors.fill: parent
        subText: i18n("Only works when pressing Return")
      }
    }

    CheckBox {
      id: chbLiveEvaluation
      text: i18n("Live evaluation")
      Layout.columnSpan: 2
    }

    Item {
      Layout.preferredWidth: 0.5 * parent.width
      Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
      Layout.preferredHeight: calcLabel.height

      Label {
        id: calcLabel
        text: i18n('Calculation timeout') + " (ms) :"
        anchors.right: parent.right
      }
    }

    Item {
      Layout.preferredWidth: 0.5 * parent.width
      Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft
      Layout.preferredHeight: tfTimeout.height

      PlasmaComponents.TextField {
        id: tfTimeout
        validator: IntValidator { bottom: 0; top: 9999999; }
        anchors.left: parent.left
      }
    }

    RowLayout {
      spacing: units.smallSpacing
      Layout.preferredWidth: parent.width
      Layout.columnSpan: 2

      Item {
        // Layout.preferredWidth: 0.5 * parent.width
        Layout.preferredHeight: previewFrame.height
        Layout.alignment: Qt.AlignVCenter | Qt.AlignRight

        Label {
          text: i18n("Icon") + ":"
          anchors.right: parent.right
          anchors.verticalCenter: parent.verticalCenter
        }
      }

      Item {
        // Layout.preferredWidth: 0.5 * parent.width
        Layout.preferredHeight: previewFrame.height
        Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft

        Button {
          id: iconButton
          anchors.left: parent.left

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
            anchors.left: parent.left
            anchors.top: parent.top
            imagePath: plasmoid.location === PlasmaCore.Types.Vertical || plasmoid.location === PlasmaCore.Types.Horizontal
              ? "widgets/panel-background" : "widgets/background"
            width: iconPreview.width + fixedMargins.left + fixedMargins.right
            height: iconPreview.height + fixedMargins.top + fixedMargins.bottom

            onWidthChanged: {
              iconButton.width = width
              iconButton.height = height
            }

            PlasmaCore.IconItem {
              id: iconPreview
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
    }

    Item {
      Layout.columnSpan: 2
      height: 5
    }

    CheckBox {
      id: chbEnableLauncher
      text: i18n("Launch program when clicking the Q! logo in the Plasmoid")
      Layout.columnSpan: 2
    }

    RowLayout {
      spacing: units.smallSpacing
      Layout.maximumWidth: parent.width
      Layout.columnSpan: 2

      Label {
        text: i18n('Executable')
        Layout.alignment: Qt.AlignVCenter
        enabled: chbEnableLauncher.checked
      }

      PlasmaComponents.TextField {
        id: tfExecutable
        Layout.alignment: Qt.AlignVCenter
        Layout.fillWidth: true
        enabled: chbEnableLauncher.checked
      }

      Button {
        id: executableButton
        icon.name: "system-run"
        width: units.iconSizes.large
        height: width
        enabled: chbEnableLauncher.checked

        FileDialog {
          id: executableDialog
          title: i18n("Please select an executable")
          folder: shortcuts.home
          onAccepted: cfg_launcherExecutable = Tools.stripProtocol(Qt.resolvedUrl(executableDialog.fileUrl))
        }

        onClicked: executableDialog.open()
      }
    }

    RowLayout {
      spacing: units.smallSpacing
      Layout.maximumWidth: parent.width
      Layout.columnSpan: 2

      CheckBox {
        id: chbCmdlinArgs
        text: i18n("Arguments")
        enabled: chbEnableLauncher.checked
      }

      PlasmaComponents.TextField {
        id: tfArguments
        Layout.alignment: Qt.AlignVCenter
        Layout.fillWidth: true
        enabled: chbEnableLauncher.checked && chbCmdlinArgs.checked

        PlasmaCore.ToolTipArea {
          anchors.fill: parent
          subText: "${INPUT} will be replaced with the current input string"
        }
      }
    }

    Item {
      Layout.columnSpan: 2
      height: 5
    }

    GroupBox {
      Layout.preferredWidth: parent.width
      Layout.columnSpan: 2

      background: Rectangle {
        width: parent.width
        color: "transparent"
        border.color: Qt.darker(theme.viewTextColor)
        radius: 5
      }

      label: Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: height/2
        color: "transparent"
        height: title.font.pixelSize
        Text {
          id: title
          text: i18n("Input history")
          anchors.centerIn: parent
          color: theme.textColor
        }
      }

      ColumnLayout {
        Layout.minimumWidth: parent.width

        Item {
          height: 5
        }

        CheckBox {
          id: chbHistoryDisabled
          text: i18n("Disable input history")
        }

        RowLayout {
          Item {
            Layout.preferredWidth: grid.width * 0.5
            Layout.preferredHeight: lbHistorySize.height
            Layout.alignment: Qt.AlignRight

            Label {
              id: lbHistorySize
              anchors.right: parent.right
              Layout.alignment: Qt.AlignVCenter
              text: i18n("History size") + ':'
              enabled: !chbHistoryDisabled.checked
            }
          }

          SpinBox {
            Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft
            id: sbHistorySize
            stepSize: 1
            from: 1
            to: 1e7
            enabled: !chbHistoryDisabled.checked
          }
        }

        Label {
          visible: chbLiveEvaluation.checked
          enabled: !chbHistoryDisabled.checked
          text: i18n("History entries are only created by pressing Enter when \"Live evaluation\" is enabled!")
        }

        Label {
          visible: chbLiveEvaluation.checked && qwr.historyFilename() != ""
          enabled: !chbHistoryDisabled.checked
          text: i18n("History entries can be edited in this file: ") + qwr.historyFilename()
        }
      }
    }
  }
}
