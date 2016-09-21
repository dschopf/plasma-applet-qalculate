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
import QtQuick.Controls 1.0
import QtQuick.Layouts 1.0
import org.kde.plasma.components 2.0 as PlasmaComponents

Item {

  property alias cfg_copyResultToClipboard:         chbCopyResultToClipboard.checked
  property alias cfg_writeResultsInInputLineEdit:   chbWriteResultsInInputLineEdit.checked
  property alias cfg_liveEvaluation:                chbLiveEvaluation.checked
  property alias cfg_timeout:                       tfTimeout.text

  GridLayout {
    anchors.left: parent.left
    anchors.right: parent.right
    columns: 2

    CheckBox {
      id: chbCopyResultToClipboard
      text: i18n("Copy result to clipboard")
      tooltip: i18n("Only works when pressing Return")
      Layout.columnSpan: 2
    }

    CheckBox {
      id: chbWriteResultsInInputLineEdit
      text: i18n("Write results in input line edit")
      tooltip: i18n("Only works when pressing Return")
      Layout.columnSpan: 2
    }

    CheckBox {
      id: chbLiveEvaluation
      text: i18n("Live evaluation")
      Layout.columnSpan: 2
    }

    Label {
      text: i18n('Calculation timeout') + " (ms) :"
      Layout.alignment: Qt.AlignVCenter|Qt.AlignRight
    }

    PlasmaComponents.TextField {
      id: tfTimeout
      validator: IntValidator { bottom: 0; top: 9999999; }
    }
  }
}
