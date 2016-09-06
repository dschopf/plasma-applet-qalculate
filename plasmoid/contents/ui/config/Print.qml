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
import QtQuick.Controls 1.3
import QtQuick.Layouts 1.1

Item {

  property alias cfg_numberFractionFormat: cobNumberFractionFormat.currentIndex
  property alias cfg_numericalDisplay: cobNumericalDisplay.currentIndex
  property alias cfg_indicateInfiniteSeries: chbIndicateInfiniteSeries.checked
  property alias cfg_useAllPrefixes: chbUseAllPrefixes.checked
  property alias cfg_useDenominatorPrefix: chbUseDenominatorPrefix.checked
  property alias cfg_negativeExponents: chbNegativeExponents.checked
  property alias cfg_binary: chbBinary.checked
  property alias cfg_octal: chbOctal.checked
  property alias cfg_decimal: chbDecimal.checked
  property alias cfg_hexadecimal: chbHexadecimal.checked

  GridLayout {

    anchors.left: parent.left
    anchors.right: parent.right
    columns: 2

    Label {
      text: i18n('Number fraction format:')
      Layout.alignment: Qt.AlignVCenter|Qt.AlignRight
    }

    ComboBox {
      id: cobNumberFractionFormat
      model: ListModel {
        ListElement { text: "Decimal" }
        ListElement { text: "Exact" }
        ListElement { text: "Fractional" }
        ListElement { text: "Combined" }
      }
    }

    Label {
      text: i18n('Numerical display:')
      Layout.alignment: Qt.AlignVCenter|Qt.AlignRight
    }

    ComboBox {
      id: cobNumericalDisplay
      model: ListModel {
        ListElement { text: "None" }
        ListElement { text: "Pure" }
        ListElement { text: "Scientific" }
        ListElement { text: "Precision" }
        ListElement { text: "Engineering" }
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

    GroupBox {
      title: i18n("Show integers also in base:")
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
  }
}
