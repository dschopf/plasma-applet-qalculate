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

import com.dschopf.plasma.qalculate

KCM.SimpleKCM {
  property alias cfg_updateExchangeRatesAtStartup: cbUpdateExchangeRatesAtStartup.checked
  property alias cfg_updateExchangeRatesRegularly: cbUpdateExchangeRatesRegularly.checked
  property alias cfg_exchangeRateUpdateInterval: sbExchangeRateUpdateInterval.value
  property alias cfg_exchangeRatesTime: lLastUpdateValue.text
  property alias cfg_switchDefaultCurrency: cbSwitchDefaultCurrency.checked
  property string cfg_selectedDefaultCurrency: cmbLocale.currentText

  QWrapper {
    id: qwr
  }

  Kirigami.FormLayout {
    anchors.left: parent.left
    anchors.right: parent.right

    CheckBox {
      id: cbUpdateExchangeRatesAtStartup
      Kirigami.FormData.label: i18n("Currency") + ':'
      text: i18n("Update exchange rates at startup")
    }

    Label {
      id: lLastUpdateValue
      Kirigami.FormData.label: i18nc("Exchange rates", "Last update") + ':'
      text: cfg_updateExchangeRatesAtStartup
    }

    Item {
      Kirigami.FormData.isSection: true
    }

    CheckBox {
      id: cbUpdateExchangeRatesRegularly
      text: i18n("Update exchange rates regularly")
    }

    SpinBox {
      id: sbExchangeRateUpdateInterval
      enabled: cbUpdateExchangeRatesRegularly.checked
      value: 24
      from: 1
      to: 72
      valueFromText: function(text, locale) { return text.split(" ")[0] }
      textFromValue: function(value, locale) { return value + " " + i18np("hour", "hours", value) }
    }

    Item {
      Kirigami.FormData.isSection: true
    }

    CheckBox {
      id: cbSwitchDefaultCurrency
      Kirigami.FormData.label: i18nc("Exchange rates", "Last update") + ":"
      text: i18n("Switch default currency")
      Layout.columnSpan: 2
    }

    ComboBox {
      id: cmbLocale
      Layout.columnSpan: 2
      enabled: cbSwitchDefaultCurrency.checked
      model: qwr.getSupportedCurrencies()
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
      visible: cmbLocale.enabled && qwr.getAutoPostConversion() != 1
      text: i18n("Default currency does only work when Input->Conversion is set to \"Best\"!")
      Layout.columnSpan: 2
    }
  }
}
