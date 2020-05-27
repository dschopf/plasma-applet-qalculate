//  Copyright (c) 2016 - 2019 Daniel Schopf <schopfdan@gmail.com>
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
import QtQuick.Layouts 1.1

import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.plasmoid 2.0
import org.kde.private.qalculate 1.0

import "../code/tools.js" as Tools

Item {
    id:main

    QWrapper {
      id: qwr
      onExchangeRatesUpdated: {
        plasmoid.configuration.exchangeRatesTime = date
      }
    }

    property bool fromCompact: false
    property bool debugLogging: false

    readonly property bool inPanel: (plasmoid.location === PlasmaCore.Types.TopEdge
        || plasmoid.location === PlasmaCore.Types.RightEdge
        || plasmoid.location === PlasmaCore.Types.BottomEdge
        || plasmoid.location === PlasmaCore.Types.LeftEdge)
    readonly property bool vertical: (plasmoid.formFactor === PlasmaCore.Types.Vertical)

    property string qalculateIcon: plasmoid.configuration.qalculateIcon
    property int timeout: plasmoid.configuration.timeout
    property bool launcherEnabled: plasmoid.configuration.launcherEnabled
    property string launcherExecutable: plasmoid.configuration.launcherExecutable
    property bool launcherArgsEnabled: plasmoid.configuration.launcherArgsEnabled
    property string launcherArguments: plasmoid.configuration.launcherArguments
    property bool historyDisabled: plasmoid.configuration.historyDisabled
    property int historySize: plasmoid.configuration.historySize

    property int unitConversion: plasmoid.configuration.unitConversion
    property int structuringMode: plasmoid.configuration.structuringMode
    property string decimalSeparator: plasmoid.configuration.decimalSeparator
    property int angleUnit: plasmoid.configuration.angleUnit
    property int expressionBase: plasmoid.configuration.expressionBase
    property bool detectTimestamps: plasmoid.configuration.detectTimestamps

    property int numberFractionFormat: plasmoid.configuration.numberFractionFormat
    property int numericalDisplay: plasmoid.configuration.numericalDisplay
    property bool indicateInfiniteSeries: plasmoid.configuration.indicateInfiniteSeries
    property bool useAllPrefixes: plasmoid.configuration.useAllPrefixes
    property bool useDenominatorPrefix: plasmoid.configuration.useDenominatorPrefix
    property bool negativeExponents: plasmoid.configuration.negativeExponents
    property bool negativeBinaryTwosComplement: plasmoid.configuration.negativeBinaryTwosComplement
    property bool resultInBase2: plasmoid.configuration.binary
    property bool resultInBase8: plasmoid.configuration.octal
    property bool resultInBase10: plasmoid.configuration.decimal
    property bool resultInBase16: plasmoid.configuration.hexadecimal
    property int resultBase: plasmoid.configuration.resultBase

    Plasmoid.switchWidth: units.gridUnit * 20
    Plasmoid.switchHeight: units.gridUnit * 30

    Component {
      id: compactRepresentation
      Item {
        id: root

        PlasmaCore.IconItem {
          id: defaultPanelIcon
          anchors.fill: parent
          visible: false
          source: plasmoid.configuration.qalculateIcon
        }

        PlasmaCore.SvgItem {
          id: qalculateSvgIcon
          visible: true
          anchors.horizontalCenter: parent.horizontalCenter
          anchors.verticalCenter: parent.verticalCenter
          anchors.fill: parent
          smooth: true
          svg: PlasmaCore.Svg {
            imagePath: plasmoid.configuration.qalculateIcon
            onImagePathChanged: {
              qalculateSvgIcon.visible = isValid()
              defaultPanelIcon.visible = !isValid()
            }
          }
        }

        MouseArea {
          id: mouseArea
          anchors.fill: parent
          hoverEnabled: true
          onClicked: {
            main.fromCompact = true
            plasmoid.expanded = !plasmoid.expanded;
          }
        }

        Layout.minimumWidth: {
          if (!inPanel)
            return units.iconSizeHints.panel;

          if (vertical) {
            return -1;
          } else {
            return Math.min(units.iconSizeHints.panel, parent.height) * buttonIcon.aspectRatio;
          }
        }

        Layout.minimumHeight: {
          if (!inPanel) {
            return units.iconSizeHints.panel;
          }

          if (vertical) {
            return Math.min(units.iconSizeHints.panel, parent.width) * buttonIcon.aspectRatio;
          } else {
            return -1;
          }
        }

        Layout.maximumWidth: {
          if (!inPanel) {
            return -1;
          }

          if (vertical) {
            return units.iconSizeHints.panel;
          } else {
            return Math.min(units.iconSizeHints.panel, parent.height) * buttonIcon.aspectRatio;
          }
        }

        Layout.maximumHeight: {
          if (!inPanel) {
            return -1;
          }

          if (vertical) {
            return Math.min(units.iconSizeHints.panel, parent.width) * buttonIcon.aspectRatio;
          } else {
            return units.iconSizeHints.panel;
          }
        }
      }
    }

    function dbgprint(msg) {
        if (!debugLogging) {
            return
        }
        print('[Qalculate!] ' + msg)
    }

    Plasmoid.icon: plasmoid.configuration.qalculateIcon
    Plasmoid.toolTipMainText: "Qalculate!"

    Plasmoid.compactRepresentation: compactRepresentation
    Plasmoid.fullRepresentation: FullRepresentation {}

    Component.onCompleted: {
      if (plasmoid.configuration.qalculateIcon.length == 0) {
        plasmoid.configuration.qalculateIcon = Tools.stripProtocol(Qt.resolvedUrl('../images/Qalculate.svg'))
      }
      if (plasmoid.configuration.updateExchangeRatesAtStartup) {
        qwr.updateExchangeRates()
      } else {
        plasmoid.configuration.exchangeRatesTime = qwr.getExchangeRatesUpdateTime()
      }
      qwr.setDisableHistory(historyDisabled)

      plasmoid.configuration.libVersion = qwr.getVersion()

      if (plasmoid.hasOwnProperty("activationTogglesExpanded"))
        plasmoid.activationTogglesExpanded = true

      if (plasmoid.configuration.switchDefaultCurrency)
        qwr.setDefaultCurrency(plasmoid.configuration.selectedDefaultCurrency)
    }

    Component.onDestruction: {
      qwr.destroy()
    }

    onUnitConversionChanged: {
      qwr.setAutoPostConversion(unitConversion)
    }

    onStructuringModeChanged: {
      qwr.setStructuringMode(structuringMode)
    }

    onAngleUnitChanged: {
      qwr.setAngleUnit(angleUnit)
    }

    onExpressionBaseChanged: {
      qwr.setExpressionBase(expressionBase)
    }

    onDetectTimestampsChanged: {
      qwr.setDetectTimestamps(detectTimestamps)
    }

    onNumberFractionFormatChanged: {
      qwr.setNumberFractionFormat(numberFractionFormat)
    }

    onNumericalDisplayChanged: {
      qwr.setNumericalDisplay(numericalDisplay)
    }

    onIndicateInfiniteSeriesChanged: {
      qwr.setIndicateInfiniteSeries(indicateInfiniteSeries)
    }

    onUseAllPrefixesChanged: {
      qwr.setUseAllPrefixes(useAllPrefixes)
    }

    onUseDenominatorPrefixChanged: {
      qwr.setUseDenominatorPrefix(useDenominatorPrefix)
    }

    onNegativeExponentsChanged: {
      qwr.setNegativeExponents(negativeExponents)
    }

    onNegativeBinaryTwosComplement: {
      qwr.setNegativeBinaryTwosComplement(negativeBinaryTwosComplement)
    }

    onResultInBase2Changed: {
      qwr.setEnableBase2(resultInBase2)
    }

    onResultInBase8Changed: {
      qwr.setEnableBase8(resultInBase8)
    }

    onResultInBase10Changed: {
      qwr.setEnableBase10(resultInBase10)
    }

    onResultInBase16Changed: {
      qwr.setEnableBase16(resultInBase16)
    }

    onResultBaseChanged: {
      qwr.setResultBase(resultBase)
    }

    onDecimalSeparatorChanged: {
      qwr.setDecimalSeparator(decimalSeparator)
    }

    onTimeoutChanged: {
      qwr.setTimeout(timeout)
    }

    onHistoryDisabledChanged: {
      qwr.setDisableHistory(historyDisabled)
    }

    onHistorySizeChanged: {
      qwr.setHistorySize(historySize)
    }
}
