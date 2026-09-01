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

import "../code/tools.js" as Tools

PlasmaExtras.Representation {
  id: fullRepresentation

  property bool binary_enabled: plasmoid.configuration.binary && plasmoid.configuration.resultBase !== 2
  property bool octal_enabled: plasmoid.configuration.octal && plasmoid.configuration.resultBase !== 8
  property bool decimal_enabled: plasmoid.configuration.decimal && plasmoid.configuration.resultBase !== 10
  property bool hex_enabled: plasmoid.configuration.hexadecimal && plasmoid.configuration.resultBase !== 16

  readonly property int paddings: Kirigami.Units.largeSpacing

  property bool historyOpen: false
  property bool historyEntryRestored: false
  property string current_input: ""
  property string last_input: ""

  anchors.fill: parent

  Layout.minimumHeight: Kirigami.Units.gridUnit * 10
  Layout.minimumWidth: Kirigami.Units.gridUnit * 15
  Layout.preferredHeight: Kirigami.Units.gridUnit * 10
  Layout.preferredWidth: Kirigami.Units.gridUnit * 15

  KQuickControlsAddons.Clipboard {
    id: clipboard
  }

  Keys.onPressed: function(event) {
    // ignore ESC (27) and TAB (9)
    if (!inputQuery.focus && event.text.charCodeAt(0) != 27 && event.text.charCodeAt(0) != 9) {
      inputQuery.forceActiveFocus();
      inputQuery.text += event.text
    }
  }

  PlasmaExtras.Menu {
    id: contextMenu

    function show(item, x, y) {
      visualParent = item
      open(x, y)
    }

    PlasmaExtras.MenuItem {
      id: menuitem_copy
      text: i18n("Copy result to clipboard")
      icon: "edit-copy"
      enabled: lResult.visible
      onClicked: clipboard.content = lResult.text
    }

    PlasmaExtras.MenuItem {
      id: menuitem_submenu

      text: i18n("Copy result as")
      icon: "edit-copy"
      enabled: lResult.visible
      visible: outputBinary.visible || outputOctal.visible || outputDecimal.visible || outputHex.visible

      property PlasmaExtras.Menu submenu: PlasmaExtras.Menu {
        id: submenu_copybase
        visualParent: menuitem_submenu.action

        PlasmaExtras.MenuItem {
          id: menuitem_copybase2
          text: i18n("Binary")
          icon: "edit-copy"
          enabled: lResult.visible
          visible: outputBinary.visible
          onClicked: clipboard.content = outputBinary.text
        }

        PlasmaExtras.MenuItem {
          id: menuitem_copybase8
          text: i18n("Octal")
          icon: "edit-copy"
          enabled: lResult.visible
          visible: outputOctal.visible
          onClicked: clipboard.content = outputOctal.text
        }

        PlasmaExtras.MenuItem {
          id: menuitem_copybase10
          text: i18n("Decimal")
          icon: "edit-copy"
          enabled: lResult.visible
          visible: outputDecimal.visible
          onClicked: clipboard.content = outputDecimal.text
        }

        PlasmaExtras.MenuItem {
          id: menuitem_copybase16
          text: i18n("Hexadecimal")
          icon: "edit-copy"
          enabled: lResult.visible
          visible: outputHex.visible
          onClicked: clipboard.content = outputHex.text
        }
      }
    }
  }

  MouseArea {
    anchors.fill: parent
    acceptedButtons: Qt.RightButton
    onPressed: contextMenu.show(this, mouse.x, mouse.y)
    enabled: true
  }

  Timer {
    id: busyTimer
    interval: 50
    running: false
    repeat: false
    onTriggered: {
      busy.visible = true
      clearOutput()
    }
  }

  Timer {
    id: exchangeRateUpdateTimer
    // interval in ms, config value provides hours
    interval: plasmoid.configuration.exchangeRateUpdateInterval * 1000 * 60 * 60
    running: plasmoid.configuration.updateExchangeRatesRegularly
    repeat: true
    onTriggered: {
      dbgprint("Updating exchange rates")
      qwr.updateExchangeRates()
    }
  }

  // invisible TextEdit for copying the result to the clipboard
  TextEdit {
    id: clipcopy
    visible: false
  }

  collapseMarginsHint: true

  HistoryPanel {
    id: historyPanel
    visible: historyOpen

    anchors {
      top: parent.top
      left: parent.left
      right: separator.left
      bottom: parent.bottom
    }
  }

  KSvg.SvgItem {
    id: separator

    anchors {
      top: parent.top
      right: leadingColumn.left
      bottom: parent.bottom
      // Stretch all the way to the top of a dialog. This magic comes
      // from PlasmaCore.PlasmaWindow::topPadding and CompactApplet containment.
      topMargin: fullRepresentation.parent ? -fullRepresentation.parent.y : 0
    }

    width: naturalSize.width
    visible: historyOpen

    imagePath: "widgets/line"
    elementId: "vertical-line"
  }

  ColumnLayout {
    id: leadingColumn

    anchors {
      top: parent.top
      right: parent.right
      bottom: parent.bottom
    }

    width: (historyOpen) ? Math.round(parent.width / 2) : parent.width

    spacing: 0

    PlasmaExtras.PlasmoidHeading {
      id: mainHeader

      Layout.preferredHeight: mainHeader.implicitHeight
      Layout.fillWidth: true

      leftInset: 0
      rightInset: 0

      contentItem: ColumnLayout {
        spacing: 0

        RowLayout {
          spacing: Kirigami.Units.smallSpacing

          Kirigami.Heading {
            id: mainHeading

            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            Layout.leftMargin: fullRepresentation.paddings
            Layout.rightMargin: fullRepresentation.paddings

            text: i18n("Qalculate!")
            textFormat: Text.PlainText
            maximumLineCount: 1
            elide: Text.ElideRight
          }

          PlasmaComponents.ToolButton {
            id: historyButton

            Layout.alignment: Qt.AlignVCenter
            Layout.topMargin: fullRepresentation.paddings / 2

            checkable: true
            icon.name: "view-history"
            onCheckedChanged: historyOpen = checked
          }

          PlasmaComponents.ToolButton {
            id: keepOpenButton

            Layout.alignment: Qt.AlignVCenter
            Layout.topMargin: fullRepresentation.paddings / 2
            Layout.rightMargin: fullRepresentation.paddings / 2

            checkable: true
            icon.name: "window-pin"
            onCheckedChanged: main.hideOnWindowDeactivate = !checked
          }
        }
      }
    }

    RowLayout {
      id: mainLayout

      Item {
        id: basicPanel
        Layout.fillWidth: true
        Layout.fillHeight: true

        ColumnLayout {
          anchors.fill: parent

          spacing: Kirigami.Units.smallSpacing

          PlasmaComponents.TextField {
            id: inputQuery

            property bool fromHistoryEntry: false
            property string lastInputBeforeHistory: ""
            property bool restoredHistoryEntry: false

            Layout.topMargin: fullRepresentation.paddings / 2
            Layout.leftMargin: fullRepresentation.paddings / 2
            Layout.rightMargin: fullRepresentation.paddings / 2
            Layout.alignment: Qt.AlignTop | Qt.AlignHCenter
            Layout.fillWidth: true

            focus: true
            clearButtonShown: true
            placeholderText: i18n("Enter an expression")
            inputMethodHints: Qt.ImhNoPredictiveText

            onAccepted: {
              onNewInput(text, true)
            }

            onTextChanged: {
              if (plasmoid.configuration.liveEvaluation && !fromHistoryEntry) {
                onNewInput(text, false)
              }
              fromHistoryEntry = false
            }

            Keys.onPressed: function(event) {
              if (event.key == Qt.Key_Escape) {
                event.accepted = true
                if (main.fromCompact) {
                  main.expanded = !main.expanded
                  keepOpenButton.checked = false
                }
                return
              }

              // need a better way to clear the input field
              var mods = Qt.ControlModifier | Qt.AltModifier
              if ((event.key == Qt.Key_C) && (event.modifiers & mods) == mods) {
                event.accepted = true
                text = ""
                return
              }

              mods = Qt.ControlModifier
              if ((event.key == Qt.Key_H) && (event.modifiers & mods) == mods) {
                event.accepted = true
                historyOpen = !historyOpen
                return
              }

              if (event.key == Qt.Key_Up) {
                event.accepted = true
                if (historyOpen) {
                  if (restoredHistoryEntry) {
                    return
                  }
                  fromHistoryEntry = true
                  if (historyPanel.isFirstEntry()) {
                    if (lastInputBeforeHistory.length) {
                      text = lastInputBeforeHistory
                    }
                    restoredHistoryEntry = true
                    historyPanel.onUp()
                  } else {
                    text = historyPanel.onUp()
                  }
                  clearOutput()
                  qalculateFullIcon.visible = true
                }
                return
              }

              if (event.key == Qt.Key_Down) {
                event.accepted = true
                if (historyOpen) {
                  restoredHistoryEntry = false
                  if (text.length && historyPanel.isNothingSelected()) {
                    lastInputBeforeHistory = text
                  }
                  fromHistoryEntry = true
                  text = historyPanel.onDown()
                  clearOutput()
                  qalculateFullIcon.visible = true
                }
                return
              }

              if (event.key == Qt.Key_Enter || event.key == Qt.Key_Return) {
                selectAll()
              }
            }
          }

          Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            ColumnLayout {
              id: clResult
              anchors.centerIn: parent
              width: parent.width

              RowLayout {
                id: rlResult
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter

                FontMetrics {
                  id: fontMetrics
                  font: lResult.font
                }

                TextEdit {
                  id: lResult
                  text: i18n("Result")
                  visible: false
                  readOnly: true
                  selectByMouse: true
                  color: Kirigami.Theme.textColor
                  Layout.alignment: Qt.AlignHCenter
                  font.bold: true
                  font.pixelSize: 40

                  Connections {
                    target: qwr

                    function onResultText(result, resultBase2, resultBase8, resultBase10, resultBase16) {
                      busyTimer.stop()
                      busy.visible = false

                      if (!result.length) {
                        lResult.visible = false
                        lResult.text = ""
                        loutputBase.visible = false
                        outputBinary.visible = false
                        outputBinary.text = ""
                        outputOctal.visible = false
                        outputOctal.text = ""
                        outputDecimal.visible = false
                        outputDecimal.text = ""
                        outputHex.visible = false
                        outputHex.text = ""
                        return
                      }

                      lResult.visible = true
                      lResult.text = result

                      lResult.font.pixelSize = 40

                      if (result.length * fontMetrics.averageCharacterWidth > fullRepresentation.width * 0.95) {
                        while (result.length * fontMetrics.averageCharacterWidth > fullRepresentation.width * 0.95) {
                          lResult.font.pixelSize = lResult.font.pixelSize * 0.85
                        }
                      }

                      if (plasmoid.configuration.resultBase !== 10) {
                        loutputBase.visible = true
                        loutputBase.anchors.left = lResult.right
                        loutputBase.anchors.top = lResult.verticalCenter
                      } else {
                        loutputBase.visible = false
                      }

                      if (binary_enabled && resultBase2.length) {
                        outputBinary.visible = resultBase2.length
                        outputBinary.text = "0b" + resultBase2
                      } else {
                        outputBinary.visible = false
                      }

                      if (octal_enabled && resultBase8.length) {
                        outputOctal.visible = resultBase8.length
                        outputOctal.text = "0o" + resultBase8
                      } else {
                        outputOctal.visible = false
                      }

                      if (decimal_enabled && resultBase10.length) {
                        outputDecimal.visible = resultBase10.length
                        outputDecimal.text = resultBase10
                      } else {
                        outputDecimal.visible = false
                      }

                      if (hex_enabled && resultBase16.length) {
                        outputHex.visible = resultBase16.length
                        outputHex.text = "0x" + resultBase16
                      } else {
                        outputHex.visible = false
                      }

                      if (!plasmoid.configuration.liveEvaluation) {
                        if (plasmoid.configuration.copyResultToClipboard) {
                          clipcopy.text = result
                          clipcopy.selectAll()
                          clipcopy.copy()
                        }

                        if (plasmoid.configuration.writeResultsInInputLineEdit)
                          text = lResult.text
                      }

                      if (historyOpen && !historyEntryRestored) {
                        historyPanel.clear()
                      }

                      historyEntryRestored = false
                    }

                    function onCalculationTimeout() {
                      lResult.text = i18n("Calculation timed out")
                      lResult.visible = true
                      busy.visible = false
                    }
                  }
                }

                Label {
                  id: loutputBase
                  text: plasmoid.configuration.resultBase
                  visible: false
                  color: Kirigami.Theme.textColor
                  Layout.minimumHeight: 0
                  Layout.maximumHeight: 0
                  font.bold: true
                  font.pixelSize: Math.round(0.9 * Kirigami.Units.gridUnit)
                }
              }

              TextEdit {
                id: outputBinary
                text: "ResultBinary"
                visible: false
                readOnly: true
                selectByMouse: true
                color: Kirigami.Theme.textColor
                Layout.alignment: Qt.AlignHCenter
                Layout.maximumWidth: parent.width
                font.pixelSize: Kirigami.Units.gridUnit
              }

              TextEdit {
                id: outputOctal
                text: "ResultOctal"
                visible: false
                readOnly: true
                selectByMouse: true
                color: Kirigami.Theme.textColor
                Layout.alignment: Qt.AlignHCenter
                font.pixelSize: Kirigami.Units.gridUnit
              }

              TextEdit {
                id: outputDecimal
                text: "ResultDecimal"
                visible: false
                readOnly: true
                selectByMouse: true
                color: Kirigami.Theme.textColor
                Layout.alignment: Qt.AlignHCenter
                font.pixelSize: Kirigami.Units.gridUnit
              }

              TextEdit {
                id: outputHex
                text: "ResultHex"
                visible: false
                readOnly: true
                selectByMouse: true
                color: Kirigami.Theme.textColor
                Layout.alignment: Qt.AlignHCenter
                font.pixelSize: Kirigami.Units.gridUnit
              }
            }

            Item {
              id: qalculateFullIcon
              width: Math.min(parent.width, parent.height)
              height: width
              anchors.centerIn: parent
              Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
              visible: true

              KSvg.SvgItem {
                  anchors.centerIn: parent

                  width: Math.min(parent.width, parent.height)
                  height: width

                  imagePath: Tools.stripProtocol(
                      Qt.resolvedUrl("../images/Qalculate.svg").toString()
                  )
              }

              MouseArea {
                anchors.fill: parent
                onClicked: {
                  if (plasmoid.configuration.launcherEnabled) {
                    if (plasmoid.configuration.launcherArgsEnabled)
                      qwr.launch(plasmoid.configuration.launcherExecutable, plasmoid.configuration.launcherArguments, inputQuery.text)
                    else
                      qwr.launch(plasmoid.configuration.launcherExecutable)
                  }
                }
              }
            }

            BusyIndicator {
              id: busy
              visible: false
              running: true
              width: Math.min(parent.width, parent.height) * 0.50
              height: width
              anchors.centerIn: parent
              Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
            }

            KSvg.SvgItem {
              id: qalculateSmallIcon
              visible: !qalculateFullIcon.visible

              anchors.right: parent.right
              anchors.bottom: parent.bottom

              smooth: true
              width: Math.round(Kirigami.Units.gridUnit * 1.25)
              height: width

              svg: KSvg.Svg {
                imagePath: Tools.stripProtocol(Qt.resolvedUrl('../images/Qalculate.svg').toString())
              }

              MouseArea {
                anchors.fill: parent
                onClicked: {
                  if (plasmoid.configuration.launcherEnabled) {
                    if (plasmoid.configuration.launcherArgsEnabled)
                        qwr.launch(plasmoid.configuration.launcherExecutable, plasmoid.configuration.launcherArguments, inputQuery.text)
                      else
                        qwr.launch(plasmoid.configuration.launcherExecutable)
                  }
                }
              }
            }
          }
        }
      }
    }
  }

  function onNewInput(input, enter) {
    if (!input.length) {
      busyTimer.stop()
      qalculateFullIcon.visible = true
      busy.visible = false
      last_input = ""
      clearOutput()
      return
    }
    if (input !== last_input || enter == true) {
      qalculateFullIcon.visible = false
      last_input = input
      qwr.evaluate(input, enter, false)
      busyTimer.start()
    }
  }

  function clearOutput() {
    lResult.visible = false
    loutputBase.visible = false
    outputBinary.visible = false
    outputBinary.text = ""
    outputOctal.visible = false
    outputOctal.text = ""
    outputDecimal.visible = false
    outputDecimal.text = ""
    outputHex.visible = false
    outputHex.text = ""
  }
}
