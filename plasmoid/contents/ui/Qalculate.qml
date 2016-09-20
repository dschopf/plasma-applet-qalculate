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
import QtQuick.Controls 1.3
import QtQuick.Layouts 1.2
import org.kde.plasma.plasmoid 2.0

Item {
    id:main

    property bool fromCompact: false
    property bool debugLogging: true

    property int unitConversion: plasmoid.configuration.unitConversion
    property int structuringMode: plasmoid.configuration.structuringMode
    property int angleUnit: plasmoid.configuration.angleUnit
    property int expressionBase: plasmoid.configuration.expressionBase
    property int resultBase: plasmoid.configuration.resultBase

    property int numberFractionFormat: plasmoid.configuration.numberFractionFormat
    property int numericalDisplay: plasmoid.configuration.numericalDisplay
    property bool indicateInfiniteSeries: plasmoid.configuration.indicateInfiniteSeries
    property bool useAllPrefixes: plasmoid.configuration.useAllPrefixes
    property bool useDenominatorPrefix: plasmoid.configuration.useDenominatorPrefix
    property bool negativeExponents: plasmoid.configuration.negativeExponents

    function dbgprint(msg) {
        if (!debugLogging) {
            return
        }
        print('[Qalculate!] ' + msg)
    }

    Plasmoid.compactRepresentation: CompactRepresentation {}
    Plasmoid.fullRepresentation: FullRepresentation {}

    Plasmoid.toolTipMainText: i18n("Qalculate!")
    Plasmoid.icon: Qt.resolvedUrl('../images/Qalculate.svg')

    QWrapper {
      id: qwrapper
    }

    Component.onCompleted: {
      if (plasmoid.configuration.updateExchangeRatesAtStartup) {
        qwrapper.update_exchange_rates()
        plasmoid.configuration.exchangeRatesTime = new Date().toLocaleString(Qt.locale())
      } else {
        plasmoid.configuration.exchangeRatesTime = qwrapper.get_exchange_rates_time()
      }
    }

    onUnitConversionChanged: {
      qwrapper.set_auto_post_conversion(unitConversion)
    }

    onStructuringModeChanged: {
      qwrapper.set_structuring_mode(structuringMode)
    }

    onAngleUnitChanged: {
      qwrapper.set_angle_unit(angleUnit)
    }

    onExpressionBaseChanged: {
      qwrapper.set_expression_base(expressionBase)
    }

    onResultBaseChanged: {
      qwrapper.set_result_base(resultBase)
    }

    onNumberFractionFormatChanged: {
      qwrapper.set_number_fraction_format(numberFractionFormat)
    }

    onNumericalDisplayChanged: {
      qwrapper.set_numerical_display(numericalDisplay)
    }

    onIndicateInfiniteSeriesChanged: {
      qwrapper.set_indicate_infinite_series(indicateInfiniteSeries)
    }

    onUseAllPrefixesChanged: {
      qwrapper.set_use_all_prefixes(useAllPrefixes)
    }

    onUseDenominatorPrefixChanged: {
      qwrapper.set_use_denominator_prefix(useDenominatorPrefix)
    }

    onNegativeExponentsChanged: {
      qwrapper.set_negative_exponents(negativeExponents)
    }
}
