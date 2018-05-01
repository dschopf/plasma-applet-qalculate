//  Copyright (c) 2016 - 2018 Daniel Schopf <schopfdan@gmail.com>
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
import QtQuick.Controls 1.4
import QtQuick.Layouts 1.0

import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 2.0 as PlasmaComponents

import "../code/tools.js" as Tools

Item {
  id: fullRepresentation

  property bool binary_enabled: plasmoid.configuration.binary && plasmoid.configuration.resultBase !== 2
  property bool octal_enabled: plasmoid.configuration.octal && plasmoid.configuration.resultBase !== 8
  property bool decimal_enabled: plasmoid.configuration.decimal && plasmoid.configuration.resultBase !== 10
  property bool hex_enabled: plasmoid.configuration.hexadecimal && plasmoid.configuration.resultBase !== 16
  property bool is_current_line: true

  property string last_input: ""
  property string current_line: ""

  anchors.fill: parent

  Layout.minimumHeight: units.gridUnit * 10 // 150
  Layout.minimumWidth: units.gridUnit * 15 // 200
  Layout.preferredHeight: units.gridUnit * 10 // 150
  Layout.preferredWidth: units.gridUnit * 15 // 200

  RowLayout {
    id: topRowLayout
    z: 1
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.left: parent.left
    Layout.fillWidth: true
    Layout.fillHeight: false

    PlasmaComponents.TextField {
      id: inputQuery
      anchors.top: parent.top
      anchors.left: parent.left
      Layout.fillWidth: true
      focus: true
      clearButtonShown: true
      placeholderText: i18n("Enter an expression")
      inputMethodHints: Qt.ImhNoPredictiveText

      onAccepted: {
        onNewInput(text, true)
        is_current_line = true
        current_line = text
      }

      onTextChanged: {
        if (is_current_line)
          current_line = text
        if (plasmoid.configuration.liveEvaluation)
          onNewInput(text, false)
      }

      Keys.onPressed: {
        if (event.key == Qt.Key_Escape) {
          event.accepted = true
          if (main.fromCompact) {
            plasmoid.expanded = !plasmoid.expanded
            keepOpen.checked = false
          }
          return
        }

        if ((event.key == Qt.Key_C) && (event.modifiers & Qt.ControlModifier)) {
          event.accepted = true
          is_current_line = true
          current_line = ""
          text = ""
          qwr.getLastHistoryLine()
          return
        }

        if (event.key == Qt.Key_Up) {
          event.accepted = true
          if (qwr.historyAvailable()) {
            var temp = qwr.getPrevHistoryLine()
            if (is_current_line) {
              is_current_line = false
              temp = qwr.getPrevHistoryLine()
            }
            if (temp !== "FIRST_ENTRY")
              text = temp
          }
          return
        }

        if (event.key == Qt.Key_Down) {
          event.accepted = true
          if (qwr.historyAvailable()) {
            var temp = qwr.getNextHistoryLine()
            if (temp !== "LAST_ENTRY")
              text = temp
            else {
              is_current_line = true
              text = current_line
            }
          }
          return
        }

        if (event.key == Qt.Key_PageUp) {
          event.accepted = true
          if (qwr.historyAvailable()) {
            is_current_line = false
            var temp = qwr.getFirstHistoryLine()
            if (temp !== "NOT_FOUND")
              text = temp
            else {
              is_current_line = true
              text = current_line
            }
          }
          return
        }

        if (event.key == Qt.Key_PageDown) {
          event.accepted = true
          is_current_line = true
          text = current_line
          qwr.getLastHistoryLine()
          return
        }
      }
    }
  }

  // invisible TextEdit for copying the result to the clipboard
  TextEdit {
    id: clipcopy
    visible: false
  }

  ColumnLayout{
    id: clMain
    spacing: 0
    anchors.top: topRowLayout.bottom
    anchors.horizontalCenter: parent.horizontalCenter
    width: parent.width
    height: parent.height - topRowLayout.height

    PlasmaCore.SvgItem {
      id: qalculateFullIcon
      visible: true
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.verticalCenter: parent.verticalCenter
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
    }

    BusyIndicator {
      id: busy
      visible: false
      running: true
      anchors.fill: parent
      anchors.margins: 5 * units.largeSpacing
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

    ColumnLayout{
      id: clResult
      spacing: 0
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.verticalCenter: parent.verticalCenter

      Label {
        id: lResult
        text: i18n("Result")
        visible: false
        color: theme.textColor
        anchors.horizontalCenter: parent.horizontalCenter
        font.bold: true
        font.pixelSize: 40

        Connections {
          target: qwr

          onResultText: {
            busyTimer.stop()
            lResult.text = result
            lResult.visible = result.length
            busy.visible = !result.length

            if (plasmoid.configuration.resultBase !== 10) {
              loutputBase.visible = true
              loutputBase.anchors.left = lResult.right
              loutputBase.anchors.top = lResult.verticalCenter
            } else {
              loutputBase.visible = false
            }
            if (!result.length || !resultIsInteger) {
              loutputBase.visible = false
              outputBinary.visible = false
              outputBinary.text = ""
              outputOctal.visible = false
              outputOctal.text = ""
              outputDecimal.visible = false
              outputDecimal.text = ""
              outputHex.visible = false
              outputHex.text = ""
            } else if (resultIsInteger) {
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

          onCalculationTimeout: {
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
        anchors.left: lResult.right
        anchors.verticalCenter: lResult.bottom
        Layout.minimumHeight: 0
        Layout.maximumHeight: 0
        font.bold: true
        font.pixelSize: Math.round(0.9 * units.gridUnit)
      }

      Label {
        id: outputBinary
        text: "ResultBinary"
        visible: false
        color: theme.textColor
        anchors.horizontalCenter: parent.horizontalCenter
        font.pixelSize: units.gridUnit
      }

      Label {
        id: outputOctal
        text: "ResultOctal"
        visible: false
        color: theme.textColor
        anchors.horizontalCenter: parent.horizontalCenter
        font.pixelSize: units.gridUnit
      }

      Label {
        id: outputDecimal
        text: "ResultDecimal"
        visible: false
        color: theme.textColor
        anchors.horizontalCenter: parent.horizontalCenter
        font.pixelSize: units.gridUnit
      }

      Label {
        id: outputHex
        text: "ResultHex"
        visible: false
        color: theme.textColor
        anchors.horizontalCenter: parent.horizontalCenter
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

  function onNewInput(input, enter) {
    if (!input.length) {
      busyTimer.stop()
      qalculateFullIcon.visible = true
      busy.visible = false
      clearOutput()
      return
    }
    if (input !== last_input) {
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
