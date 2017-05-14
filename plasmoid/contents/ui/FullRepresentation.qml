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
import QtQuick.Controls 1.4
import QtQuick.Layouts 1.0

import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core 2.0
import org.kde.plasma.components 2.0 as PlasmaComponents

import "../code/tools.js" as Tools

Item {
  id: fullRepresentation

  property bool binary_enabled: plasmoid.configuration.binary && plasmoid.configuration.resultBase !== 2
  property bool octal_enabled: plasmoid.configuration.octal && plasmoid.configuration.resultBase !== 8
  property bool decimal_enabled: plasmoid.configuration.decimal && plasmoid.configuration.resultBase !== 10
  property bool hex_enabled: plasmoid.configuration.hexadecimal && plasmoid.configuration.resultBase !== 16

  property string last_input: ""

  anchors.fill: parent

  Layout.minimumHeight: units.gridUnit * 10 // 150
  Layout.minimumWidth: units.gridUnit * 15 // 200

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
        onNewInput(inputQuery.text)
      }

      onTextChanged: {
        if (plasmoid.configuration.liveEvaluation)
          onNewInput(inputQuery.text)
      }

      Keys.onPressed: {
        if (event.key == Qt.Key_Escape) {
          event.accepted = true
          if (main.fromCompact) {
            plasmoid.expanded = !plasmoid.expanded
            keepOpen.checked = false
          }
        }
      }
    }
  }

  // invisible TextEdit for copying the result
  // to the clipboard
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
    height: (parent.height - topRowLayout.height)

    IconItem {
      id: qalculateIcon
      visible: true
      anchors.fill: parent
      anchors.margins: units.largeSpacing
      source: Tools.stripProtocol(Qt.resolvedUrl('../images/Qalculate.svg'))
    }

    BusyIndicator {
      id: busy
      visible: false
      running: true
      anchors.fill: parent
      anchors.margins: 5 * units.largeSpacing
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
            if (!result.length || !qwr.lastResultIsInteger()) {
              loutputBase.visible = false
              outputBinary.visible = false
              outputBinary.text = ""
              outputOctal.visible = false
              outputOctal.text = ""
              outputDecimal.visible = false
              outputDecimal.text = ""
              outputHex.visible = false
              outputHex.text = ""
            } else if (qwr.lastResultIsInteger()) {
              if (binary_enabled) {
                outputBinary.visible = result.length
                outputBinary.text = "0b" + qwr.getLastResultInBase(2)
              } else {
                outputBinary.visible = false
              }
              if (octal_enabled) {
                outputOctal.visible = result.length
                outputOctal.text = "0o" + qwr.getLastResultInBase(8)
              } else {
                outputOctal.visible = false
              }
              if (decimal_enabled) {
                outputDecimal.visible = result.length
                outputDecimal.text = qwr.getLastResultInBase(10)
              } else {
                outputDecimal.visible = false
              }
              if (hex_enabled) {
                outputHex.visible = result.length
                outputHex.text = "0x" + qwr.getLastResultInBase(16)
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

  function onNewInput(input) {
    if (input !== last_input) {
      qalculateIcon.visible = !input.length
      busy.visible = input.length
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
      qwr.evaluate(input)
      last_input = input
    }
  }
}
