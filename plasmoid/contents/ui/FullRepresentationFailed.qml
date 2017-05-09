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

import QtQuick 2.1
import QtQuick.Controls 1.4
import QtQuick.Layouts 1.0

Item {
  id: fullRepresentationLoading

  anchors.fill: parent

  Layout.minimumHeight: units.gridUnit * 12
  Layout.minimumWidth: units.gridUnit * 15

  Label {
    id: lResult
    text: i18n("Failed loading\nnative plugin!")
    visible: true
    color: theme.textColor
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.verticalCenter: parent.verticalCenter
    font.bold: true
    font.pointSize: units.gridUnit
  }
}