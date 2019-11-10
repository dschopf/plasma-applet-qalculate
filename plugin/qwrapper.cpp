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

#include <QProcess>

#include "qwrapper.h"

QWrapper::QWrapper(QObject* parent)
  : QObject(parent), m_qalc(Qalculate::instance())
{
  m_qalc.register_callbacks(this);
}

QWrapper::~QWrapper()
{
  m_qalc.unregister_callbacks(this);
}

void QWrapper::onResultText(QString result, QString resultBase2, QString resultBase8, QString resultBase10, QString resultBase16)
{
  emit resultText(result, resultBase2, resultBase8, resultBase10, resultBase16);
}

void QWrapper::onCalculationTimeout()
{
  emit calculationTimeout();
}

void QWrapper::onExchangeRatesUpdated(QString date)
{
  emit exchangeRatesUpdated(date);
}

void QWrapper::evaluate(QString const& input, bool const enter_pressed) { m_qalc.evaluate(input, enter_pressed, this); }

void QWrapper::launch(const QString& executable)
{
  QProcess::startDetached(executable);
}

void QWrapper::launch(const QString& executable, const QString& args, const QString& expression)
{
  QStringList list = args.split(' ', QString::SkipEmptyParts);

  for (auto& s : list)
    s.replace(QString("${INPUT}"), expression);

  QProcess::startDetached(executable, list);
}

int QWrapper::getVersion()
{
#if ((QALCULATE_MAJOR_VERSION == 3) && (QALCULATE_MINOR_VERSION >= 3)) || (QALCULATE_MAJOR_VERSION > 3)
  return 330;
#elif defined(HAVE_QALCULATE_2_6_0)
  return 260;
#elif defined(HAVE_QALCULATE_2_5_0)
  return 250;
#elif defined(HAVE_QALCULATE_2_2_0)
  return 220;
#elif defined(HAVE_QALCULATE_2_0_0)
  return 200;
#else
  return 100;
#endif
}

void QWrapper::setTimeout(const int timeout) { m_qalc.setTimeout(timeout); }

void QWrapper::setDisableHistory(const bool disabled) { m_qalc.setDisableHistory(disabled); }

void QWrapper::setHistorySize(const int size) { m_qalc.setHistorySize(size); }

void QWrapper::setAutoPostConversion(const int value) { m_qalc.setAutoPostConversion(value); }

int QWrapper::getAutoPostConversion() { return m_qalc.getAutoPostConversion(); }

void QWrapper::setStructuringMode(const int mode) { m_qalc.setStructuringMode(mode); }

void QWrapper::setDecimalSeparator(const QString& separator) { m_qalc.setDecimalSeparator(separator); }

void QWrapper::setAngleUnit(const int unit) { m_qalc.setAngleUnit(unit); }

void QWrapper::setExpressionBase(const int base) { m_qalc.setExpressionBase(base); }

void QWrapper::setEnableBase2(const bool enable) { m_qalc.setEnableBase2(enable); }

void QWrapper::setEnableBase8(const bool enable) { m_qalc.setEnableBase8(enable); }

void QWrapper::setEnableBase10(const bool enable) { m_qalc.setEnableBase10(enable); }

void QWrapper::setEnableBase16(const bool enable) { m_qalc.setEnableBase16(enable); }

void QWrapper::setResultBase(const int base) { m_qalc.setResultBase(base); }

void QWrapper::setDetectTimestamps(const bool enable) { m_qalc.setDetectTimestamps(enable); }

void QWrapper::setNumberFractionFormat(const int format) { m_qalc.setNumberFractionFormat(format); }

void QWrapper::setNumericalDisplay(const int value) { m_qalc.setNumericalDisplay(value); }

void QWrapper::setIndicateInfiniteSeries(const bool value) { m_qalc.setIndicateInfiniteSeries(value); }

void QWrapper::setUseAllPrefixes(const bool value) { m_qalc.setUseAllPrefixes(value); }

void QWrapper::setUseDenominatorPrefix(const bool value) { m_qalc.setUseDenominatorPrefix(value); }

void QWrapper::setNegativeExponents(const bool value) { m_qalc.setNegativeExponents(value); }

void QWrapper::setNegativeBinaryTwosComplement(const bool value) { m_qalc.setNegativeBinaryTwosComplement(value); }

void QWrapper::updateExchangeRates() { m_qalc.updateExchangeRates(); }

QString QWrapper::getExchangeRatesUpdateTime() { return m_qalc.getExchangeRatesUpdateTime(); }

QStringList QWrapper::getSupportedCurrencies() { return m_qalc.getSupportedCurrencies(); }

void QWrapper::setDefaultCurrency(const int currency_idx) { m_qalc.setDefaultCurrency(currency_idx); }

bool QWrapper::historyAvailable() { return m_qalc.historyAvailable(); }

QString QWrapper::getPrevHistoryLine() { return m_qalc.getPrevHistoryLine(); }

QString QWrapper::getNextHistoryLine() { return m_qalc.getNextHistoryLine(); }

QString QWrapper::getFirstHistoryLine() { return m_qalc.getFirstHistoryLine(); }

void QWrapper::getLastHistoryLine() { return m_qalc.getLastHistoryLine(); }
