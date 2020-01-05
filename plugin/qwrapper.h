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

#ifndef PLUGIN_QWRAPPER_H_INCLUDED
#define PLUGIN_QWRAPPER_H_INCLUDED

#include <QAbstractListModel>

#include "qalculate.h"

class HistoryListModel : public QAbstractListModel {
  Q_OBJECT

public:
  explicit HistoryListModel() : m_calc(Qalculate::instance()) {}
  explicit HistoryListModel(QObject* parent);

  enum {
    History = Qt::UserRole + 1
  };

  int rowCount(const QModelIndex & parent) const override;
  QVariant data(const QModelIndex & index, int role) const override;

  QHash<int,QByteArray> roleNames() const override;

private:
  Qalculate& m_calc;
};

class QWrapper : public QObject, public IQWrapperCallbacks, public IResultCallbacks {
  Q_OBJECT

public:
  explicit QWrapper(QObject* parent = 0);
  ~QWrapper();

  // IResultCallbacks
  void onResultText(QString result, QString resultBase2, QString resultBase8, QString resultBase10, QString resultBase16) override;
  void onCalculationTimeout() override;

  // IQWrapperCallbacks
  void onExchangeRatesUpdated(QString date) override;
  void onHistoryUpdated() override;

public Q_SLOTS:
  void evaluate(const QString& input, const bool enter_pressed);
  void launch(const QString& executable);
  void launch(const QString& executable, const QString& arguments, const QString& expression);
  int getVersion();

  // general settings
  void setTimeout(const int timeout);
  void setDisableHistory(const bool disabled);
  void setHistorySize(const int size);

  // evaluation settings
  void setAutoPostConversion(const int value);
  int getAutoPostConversion();
  void setStructuringMode(const int mode);
  void setDecimalSeparator(const QString& separator);
  void setAngleUnit(const int unit);
  void setExpressionBase(const int base);
  void setEnableBase2(const bool enable);
  void setEnableBase8(const bool enable);
  void setEnableBase10(const bool enable);
  void setEnableBase16(const bool enable);
  void setResultBase(const int base);
  void setDetectTimestamps(const bool enable);

  // print settings
  void setNumberFractionFormat(const int format);
  void setNumericalDisplay(const int value);
  void setIndicateInfiniteSeries(const bool value);
  void setUseAllPrefixes(const bool value);
  void setUseDenominatorPrefix(const bool value);
  void setNegativeExponents(const bool value);
  void setNegativeBinaryTwosComplement(const bool value);

  // currency settings
  void updateExchangeRates();
  QString getExchangeRatesUpdateTime();
  QStringList getSupportedCurrencies();
  void setDefaultCurrency(const int currency_idx);

  // history management
  HistoryListModel* getModel() { return &m_history; }
  int historyEntries();
  QString historyFilename() const;

signals:
  void resultText(QString result, QString resultBase2, QString resultBase8, QString resultBase10, QString resultBase16);
  void calculationTimeout();
  void exchangeRatesUpdated(QString date);

private:
  Qalculate& m_qalc;
  HistoryListModel m_history;
};

#endif // PLUGIN_QWRAPPER_H_INCLUDED
