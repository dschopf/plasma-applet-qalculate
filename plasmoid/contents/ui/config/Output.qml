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
import QtQuick.Controls 1.0
import QtQuick.Layouts 1.0

Item {

  property int cfg_libVersion
  property int cfg_numberFractionFormat
  property alias cfg_numericalDisplay: cobNumericalDisplay.currentIndex
  property alias cfg_indicateInfiniteSeries: chbIndicateInfiniteSeries.checked
  property alias cfg_useAllPrefixes: chbUseAllPrefixes.checked
  property alias cfg_useDenominatorPrefix: chbUseDenominatorPrefix.checked
  property alias cfg_negativeExponents: chbNegativeExponents.checked
  property alias cfg_negativeBinaryTwosComplement: chbNegativeBinaryTwosComplement.checked
  property alias cfg_binary: chbBinary.checked
  property alias cfg_octal: chbOctal.checked
  property alias cfg_decimal: chbDecimal.checked
  property alias cfg_hexadecimal: chbHexadecimal.checked
  property alias cfg_resultBase: sbResultBase.value

  onCfg_numberFractionFormatChanged: {
    switch (cfg_numberFractionFormat) {
      case 0:
        numberFractionFormatGroup.current = numberFractionFormatDecimal;
        break;
      case 1:
        numberFractionFormatGroup.current = numberFractionFormatExact;
        break;
      case 2:
        numberFractionFormatGroup.current = numberFractionFormatFractional;
        break;
      case 3:
        numberFractionFormatGroup.current = numberFractionFormatCombined;
        break;
      default:
    }
  }

  ExclusiveGroup {
    id: numberFractionFormatGroup
  }

  Component.onCompleted: {
    cfg_numberFractionFormatChanged()
  }

  GridLayout {
    anchors.left: parent.left
    anchors.right: parent.right
    columns: 2

    GroupBox {
      title: i18n("Number fraction format")
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
          id: numberFractionFormatDecimal
          exclusiveGroup: numberFractionFormatGroup
          text: i18nc("FractionFormat", "Decimal")
          onCheckedChanged: if (checked) cfg_numberFractionFormat = 0;
        }
        Label {
          text: i18nc("FractionFormat", "Display numbers in decimal, not fractional, format (ex. 0.333333).")
        }

        RadioButton {
          id: numberFractionFormatExact
          exclusiveGroup: numberFractionFormatGroup
          text: i18nc("FractionFormat", "Exact")
          onCheckedChanged: if (checked) cfg_numberFractionFormat = 1;
        }
        Label {
          text: i18nc("FractionFormat", "Display as fraction if necessary to get an exact display of the result (ex. 1/3, but 0.25).")
        }

        RadioButton {
          id: numberFractionFormatFractional
          exclusiveGroup: numberFractionFormatGroup
          text: i18nc("FractionFormat", "Fractional")
          onCheckedChanged: if (checked) cfg_numberFractionFormat = 2;
        }
        Label {
          text: i18nc("FractionFormat", "Display as fraction (ex. 4/3).")
        }

        RadioButton {
          id: numberFractionFormatCombined
          exclusiveGroup: numberFractionFormatGroup
          text: i18nc("FractionFormat", "Combined")
          onCheckedChanged: if (checked) cfg_numberFractionFormat = 3;
        }
        Label {
          text: i18nc("FractionFormat", "Display as an integer and a fraction (ex. 3 + 1/2).")
        }
      }
    }

    Label {
      text: i18n("Numerical display") + ':'
      Layout.alignment: Qt.AlignVCenter|Qt.AlignRight
    }

    ComboBox {
      id: cobNumericalDisplay
      model: ListModel {
        Component.onCompleted: {
            var arr = [] // use temp array to avoid constant binding stuff
            arr.push({text: i18nc("NumericalDisplay", "None")})
            arr.push({text: i18nc("NumericalDisplay", "Pure")})
            arr.push({text: i18nc("NumericalDisplay", "Scientific")})
            arr.push({text: i18nc("NumericalDisplay", "Precision")})
            arr.push({text: i18nc("NumericalDisplay", "Engineering")})
            append(arr)
        }
      }
    }

    CheckBox {
      id: chbIndicateInfiniteSeries
      text: i18n("Indicate infinite series")
      Layout.columnSpan: 2
    }

    CheckBox {
      id: chbUseAllPrefixes
      text: i18n("Use all prefixes")
      Layout.columnSpan: 2
    }

    CheckBox {
      id: chbUseDenominatorPrefix
      text: i18n("Use denominator prefix")
      Layout.columnSpan: 2
    }

    CheckBox {
      id: chbNegativeExponents
      text: i18n("Negative exponents")
      Layout.columnSpan: 2
    }

    CheckBox {
      id: chbNegativeBinaryTwosComplement
      visible: cfg_libVersion >= 250
      text: i18n("Use two's complement representation for negative binary numbers")
      Layout.columnSpan: 2
    }

    GroupBox {
      title: i18n("Show integers also in base") + ':'
      flat: false
      checkable: false
      Layout.fillWidth: true
      Layout.columnSpan: 2

      Column {
        CheckBox {
          id: chbBinary
          text: i18n("Binary")
        }

        CheckBox {
          id: chbOctal
          text: i18n("Octal")
        }

        CheckBox {
          id: chbDecimal
          text: i18n("Decimal")
        }

        CheckBox {
          id: chbHexadecimal
          text: i18n("Hexadecimal")
        }
      }
    }

    Label {
      text: i18n("Result base") + ':'
      Layout.alignment: Qt.AlignVCenter|Qt.AlignRight
    }

    SpinBox {
      id: sbResultBase
      decimals: 0
      stepSize: 1
      minimumValue: 1
      maximumValue: 64
    }
  }
}
