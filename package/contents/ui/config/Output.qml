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
  property alias cfg_unicode: chbUnicode.checked

  Kirigami.FormLayout {
    anchors.left: parent.left
    anchors.right: parent.right

    RadioButton {
      id: numberFractionFormatDecimal
      Kirigami.FormData.label: i18n("Number fraction format") + ":"
      text: i18nc("FractionFormat", "Decimal")
      ButtonGroup.group: numberFractionFormatGroup
      property int index: 0
      checked: cfg_numberFractionFormat === 0
    }

    Label {
      leftPadding: numberFractionFormatDecimal.contentItem.leftPadding
      text: i18nc("FractionFormat", "Display numbers in decimal, not fractional, format (ex. 0.333333).")
      Layout.fillWidth: true
      wrapMode: Text.Wrap
      font: Kirigami.Theme.smallFont
    }

    RadioButton {
        id: numberFractionFormatExact
        text: i18nc("FractionFormat", "Exact")
        ButtonGroup.group: numberFractionFormatGroup
        property int index: 1
        checked: cfg_numberFractionFormat === 1
    }

    Label {
      leftPadding: numberFractionFormatExact.contentItem.leftPadding
      text: i18nc("FractionFormat", "Display as fraction if necessary to get an exact display of the result (ex. 1/3, but 0.25).")
      Layout.fillWidth: true
      wrapMode: Text.Wrap
      font: Kirigami.Theme.smallFont
    }

    RadioButton {
        id: numberFractionFormatFractional
        text: i18nc("FractionFormat", "Fractional")
        ButtonGroup.group: numberFractionFormatGroup
        property int index: 2
        checked: cfg_numberFractionFormat === 2
    }

    Label {
      leftPadding: numberFractionFormatFractional.contentItem.leftPadding
      text: i18nc("FractionFormat", "Display as fraction (ex. 4/3).")
      Layout.fillWidth: true
      wrapMode: Text.Wrap
      font: Kirigami.Theme.smallFont
    }

    RadioButton {
        id: numberFractionFormatCombined
        text: i18nc("FractionFormat", "Combined")
        ButtonGroup.group: numberFractionFormatGroup
        property int index: 3
        checked: cfg_numberFractionFormat === 3
    }

    Label {
      leftPadding: numberFractionFormatCombined.contentItem.leftPadding
      text: i18nc("FractionFormat", "Display as an integer and a fraction (ex. 3 + 1/2).")
      Layout.fillWidth: true
      wrapMode: Text.Wrap
      font: Kirigami.Theme.smallFont
    }

    ButtonGroup {
      id: numberFractionFormatGroup
      onCheckedButtonChanged: {
        if (checkedButton) {
          cfg_numberFractionFormat = checkedButton.index
        }
      }
    }

    Item {
      Kirigami.FormData.isSection: true
    }

    ComboBox {
      id: cobNumericalDisplay
      Kirigami.FormData.label: i18n("Numerical display") + ':'
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

    Item {
      Kirigami.FormData.isSection: true
    }

    CheckBox {
      id: chbUnicode
      text: i18n("Enable unicode in output")
    }

    CheckBox {
      id: chbIndicateInfiniteSeries
      text: i18n("Indicate infinite series")
    }

    CheckBox {
      id: chbUseAllPrefixes
      text: i18n("Use all prefixes")
    }

    CheckBox {
      id: chbUseDenominatorPrefix
      text: i18n("Use denominator prefix")
    }

    CheckBox {
      id: chbNegativeExponents
      text: i18n("Negative exponents")
    }

    CheckBox {
      id: chbNegativeBinaryTwosComplement
      text: i18n("Use two's complement representation for negative binary numbers")
    }

    Item {
      Kirigami.FormData.isSection: true
    }

    CheckBox {
      id: chbBinary
      Kirigami.FormData.label: i18n("Show integers also in base") + ':'
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

    Item {
      Kirigami.FormData.isSection: true
    }

    SpinBox {
      id: sbResultBase
      Kirigami.FormData.label: i18n("Result base") + ':'
      from: 1
      to: 64
    }
  }
}
