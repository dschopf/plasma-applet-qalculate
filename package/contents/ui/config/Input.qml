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
import QtQuick.Controls 2.15
import QtQuick.Layouts

import org.kde.kirigami 2.20 as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {

  property int cfg_unitConversion
  property int cfg_structuringMode
  property string cfg_decimalSeparator
  property alias cfg_useKDESeparator:               cbUseKDESetting.checked
  property alias cfg_angleUnit:                     cobAngleUnit.currentIndex
  property alias cfg_expressionBase:                sbExpressionBase.value
  property alias cfg_detectTimestamps:              cbDetectTimestamps.checked

  Kirigami.FormLayout {
    anchors.left: parent.left
    anchors.right: parent.right

    RadioButton {
      id: unitConversionTypeNone
      Kirigami.FormData.label: i18n("Unit conversion") + ":"
      text: i18nc("Unit conversion", "None")
      ButtonGroup.group: unitConversionGroup
      property int index: 0
      checked: cfg_unitConversion === 0
    }

    Label {
      leftPadding: unitConversionTypeNone.contentItem.leftPadding
      text: i18nc("Unit conversion", "Do not do any conversion of units in addition to syncing.")
      Layout.fillWidth: true
      wrapMode: Text.Wrap
      font: Kirigami.Theme.smallFont
    }

    RadioButton {
        id: unitConversionTypeBest
        text: i18nc("Unit conversion", "Best")
        ButtonGroup.group: unitConversionGroup
        property int index: 1
        checked: cfg_unitConversion === 1
    }

    Label {
      leftPadding: unitConversionTypeBest.contentItem.leftPadding
      text: i18nc("Unit conversion", "Convert to the best suited SI units (the least amount of units).")
      Layout.fillWidth: true
      wrapMode: Text.Wrap
      font: Kirigami.Theme.smallFont
    }

    RadioButton {
        id: unitConversionTypeBase
        text: i18nc("Unit conversion", "Base")
        ButtonGroup.group: unitConversionGroup
        property int index: 2
        checked: cfg_unitConversion === 2
    }

    Label {
      leftPadding: unitConversionTypeBase.contentItem.leftPadding
      text: i18nc("Unit conversion", "Convert to base units.")
      Layout.fillWidth: true
      wrapMode: Text.Wrap
      font: Kirigami.Theme.smallFont
    }

    ButtonGroup {
      id: unitConversionGroup
      onCheckedButtonChanged: {
        if (checkedButton) {
          cfg_unitConversion = checkedButton.index
        }
      }
    }

    Item {
      Kirigami.FormData.isSection: true
    }

    RadioButton {
      id: structuringModeNone
      Kirigami.FormData.label: i18n("Structuring mode") + ":"
      text: i18nc("Structuring mode", "None")
      ButtonGroup.group: structuringModeGroup
      property int index: 0
      checked: cfg_structuringMode === 0
    }

    Label {
      leftPadding: structuringModeNone.contentItem.leftPadding
      text: i18nc("Structuring mode", "Do not do any factorization or additional simplifications.")
      Layout.fillWidth: true
      wrapMode: Text.Wrap
      font: Kirigami.Theme.smallFont
    }

    RadioButton {
        id: structuringModeSimplify
        text: i18nc("Structuring mode", "Simplify")
        ButtonGroup.group: structuringModeGroup
        property int index: 1
        checked: cfg_structuringMode === 1
    }

    Label {
      leftPadding: structuringModeSimplify.contentItem.leftPadding
      text: i18nc("Structuring mode", "Simplify the result as much as possible.")
      Layout.fillWidth: true
      wrapMode: Text.Wrap
      font: Kirigami.Theme.smallFont
    }

    RadioButton {
        id: structuringModeFactorize
        text: i18nc("Structuring mode", "Factorize")
        ButtonGroup.group: structuringModeGroup
        property int index: 2
        checked: cfg_structuringMode === 2
    }

    Label {
      leftPadding: structuringModeFactorize.contentItem.leftPadding
      text: i18nc("Structuring mode", "Factorize the result.")
      Layout.fillWidth: true
      wrapMode: Text.Wrap
      font: Kirigami.Theme.smallFont
    }

    ButtonGroup {
      id: structuringModeGroup
      onCheckedButtonChanged: {
        if (checkedButton) {
          cfg_structuringMode = checkedButton.index
        }
      }
    }

    Item {
      Kirigami.FormData.isSection: true
    }

    RadioButton {
      id: decimalSeparatorDot
      Kirigami.FormData.label: i18n('Decimal separator') + ":"
      text: i18nc("Separator", "\".\" (dot)")
      ButtonGroup.group: separatorGroup
      property string value: "."
      checked: cfg_decimalSeparator === "."
      enabled: !cbUseKDESetting.checked
    }

    RadioButton {
      id: decimalSeparatorComma
      text: i18nc("Separator", "\",\" (comma)")
      ButtonGroup.group: separatorGroup
      property string value: ","
      checked: cfg_decimalSeparator === ","
      enabled: !cbUseKDESetting.checked
    }

    ButtonGroup {
      id: separatorGroup
      onCheckedButtonChanged: {
        if (checkedButton) {
          cfg_decimalSeparator = checkedButton.value
        }
      }
    }

    CheckBox {
      id: cbUseKDESetting
      text: i18n("Use KDE setting") + ": \"" + Qt.locale().decimalPoint + "\""
      onCheckedChanged: {
        if (checked) {
          cfg_decimalSeparator = Qt.locale().decimalPoint
        } else {
          cfg_decimalSeparator = checkedButton.value
        }
      }
    }

    Item {
      Kirigami.FormData.isSection: true
    }

    ComboBox {
      id: cobAngleUnit
      Kirigami.FormData.label: i18n("Angle unit") + ':'
      model: ListModel {
        Component.onCompleted: {
            var arr = [] // use temp array to avoid constant binding stuff
            arr.push({text: i18nc("Angle Unit", "None")})
            arr.push({text: i18nc("Angle Unit", "Radians")})
            arr.push({text: i18nc("Angle Unit", "Degrees")})
            arr.push({text: i18nc("Angle Unit", "Gradians")})
            append(arr)
        }
      }
    }

    Item {
      Kirigami.FormData.isSection: true
    }

    SpinBox {
      id: sbExpressionBase
      Kirigami.FormData.label: i18n("Expression base") + ':'
      from: 1
      to: 64
    }

    Item {
      Kirigami.FormData.isSection: true
    }

    CheckBox {
      id: cbDetectTimestamps
      Kirigami.FormData.label: i18n("Timestamps") + ':'
      text: i18n("Interpret 9-12 digit numbers as a timestamp")
    }
  }
}
