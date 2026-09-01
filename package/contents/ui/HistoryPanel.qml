//  Copyright (c) 2016 - 2026 Daniel Schopf <schopfdan@gmail.com>
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

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.extras as PlasmaExtras
import org.kde.plasma.components 3.0 as PlasmaComponents
import org.kde.kquickcontrolsaddons as KQuickControlsAddons
import org.kde.ksvg as KSvg

import com.dschopf.plasma.qalculate

import "../code/tools.js" as Tools

Item {
  property int selectedId: -1
  property bool searchVisible: false
  property HistoryFilterModel historyModel: qwr.getModel()

  Layout.fillWidth: true

  ColumnLayout {
    anchors.fill: parent
    Layout.fillWidth: true

    spacing: 0

    PlasmaExtras.PlasmoidHeading {
      id: historyHeader

      Layout.preferredHeight: historyHeader.implicitHeight
      Layout.fillWidth: true

      leftInset: 0
      rightInset: 0

      contentItem: ColumnLayout {
        spacing: 0

        RowLayout {
          spacing: Kirigami.Units.smallSpacing

          Kirigami.Heading {
            id: historyHeading

            Layout.alignment: Qt.AlignVCenter
            Layout.leftMargin: fullRepresentation.paddings
            Layout.rightMargin: fullRepresentation.paddings

            text: i18n("History")
            textFormat: Text.PlainText
            maximumLineCount: 1
            elide: Text.ElideRight

            visible: !searchVisible
          }

          Item {
            Layout.fillWidth: true
            visible: !searchVisible
          }

          PlasmaComponents.TextField {
            id: historySearch

            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            Layout.leftMargin: fullRepresentation.paddings
            Layout.topMargin: fullRepresentation.paddings / 2
            Layout.rightMargin: fullRepresentation.paddings / 2

            visible: searchVisible

            clearButtonShown: true
            placeholderText: i18n("Search an entry")
            inputMethodHints: Qt.ImhNoPredictiveText

            onTextChanged: {
              if (historyListView.currentIndex != -1) {
                selectedId = historyModel.findBaseIndex(historyListView.currentIndex)
              }
              historyModel.filterText = text
              if (selectedId != -1) {
                var newIndex = historyModel.findFilterIndex(selectedId)
                historyListView.currentIndex = newIndex
                var newPos = newIndex < 0 ? 0 : newIndex
                historyListView.positionViewAtIndex(newPos, ListView.Center)
              }
            }
          }

          PlasmaComponents.ToolButton {
            id: showHistory

            Layout.alignment: Qt.AlignVCenter
            Layout.topMargin: fullRepresentation.paddings / 2
            Layout.rightMargin: fullRepresentation.paddings / 2

            checkable: true
            icon.name: "system-search"
            onCheckedChanged: searchVisible = checked
          }
        }
      }
    }

    ScrollView {
      Layout.fillWidth: true
      Layout.fillHeight: true

      ScrollBar.vertical.policy: ScrollBar.AsNeeded

      ListView {
        id: historyListView
        clip: true

        model: historyModel

        currentIndex: -1

        // Delegate defining how each row is drawn
        delegate: ItemDelegate {
          required property string history
          required property int index

          width: ListView.view.width

          topPadding: 2
          bottomPadding: 2
          leftPadding: 0
          rightPadding: 0

          background: Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 3
            anchors.rightMargin: 3
            radius: 5
            color: {
              if (index === historyListView.currentIndex)
                return palette.highlight

              if (hovered)
                return Qt.alpha(palette.highlight, 0.12)

              return "transparent"
            }

            border.width: hovered && index !== historyListView.currentIndex ? 1 : 0
            border.color: palette.highlight
          }

          contentItem: RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 6
            anchors.rightMargin: 6

            Label {
              text: history
              color: index === historyListView.currentIndex
                ? palette.highlightedText
                : palette.text
              Layout.fillWidth: true
            }
          }

          Timer {
              id: singleClickTimer
              interval: 125
              repeat: false

              onTriggered: {
                  historyListView.currentIndex = index
                  inputQuery.fromHistoryEntry = true
                  inputQuery.text = history
                  clearOutput()
                  qalculateFullIcon.visible = true
                  inputQuery.fromHistoryEntry = false
              }
          }

          onClicked: {
              singleClickTimer.restart()
          }

          onDoubleClicked: {
              singleClickTimer.stop()

              historyListView.currentIndex = index
              qalculateFullIcon.visible = false
              inputQuery.fromHistoryEntry = true
              inputQuery.text = history
              last_input = history
              historyEntryRestored = true
              inputQuery.fromHistoryEntry = false
              qwr.evaluate(history, true, true)
              busyTimer.start()
          }
        }
      }
    }
  }

  // returns the string of the currently selected item
  // empty string in case we reached the
  function onUp() {
    if (historyListView.currentIndex <= 0) {
      historyListView.currentIndex = -1
      return ""
    }
    historyListView.currentIndex--
    return historyListView.model.data(historyListView.model.index(historyListView.currentIndex, 0), Qt.DisplayRole)
  }

  function onDown() {
    if (historyListView.currentIndex >= (historyListView.model.rowCount() - 1)) {
      historyListView.currentIndex = historyListView.model.rowCount() - 1
    } else {
      historyListView.currentIndex++
    }
    return historyListView.model.data(historyListView.model.index(historyListView.currentIndex, 0), Qt.DisplayRole)
  }

  function isFirstEntry() {
    return historyListView.currentIndex <= 0
  }

  function isNothingSelected() {
    return historyListView.currentIndex === -1
  }

  function clear() {
    historyListView.currentIndex = -1
    historyListView.positionViewAtIndex(0, ListView.Beginning)
  }
}
