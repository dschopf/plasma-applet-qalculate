//  Copyright (c) 2016 - 2024 Daniel Schopf <schopfdan@gmail.com>
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

import QtQuick 2.15
import QtQuick.Dialogs
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.1

import org.kde.draganddrop 2.0 as DragDrop
import org.kde.iconthemes as KIconThemes
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami 2.20 as Kirigami
import org.kde.ksvg 1.0 as KSvg
import org.kde.plasma.plasmoid 2.0
import org.kde.kcmutils as KCM

import com.dschopf.plasma.qalculate

import "../../code/tools.js" as Tools

KCM.SimpleKCM {

  property var cfg_angleUnit
  property string cfg_qalculateIcon:                Plasmoid.configuration.qalculateIcon
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

  Kirigami.FormLayout {
    anchors.left: parent.left
    anchors.right: parent.right

    CheckBox {
      id: chbCopyResultToClipboard
      Kirigami.FormData.label: i18n("Behavior") + ":"
      text: i18n("Copy result to clipboard")
    }

    Kirigami.InlineMessage {
        Layout.fillWidth: true
        visible: chbCopyResultToClipboard.checked && chbLiveEvaluation.checked
        showCloseButton: true
        type: Kirigami.MessageType.Warning
        text: i18n("Only works when pressing \"Return\"")
    }

    CheckBox {
      id: chbWriteResultsInInputLineEdit
      text: i18n("Write results in input line edit")
    }

    Kirigami.InlineMessage {
        Layout.fillWidth: true
        visible: chbWriteResultsInInputLineEdit.checked && chbLiveEvaluation.checked
        showCloseButton: true
        type: Kirigami.MessageType.Warning
        text: i18n("Only works when pressing \"Return\"")
    }

    CheckBox {
      id: chbLiveEvaluation
      text: i18n("Live evaluation")
    }

    Kirigami.ActionTextField {
      id: tfTimeout
      Kirigami.FormData.label: i18n('Calculation timeout') + " (ms) :"
      text: Plasmoid.configuration.timeout
      validator: IntValidator { bottom: 0; top: 9999999; }
      rightActions: [
        Action {
          icon.name: "edit-reset"
          text: i18n("Reset to default value")
          onTriggered: {
              tfTimeout.text = '10000'
              cfg_timeout = '10000'
          }
        }
      ]
      onAccepted: cfg_timeout = tfTimeout.text
    }

    Button {
        id: iconButton

        Kirigami.FormData.label: i18n("Icon") + ":"

        implicitWidth: previewFrame.width + Kirigami.Units.smallSpacing * 2
        implicitHeight: previewFrame.height + Kirigami.Units.smallSpacing * 2

        // Just to provide some visual feedback when dragging;
        // cannot have checked without checkable enabled
        checkable: true
        checked: dropArea.containsAcceptableDrag

        onPressed: iconMenu.opened ? iconMenu.close() : iconMenu.open()

        DragDrop.DropArea {
            id: dropArea

            property bool containsAcceptableDrag: false

            anchors.fill: parent

            onDragEnter: {
                // Cannot use string operations (e.g. indexOf()) on "url" basic type.
                var urlString = event.mimeData.url.toString();

                // This list is also hardcoded in KIconDialog.
                var extensions = [".png", ".xpm", ".svg", ".svgz"];
                containsAcceptableDrag = urlString.indexOf("file:///") === 0 && extensions.some(function (extension) {
                    return urlString.indexOf(extension) === urlString.length - extension.length; // "endsWith"
                });

                if (!containsAcceptableDrag) {
                    event.ignore();
                }
            }
            onDragLeave: containsAcceptableDrag = false

            onDrop: {
                if (containsAcceptableDrag) {
                    // Strip file:// prefix, we already verified in onDragEnter that we have only local URLs.
                    iconDialog.setCustomButtonImage(event.mimeData.url.toString().substr("file://".length));
                }
                containsAcceptableDrag = false;
            }
        }

        KIconThemes.IconDialog {
            id: iconDialog
            onIconNameChanged: cfg_qalculateIcon = iconName
        }

        KSvg.FrameSvgItem {
            id: previewFrame
            anchors.centerIn: parent
            imagePath: Plasmoid.location === PlasmaCore.Types.Vertical || Plasmoid.location === PlasmaCore.Types.Horizontal
                    ? "widgets/panel-background" : "widgets/background"
            width: Kirigami.Units.iconSizes.large + fixedMargins.left + fixedMargins.right
            height: Kirigami.Units.iconSizes.large + fixedMargins.top + fixedMargins.bottom

            Kirigami.Icon {
                anchors.centerIn: parent
                width: Kirigami.Units.iconSizes.large
                height: width
                source: cfg_qalculateIcon
            }
        }

        Menu {
            id: iconMenu

            // Appear below the button
            y: +parent.height

            onClosed: iconButton.checked = false;

            MenuItem {
                text: i18nc("Open icon chooser dialog", "Choose Icon")
                icon.name: "document-open-folder"
                onClicked: iconDialog.open()
            }
            MenuItem {
                text: i18nc("Reset icon to default", "Clear Icon")
                icon.name: "edit-clear"
                onClicked: cfg_qalculateIcon = Tools.stripProtocol(Qt.resolvedUrl('../../images/Qalculate.svg').toString())
            }
        }
    }

    Item {
      Kirigami.FormData.isSection: true
    }

    CheckBox {
      id: chbEnableLauncher
      text: i18n("Launch program when clicking the Q! logo in the Plasmoid")
    }

    RowLayout {
      Layout.fillWidth: true

      Kirigami.ActionTextField {
        id: tfExecutable
        text: i18n('Executable')
        enabled: chbEnableLauncher.checked
        Layout.fillWidth: true
        rightActions: [
          Action {
            icon.name: "edit-clear"
            text: i18n("Clear the field")
            onTriggered: {
                tfExecutable.clear()
            }
          }
        ]
      }

      Button {
        id: executableButton
        icon.name: "system-run"
        width: Kirigami.Units.iconSizes.large
        height: width
        enabled: chbEnableLauncher.checked

        FileDialog {
          id: executableDialog
          title: i18n("Please select an executable")
          onAccepted: cfg_launcherExecutable = Tools.stripProtocol(Qt.resolvedUrl(executableDialog.fileUrl).to_string())
        }

        onClicked: executableDialog.open()
      }
    }

    RowLayout {
      spacing: Kirigami.Units.smallSpacing
      Layout.fillWidth: true

      CheckBox {
        id: chbCmdlinArgs
        text: i18n("Arguments")
        enabled: chbEnableLauncher.checked
      }

      TextField {
        id: tfArguments
        Layout.alignment: Qt.AlignVCenter
        Layout.fillWidth: true
        enabled: chbEnableLauncher.checked && chbCmdlinArgs.checked
      }
    }

    Kirigami.InlineMessage {
      Layout.fillWidth: true
      visible: tfArguments.enabled
      showCloseButton: true
      text: i18n("${INPUT} will be replaced with the current input string")
    }

    Item {
      Kirigami.FormData.isSection: true
    }

    CheckBox {
      id: chbHistoryDisabled
      text: i18n("Disable input history")
      Kirigami.FormData.label: i18n("Input history") + ":"
    }

    SpinBox {
      id: sbHistorySize
      stepSize: 1
      from: 1
      to: 1e7
      enabled: !chbHistoryDisabled.checked
    }

    Label {
      visible: !chbHistoryDisabled.checked && qwr.historyFilename() != ""
      text: i18n("History entries are stored in this file") + ": " + qwr.historyFilename()
    }
  }

  footer: ColumnLayout {
    Kirigami.InlineMessage {
      Layout.fillWidth: true
      visible: chbLiveEvaluation.checked && chbHistoryDisabled.checked
      showCloseButton: true
      text: i18n("History entries are only created by pressing Enter when \"Live evaluation\" is enabled!")
    }
  }
}
