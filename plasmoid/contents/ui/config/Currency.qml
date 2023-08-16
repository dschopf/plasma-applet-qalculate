//  Copyright (c) 2016 - 2023 Daniel Schopf <schopfdan@gmail.com>
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

import org.kde.private.qalculate 1.0

Item {

  property int cfg_libVersion
  property alias cfg_updateExchangeRatesAtStartup: cbUpdateExchangeRatesAtStartup.checked
  property alias cfg_updateExchangeRatesRegularly: cbUpdateExchangeRatesRegularly.checked
  property alias cfg_exchangeRateUpdateInterval: sbExchangeRateUpdateInterval.value
  property alias cfg_exchangeRatesTime: lLastUpdateValue.text
  property alias cfg_switchDefaultCurrency: cbSwitchDefaultCurrency.checked
  property string cfg_selectedDefaultCurrency: cmbLocale.currentText

  QWrapper {
    id: qwr
  }

  GridLayout {
    anchors.left: parent.left
    anchors.right: parent.right
    columns: 2

    CheckBox {
      id: cbUpdateExchangeRatesAtStartup
      text: i18n("Update exchange rates at startup")
      Layout.columnSpan: 2
    }

    RowLayout {
      Layout.columnSpan: 2

      CheckBox {
        id: cbUpdateExchangeRatesRegularly
        enabled: cbUpdateExchangeRatesAtStartup.checked
        text: i18n("Update exchange rates every")
      }

      SpinBox {
        id: sbExchangeRateUpdateInterval
        enabled: cbUpdateExchangeRatesAtStartup.checked
        decimals: 0
        stepSize: 1
        value: 24
        minimumValue: 1
        maximumValue: 72
      }

      Label {
        id: lFooBar
        enabled: cbUpdateExchangeRatesAtStartup.checked
        text: i18np("hour", "hours", sbExchangeRateUpdateInterval.value)
      }
    }

    Label {
      id: lLastUpdateLabel
      text: i18nc("Exchange rates", "Last update") + ':'
    }

    Label {
      id: lLastUpdateValue
      text: cfg_updateExchangeRatesAtStartup
    }

    CheckBox {
      id: cbSwitchDefaultCurrency
      text: i18n("Switch default currency")
      visible: cfg_libVersion >= 330
      Layout.columnSpan: 2
    }

    ComboBox {
      id: cmbLocale
      Layout.columnSpan: 2
      enabled: cbSwitchDefaultCurrency.checked
      model: qwr.getSupportedCurrencies()
      visible: cfg_libVersion >= 330
      currentIndex: cfg_selectedDefaultCurrency

      onCurrentIndexChanged: {
        qwr.setDefaultCurrency(currentIndex)
        cfg_selectedDefaultCurrency = currentIndex
      }

      onEnabledChanged: {
        qwr.setDefaultCurrency(enabled ? currentIndex : -1)
      }
    }

    Label {
      visible: cfg_libVersion >= 330 && cmbLocale.enabled && qwr.getAutoPostConversion() != 1
      text: i18n("Default currency does only work when Input->Conversion is set to \"Best\"!")
      Layout.columnSpan: 2
    }
  }
}
