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

import QtQuick 2.2
import QtQuick.Controls 1.4
import QtQuick.Layouts 1.1
import QtQuick.Dialogs 1.1

import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 2.0 as PlasmaComponents

Item {
  id: fullRepresentation

  property bool binary_enabled: plasmoid.configuration.binary && plasmoid.configuration.resultBase !== 2
  property bool octal_enabled: plasmoid.configuration.octal && plasmoid.configuration.resultBase !== 8
  property bool decimal_enabled: plasmoid.configuration.decimal && plasmoid.configuration.resultBase !== 10
  property bool hex_enabled: plasmoid.configuration.hexadecimal && plasmoid.configuration.resultBase !== 16

  anchors.fill: parent

  Layout.minimumHeight: 150
  Layout.minimumWidth: 200

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
        if (plasmoid.configuration.copyResultToClipboard) {
          clipcopy.text = lResult.text
          clipcopy.selectAll()
          clipcopy.copy()
        }
        if (plasmoid.configuration.writeResultsInInputLineEdit) {
          text = lResult.text
        }
      }
      onTextChanged: {
        if (plasmoid.configuration.liveEvaluation)
          onNewInput(inputQuery.text)
      }
      Keys.onPressed: {
        if (event.key == Qt.Key_Escape) {
          event.accepted = true;
          if (main.fromCompact) {
            plasmoid.expanded = !plasmoid.expanded;
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
    id: clmain
    spacing: 0
    anchors.top: topRowLayout.bottom
    anchors.horizontalCenter: parent.horizontalCenter
    width: parent.width
    height: parent.height - topRowLayout.height

    PlasmaCore.SvgItem {
      id: qalculateIcon
      visible: true
      anchors {
        horizontalCenter: parent.horizontalCenter
        verticalCenter: parent.verticalCenter
      }
      Layout.minimumHeight: 64
      Layout.minimumWidth: 64
      Layout.maximumHeight: 64
      Layout.maximumWidth: 64
      svg: PlasmaCore.Svg {
        id: qalculateSVGIcon
        imagePath: Qt.resolvedUrl('../images/Qalculate.svg')
      }
    }

    Label {
      id: lResult
      text: i18n("Result")
      visible: false
      color: theme.textColor
      anchors.horizontalCenter: parent.horizontalCenter
      font.bold: true
      font.pixelSize: 40
    }

    Label {
      id: loutputBase
      text: plasmoid.configuration.resultBase
      visible: false
      color: theme.textColor
      anchors.left: lResult.right
      anchors.top: lResult.verticalCenter
      font.bold: true
      font.pixelSize: 25
    }

    Label {
      id: outputBinary
      text: "ResultBinary"
      visible: false
      color: theme.textColor
      anchors.horizontalCenter: parent.horizontalCenter
      font.pixelSize: 18
    }

    Label {
      id: outputOctal
      text: "ResultOctal"
      visible: false
      color: theme.textColor
      anchors.horizontalCenter: parent.horizontalCenter
      font.pixelSize: 18
    }

    Label {
      id: outputDecimal
      text: "ResultDecimal"
      visible: false
      color: theme.textColor
      anchors.horizontalCenter: parent.horizontalCenter
      font.pixelSize: 18
    }

    Label {
      id: outputHex
      text: "ResultHex"
      visible: false
      color: theme.textColor
      anchors.horizontalCenter: parent.horizontalCenter
      font.pixelSize: 18
    }
  }

  PlasmaComponents.ToolButton {
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
    qalculateIcon.visible = !input.length
    lResult.text = qwrapper.evaluate(input)
    lResult.visible = input.length
    if (plasmoid.configuration.resultBase !== 10) {
      loutputBase.visible = true
      loutputBase.anchors.left = lResult.right
      loutputBase.anchors.top = lResult.verticalCenter
    } else {
      loutputBase.visible = false
    }
    if (!input.length || !qwrapper.last_result_is_integer()) {
      loutputBase.visible = false
      outputBinary.visible = false
      outputBinary.text = ""
      outputOctal.visible = false
      outputOctal.text = ""
      outputDecimal.visible = false
      outputDecimal.text = ""
      outputHex.visible = false
      outputHex.text = ""
    } else if (qwrapper.last_result_is_integer()) {
      if (binary_enabled) {
        outputBinary.visible = input.length
        outputBinary.text = "0b" + qwrapper.get_last_result_as(2)
      } else {
        outputBinary.visible = false
      }
      if (octal_enabled) {
        outputOctal.visible = input.length
        outputOctal.text = "0o" + qwrapper.get_last_result_as(8)
      } else {
        outputOctal.visible = false
      }
      if (decimal_enabled) {
        outputDecimal.visible = input.length
        outputDecimal.text = qwrapper.get_last_result_as(10)
      } else {
        outputDecimal.visible = false
      }
      if (hex_enabled) {
        outputHex.visible = input.length
        outputHex.text = "0x" + qwrapper.get_last_result_as(16)
      } else {
        outputHex.visible = false
      }
    }
  }
}
