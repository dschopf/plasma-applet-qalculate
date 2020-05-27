//  Copyright (c) 2016 - 2019 Daniel Schopf <schopfdan@gmail.com>
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

import QtQuick 2.7
import QtQuick.Controls 1.4
import QtQuick.Layouts 1.0

import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 2.0 as PlasmaComponents
import org.kde.kquickcontrolsaddons 2.0 as KQuickControlsAddons

import "../code/tools.js" as Tools

Item {
  id: fullRepresentation

  property bool binary_enabled: plasmoid.configuration.binary && plasmoid.configuration.resultBase !== 2
  property bool octal_enabled: plasmoid.configuration.octal && plasmoid.configuration.resultBase !== 8
  property bool decimal_enabled: plasmoid.configuration.decimal && plasmoid.configuration.resultBase !== 10
  property bool hex_enabled: plasmoid.configuration.hexadecimal && plasmoid.configuration.resultBase !== 16
  property string current_input: ""
  property string last_input: ""

  anchors.fill: parent

  Layout.minimumHeight: units.gridUnit * 10 // 150
  Layout.minimumWidth: units.gridUnit * 15 // 200
  Layout.preferredHeight: units.gridUnit * 10 // 150
  Layout.preferredWidth: units.gridUnit * 15 // 200

  KQuickControlsAddons.Clipboard {
    id: clipboard
  }

  Keys.onPressed: {
    // ignore ESC (27) and TAB (9)
    if (!inputQuery.focus && event.text.charCodeAt(0) != 27 && event.text.charCodeAt(0) != 9) {
      inputQuery.forceActiveFocus();
      inputQuery.text += event.text
    }
  }

  PlasmaComponents.ContextMenu {
    id: contextMenu

    function show(item, x, y) {
      visualParent = item
      open(x, y)
    }

    PlasmaComponents.MenuItem {
      id: menuitem_copy
      text: i18n("Copy result to clipboard")
      icon: "edit-copy"
      enabled: lResult.visible
      onClicked: clipboard.content = lResult.text
    }

    PlasmaComponents.MenuItem {
      id: menuitem_submenu

      text: i18n("Copy result as")
      icon: "edit-copy"
      enabled: lResult.visible
      visible: outputBinary.visible || outputOctal.visible || outputDecimal.visible || outputHex.visible

      property variant submenu: submenu_copybase

      PlasmaComponents.ContextMenu {
        id: submenu_copybase
        visualParent: menuitem_submenu.action

        PlasmaComponents.MenuItem {
          id: menuitem_copybase2
          text: i18n("Binary")
          icon: "edit-copy"
          enabled: lResult.visible
          visible: outputBinary.visible
          onClicked: clipboard.content = outputBinary.text
        }

        PlasmaComponents.MenuItem {
          id: menuitem_copybase8
          text: i18n("Octal")
          icon: "edit-copy"
          enabled: lResult.visible
          visible: outputOctal.visible
          onClicked: clipboard.content = outputOctal.text
        }

        PlasmaComponents.MenuItem {
          id: menuitem_copybase10
          text: i18n("Decimal")
          icon: "edit-copy"
          enabled: lResult.visible
          visible: outputDecimal.visible
          onClicked: clipboard.content = outputDecimal.text
        }

        PlasmaComponents.MenuItem {
          id: menuitem_copybase16
          text: i18n("Hexadecimal")
          icon: "edit-copy"
          enabled: lResult.visible
          visible: outputHex.visible
          onClicked: clipboard.content = outputHex.text
        }
      }
    }
  }

  MouseArea {
    anchors.fill: parent
    acceptedButtons: Qt.RightButton
    onPressed: contextMenu.show(this, mouse.x, mouse.y)
    enabled: true
  }

  RowLayout {
    id: topRowLayout
    z: 1
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.left: parent.left
    Layout.fillWidth: true
    Layout.fillHeight: false

    PlasmaComponents.TextField {
      id: inputQuery
      Layout.alignment: Qt.AlignTop | Qt.AlignLeft
      Layout.fillWidth: true
      focus: true
      clearButtonShown: true
      placeholderText: i18n("Enter an expression")
      inputMethodHints: Qt.ImhNoPredictiveText

      onAccepted: {
        if (clHistory.visible) {
          clHistory.visible = false
          clMain.visible = true
        }
        onNewInput(text, true)
      }

      onTextChanged: {
        if (text == "" && clHistory.visible) {
          clHistory.visible = false
          clMain.visible = true
        }
        if (plasmoid.configuration.liveEvaluation && !clHistory.visible)
          onNewInput(text, false)
      }

      Keys.onPressed: {
        if (event.key == Qt.Key_Escape) {
          event.accepted = true
          if (clHistory.visible) {
            clMain.visible = true
            clHistory.visible = false
            text = current_input
          } else if (main.fromCompact) {
            plasmoid.expanded = !plasmoid.expanded
            keepOpen.checked = false
          }
          return
        }

        // need a better way to clear the input field
        var mods = Qt.ControlModifier | Qt.AltModifier
        if ((event.key == Qt.Key_C) && (event.modifiers & mods) == mods) {
          event.accepted = true
          text = ""
          return
        }

        if (event.key == Qt.Key_Up) {
          event.accepted = true
          if (qwr.historyEntries() == 0)
            return
          if (!clHistory.visible) {
            clMain.visible = true
            clHistory.visible = false
            current_input = text
          } else {
            historyList.decrementCurrentIndex()
          }
          text = historyList.currentItem.text
          return
        }

        if (event.key == Qt.Key_Down) {
          event.accepted = true
          if (qwr.historyEntries() == 0)
            return
          if (!clHistory.visible) {
            clHistory.visible = true
            clMain.visible = false
            current_input = text
          } else {
            historyList.incrementCurrentIndex()
          }
          text = historyList.currentItem.text
          return
        }

        if (event.key == Qt.Key_PageUp) {
          event.accepted = true
          if (qwr.historyEntries() == 0)
            return
          if (clHistory.visible) {
            var temp = historyList.highlightMoveVelocity
            historyList.highlightMoveVelocity = 40000
            historyList.positionViewAtBeginning()
            historyList.currentIndex = 0
            historyList.highlightMoveVelocity = temp
            text = historyList.currentItem.text
          }
          return
        }

        if (event.key == Qt.Key_PageDown) {
          event.accepted = true
          if (qwr.historyEntries() == 0)
            return
          if (clHistory.visible) {
            var temp = historyList.highlightMoveVelocity
            historyList.highlightMoveVelocity = 40000
            historyList.positionViewAtEnd()
            historyList.currentIndex = historyList.count - 1
            historyList.highlightMoveVelocity = temp
            text = historyList.currentItem.text
          }
          return
        }

        if (event.key == Qt.Key_Enter || event.key == Qt.Key_Return) {
          selectAll()
        }
      }
    }
  }

  // invisible TextEdit for copying the result to the clipboard
  TextEdit {
    id: clipcopy
    visible: false
  }

  ColumnLayout {
    id: clHistory
    spacing: 0
    anchors.top: topRowLayout.bottom
    anchors.horizontalCenter: parent.horizontalCenter
    width: parent.width
    height: parent.height - topRowLayout.height
    visible: false

    Component {
      id: historyDelegate
      Item {
        id: historyItem
        height: historyText.height
        width: historyList.width
        property alias text: historyText.text
        Text {
          id: historyText
          color: theme.textColor
          text: history
          x: 5
          width: parent.width
        }
        MouseArea {
          anchors.fill: parent
          onClicked: {
            historyList.currentIndex = index
            inputQuery.text = historyList.currentItem.text
          }
        }
      }
    }

    Component {
      id: highlightBar
      PlasmaComponents.Highlight {
        width: historyList.width
        height: historyList.currentItem.height
        y: historyList.currentItem.y;
      }
    }

    ListView {
      id: historyList
      Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
      Layout.fillHeight: true
      Layout.fillWidth: true
      spacing: 1
      model: qwr.getModel()
      delegate: historyDelegate
      highlight: highlightBar
      highlightFollowsCurrentItem: false
      focus: true
      clip: true
    }
  }

  ColumnLayout {
    id: clMain
    spacing: 0
    anchors.top: topRowLayout.bottom
    anchors.horizontalCenter: parent.horizontalCenter
    width: parent.width
    height: parent.height - topRowLayout.height

    PlasmaCore.SvgItem {
      id: qalculateFullIcon
      visible: true
      Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
      Layout.fillHeight: true
      Layout.fillWidth: true
      Layout.maximumHeight: Math.min(parent.height, parent.width)
      Layout.maximumWidth: Layout.maximumHeight
      Layout.preferredHeight: Math.min(parent.height, parent.width)
      Layout.preferredWidth: Layout.preferredHeight
      smooth: true

      svg: PlasmaCore.Svg {
        imagePath: Tools.stripProtocol(Qt.resolvedUrl('../images/Qalculate.svg'))
      }

      MouseArea {
        anchors.fill: parent
        onClicked: {
          if (plasmoid.configuration.launcherEnabled) {
            if (plasmoid.configuration.launcherArgsEnabled)
              qwr.launch(plasmoid.configuration.launcherExecutable, plasmoid.configuration.launcherArguments, inputQuery.text)
            else
              qwr.launch(plasmoid.configuration.launcherExecutable)
          }
        }
      }
    }

    BusyIndicator {
      id: busy
      visible: false
      running: true
      Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
      Layout.fillHeight: true
      Layout.fillWidth: true
      Layout.margins: 50
    }

    Timer {
      id: busyTimer
      interval: 50
      running: false
      repeat: false
      onTriggered: {
        busy.visible = true
        clearOutput()
      }
    }

    ColumnLayout {
      id: clResult
      spacing: 0
      Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
      Layout.maximumWidth: parent.width

      RowLayout {
        id: rlResult
        spacing: 0
        Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter

        FontMetrics {
          id: fontMetrics
          font: lResult.font
        }

        TextEdit {
          id: lResult
          text: i18n("Result")
          visible: false
          readOnly: true
          selectByMouse: true
          color: theme.textColor
          Layout.alignment: Qt.AlignHCenter
          font.bold: true
          font.pixelSize: 40

          Connections {
            target: qwr

            function onResultText(result, resultBase2, resultBase8, resultBase10, resultBase16) {
              busyTimer.stop()
              busy.visible = false

              if (!result.length) {
                lResult.visible = false
                lResult.text = ""
                loutputBase.visible = false
                outputBinary.visible = false
                outputBinary.text = ""
                outputOctal.visible = false
                outputOctal.text = ""
                outputDecimal.visible = false
                outputDecimal.text = ""
                outputHex.visible = false
                outputHex.text = ""
                return
              }

              lResult.visible = true
              lResult.text = result

              lResult.font.pixelSize = 40

              if (result.length * fontMetrics.averageCharacterWidth > fullRepresentation.width * 0.95) {
                while (result.length * fontMetrics.averageCharacterWidth > fullRepresentation.width * 0.95) {
                  lResult.font.pixelSize = lResult.font.pixelSize * 0.85
                }
              }

              if (plasmoid.configuration.resultBase !== 10) {
                loutputBase.visible = true
                loutputBase.anchors.left = lResult.right
                loutputBase.anchors.top = lResult.verticalCenter
              } else {
                loutputBase.visible = false
              }

              if (binary_enabled && resultBase2.length) {
                outputBinary.visible = resultBase2.length
                outputBinary.text = "0b" + resultBase2
              } else {
                outputBinary.visible = false
              }

              if (octal_enabled && resultBase8.length) {
                outputOctal.visible = resultBase8.length
                outputOctal.text = "0o" + resultBase8
              } else {
                outputOctal.visible = false
              }

              if (decimal_enabled && resultBase10.length) {
                outputDecimal.visible = resultBase10.length
                outputDecimal.text = resultBase10
              } else {
                outputDecimal.visible = false
              }

              if (hex_enabled && resultBase16.length) {
                outputHex.visible = resultBase16.length
                outputHex.text = "0x" + resultBase16
              } else {
                outputHex.visible = false
              }

              if (!plasmoid.configuration.liveEvaluation) {
                if (plasmoid.configuration.copyResultToClipboard) {
                  clipcopy.text = result
                  clipcopy.selectAll()
                  clipcopy.copy()
                }

                if (plasmoid.configuration.writeResultsInInputLineEdit)
                  text = lResult.text
              }
            }

            function onCalculationTimeout() {
              lResult.text = i18n("Calculation timed out")
              lResult.visible = true
              busy.visible = false
            }
          }
        }

        Label {
          id: loutputBase
          text: plasmoid.configuration.resultBase
          visible: false
          color: theme.textColor
          Layout.minimumHeight: 0
          Layout.maximumHeight: 0
          font.bold: true
          font.pixelSize: Math.round(0.9 * units.gridUnit)
        }
      }

      TextEdit {
        id: outputBinary
        text: "ResultBinary"
        visible: false
        readOnly: true
        selectByMouse: true
        color: theme.textColor
        Layout.alignment: Qt.AlignHCenter
        Layout.maximumWidth: parent.width
        font.pixelSize: units.gridUnit
      }

      TextEdit {
        id: outputOctal
        text: "ResultOctal"
        visible: false
        readOnly: true
        selectByMouse: true
        color: theme.textColor
        Layout.alignment: Qt.AlignHCenter
        font.pixelSize: units.gridUnit
      }

      TextEdit {
        id: outputDecimal
        text: "ResultDecimal"
        visible: false
        readOnly: true
        selectByMouse: true
        color: theme.textColor
        Layout.alignment: Qt.AlignHCenter
        font.pixelSize: units.gridUnit
      }

      TextEdit {
        id: outputHex
        text: "ResultHex"
        visible: false
        readOnly: true
        selectByMouse: true
        color: theme.textColor
        Layout.alignment: Qt.AlignHCenter
        font.pixelSize: units.gridUnit
      }
    }
  }

  PlasmaComponents.ToolButton {
    id: keepOpen
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    width: Math.round(units.gridUnit * 1.25)
    height: width
    checkable: true
    iconSource: "window-pin"
    visible: main.fromCompact
    onCheckedChanged: plasmoid.hideOnWindowDeactivate = !checked
  }

  PlasmaCore.SvgItem {
    id: qalculateSmallIcon
    visible: !qalculateFullIcon.visible && !clHistory.visible
    anchors.left: parent.left
    anchors.bottom: parent.bottom
    smooth: true
    width: Math.round(units.gridUnit * 1.25)
    height: width

    svg: PlasmaCore.Svg {
      imagePath: Tools.stripProtocol(Qt.resolvedUrl('../images/Qalculate.svg'))
    }

    MouseArea {
      anchors.fill: parent
      onClicked: {
        if (plasmoid.configuration.launcherEnabled) {
          if (plasmoid.configuration.launcherArgsEnabled)
              qwr.launch(plasmoid.configuration.launcherExecutable, plasmoid.configuration.launcherArguments, inputQuery.text)
            else
              qwr.launch(plasmoid.configuration.launcherExecutable)
        }
      }
    }
  }

  function onNewInput(input, enter) {
    if (!input.length) {
      busyTimer.stop()
      qalculateFullIcon.visible = true
      busy.visible = false
      last_input = ""
      clearOutput()
      return
    }
    if (input !== last_input || enter == true) {
      qalculateFullIcon.visible = false
      last_input = input
      qwr.evaluate(input, enter)
      busyTimer.start()
    }
  }

  function clearOutput() {
    lResult.visible = false
    loutputBase.visible = false
    outputBinary.visible = false
    outputBinary.text = ""
    outputOctal.visible = false
    outputOctal.text = ""
    outputDecimal.visible = false
    outputDecimal.text = ""
    outputHex.visible = false
    outputHex.text = ""
  }
}
