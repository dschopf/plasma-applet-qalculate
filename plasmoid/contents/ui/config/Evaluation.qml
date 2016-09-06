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

  property alias cfg_convertToBestUnits:            chbConvertToBestUnits.checked
  property alias cfg_copyResultToClipboard:         chbCopyResultToClipboard.checked
  property alias cfg_writeResultsInInputLineEdit:   chbWriteResultsInInputLineEdit.checked
  property alias cfg_liveEvaluation:                chbLiveEvaluation.checked
  property alias cfg_enableReversePolishNotation:   chbEnableReversePolishNotation.checked
  property alias cfg_structuringMode:               cobStructuringMode.currentIndex
  property alias cfg_angleUnit:                     cobAngleUnit.currentIndex
  property alias cfg_expressionBase:                sbExpressionBase.value
  property alias cfg_resultBase:                    sbResultBase.value

  GridLayout {

    anchors.left: parent.left
    anchors.right: parent.right
    columns: 2

    CheckBox {
      id: chbConvertToBestUnits
      text: i18n("Convert to best units")
      Layout.columnSpan: 2
    }

    CheckBox {
      id: chbCopyResultToClipboard
      text: i18n("Copy result to clipboard")
      Layout.columnSpan: 2
    }

    CheckBox {
      id: chbWriteResultsInInputLineEdit
      text: i18n("Write results in input line edit")
      Layout.columnSpan: 2
    }

    CheckBox {
      id: chbLiveEvaluation
      text: i18n("Live evaluation")
      Layout.columnSpan: 2
    }

    CheckBox {
      id: chbEnableReversePolishNotation
      text: i18n("Enable reverse Polish notation")
      Layout.columnSpan: 2
    }

    Label {
      text: i18n('Structuring mode:')
      Layout.alignment: Qt.AlignVCenter|Qt.AlignRight
    }

    ComboBox {
      id: cobStructuringMode
      model: ListModel {
        ListElement { text: "None" }
        ListElement { text: "Simplify" }
        ListElement { text: "Factorize" }
      }
    }

    Label {
      text: i18n('Angle unit:')
      Layout.alignment: Qt.AlignVCenter|Qt.AlignRight
    }

    ComboBox {
      id: cobAngleUnit
      model: ListModel {
        ListElement { text: "None" }
        ListElement { text: "Radians" }
        ListElement { text: "Degrees" }
        ListElement { text: "Gradians" }
      }
    }

    Label {
      text: i18n('Expression base:')
      Layout.alignment: Qt.AlignVCenter|Qt.AlignRight
    }

    SpinBox {
      id: sbExpressionBase
      decimals: 0
      stepSize: 1
      minimumValue: 1
      maximumValue: 64
    }

    Label {
      text: i18n('Result base:')
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
