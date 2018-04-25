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

Item {
  property int cfg_unitConversion
  property int cfg_structuringMode
  property string cfg_decimalSeparator
  property alias cfg_useKDESeparator:               cbUseKDESetting.checked
  property alias cfg_angleUnit:                     cobAngleUnit.currentIndex
  property alias cfg_expressionBase:                sbExpressionBase.value

  onCfg_unitConversionChanged: {
    switch (cfg_unitConversion) {
      case 0:
        unitConversionGroup.current = unitConversionTypeNone;
        break;
      case 1:
        unitConversionGroup.current = unitConversionTypeBest;
        break;
      case 2:
        unitConversionGroup.current = unitConversionTypeBase;
        break;
      default:
    }
  }

  onCfg_structuringModeChanged: {
    switch (cfg_structuringMode) {
      case 0:
        structuringModeGroup.current = structuringModeNone;
        break;
      case 1:
        structuringModeGroup.current = structuringModeSimplify;
        break;
      case 2:
        structuringModeGroup.current = structuringModeFactorize;
        break;
      default:
    }
  }

  Component.onCompleted: {
    cfg_unitConversionChanged()
    cfg_structuringModeChanged()
  }

  ExclusiveGroup {
    id: unitConversionGroup
  }

  ExclusiveGroup {
    id: structuringModeGroup
  }

  GridLayout {
    anchors.left: parent.left
    anchors.right: parent.right
    columns: 2

    GroupBox {
      title: i18n("Unit conversion")
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

        RadioButton {
          id: unitConversionTypeNone
          exclusiveGroup: unitConversionGroup
          text: i18nc("Unit conversion", "None")
          onCheckedChanged: if (checked) cfg_unitConversion = 0;
        }
        Label {
          text: i18nc("Unit conversion", "Do not do any conversion of units in addition to syncing.")
        }

        RadioButton {
          id: unitConversionTypeBest
          exclusiveGroup: unitConversionGroup
          text: i18nc("Unit conversion", "Best")
          onCheckedChanged: if (checked) cfg_unitConversion = 1;
        }
        Label {
          text: i18nc("Unit conversion", "Convert to the best suited SI units (the least amount of units).")
        }

        RadioButton {
          id: unitConversionTypeBase
          exclusiveGroup: unitConversionGroup
          text: i18nc("Unit conversion", "Base")
          onCheckedChanged: if (checked) cfg_unitConversion = 2;
        }
        Label {
          text: i18nc("Unit conversion", "Convert to base units.")
        }
      }
    }

    GroupBox {
      title: i18n("Structuring mode")
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

        RadioButton {
          id: structuringModeNone
          exclusiveGroup: structuringModeGroup
          text: i18nc("Structuring mode", "None")
          onCheckedChanged: if (checked) cfg_structuringMode = 0;
        }
        Label {
          text: i18nc("Structuring mode", "Do not do any factorization or additional simplifications.")
        }

        RadioButton {
          id: structuringModeSimplify
          exclusiveGroup: structuringModeGroup
          text: i18nc("Structuring mode", "Simplify")
          onCheckedChanged: if (checked) cfg_structuringMode = 1;
        }
        Label {
          text: i18nc("Structuring mode", "Simplify the result as much as possible.")
        }

        RadioButton {
          id: structuringModeFactorize
          exclusiveGroup: structuringModeGroup
          text: i18nc("Structuring mode", "Factorize")
          onCheckedChanged: if (checked) cfg_structuringMode = 2;
        }
        Label {
          text: i18nc("Structuring mode", "Factorize the result.")
        }
      }
    }

    GridLayout {
      anchors.horizontalCenter: parent.horizontalCenter
      Layout.columnSpan: 2
      columns: 3

      Label {
        text: i18n('Decimal separator') + ":"
        Layout.alignment: Qt.AlignVCenter|Qt.AlignRight
      }

      PlasmaComponents.TextField {
        id: tfDecimalSeparator
        validator: RegExpValidator { regExp: /(\.|,)/; }
        enabled: !cbUseKDESetting.checked
        onTextChanged: {
          cfg_decimalSeparator = text
        }
      }

      CheckBox {
        id: cbUseKDESetting
        text: i18n("Use KDE setting") + ": \"" + Qt.locale().decimalPoint + "\""
        onCheckedChanged: {
          if (checked)
            cfg_decimalSeparator = Qt.locale().decimalPoint
          else
            cfg_decimalSeparator = tfDecimalSeparator.text
        }
      }
    }

    Label {
      text: i18n("Angle unit") + ':'
      Layout.alignment: Qt.AlignVCenter|Qt.AlignRight
    }

    ComboBox {
      id: cobAngleUnit
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

    Label {
      text: i18n("Expression base") + ':'
      Layout.alignment: Qt.AlignVCenter|Qt.AlignRight
    }

    SpinBox {
      id: sbExpressionBase
      decimals: 0
      stepSize: 1
      minimumValue: 1
      maximumValue: 64
    }
  }
}
