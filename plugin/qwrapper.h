//  Copyright (c) 2016 - 2018 Daniel Schopf <schopfdan@gmail.com>
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

#ifndef QWRAPPER_H_INCLUDED
#define QWRAPPER_H_INCLUDED

#include <libqalculate/qalculate.h>

#include <condition_variable>
#include <memory>
#include <mutex>
#include <thread>

#include <QNetworkAccessManager>
#include <QObject>

enum class State {
  Calculating,
  Idle,
#if !defined(HAVE_QALCULATE_2_0_0)
  Printing,
#endif
  Stop
};

class QWrapper : public QObject {
  Q_OBJECT

public:
  explicit QWrapper(QObject *parent = 0);
  ~QWrapper();

public Q_SLOTS:
  void evaluate(const QString &input, const bool enter_pressed);

  // general settings
  void setTimeout(const int timeout);
  void setDisableHistory(const bool disabled);
  void setHistorySize(const int size);

  // evaluation settings
  void setAutoPostConversion(const int value);
  void setStructuringMode(const int mode);
  void setDecimalSeparator(const QString &separator);
  void setAngleUnit(const int unit);
  void setExpressionBase(const int base);
  void setEnableBase2(const bool enable);
  void setEnableBase8(const bool enable);
  void setEnableBase10(const bool enable);
  void setEnableBase16(const bool enable);
  void setResultBase(const int base);

  // print settings
  void setNumberFractionFormat(const int format);
  void setNumericalDisplay(const int value);
  void setIndicateInfiniteSeries(const bool value);
  void setUseAllPrefixes(const bool value);
  void setUseDenominatorPrefix(const bool value);
  void setNegativeExponents(const bool value);

  // currency settings
  void updateExchangeRates();
  QString getExchangeRatesUpdateTime();

  // history management
  bool historyAvailable();
  QString getPrevHistoryLine();
  QString getNextHistoryLine();
  QString getFirstHistoryLine();
  void getLastHistoryLine();

signals:
  void resultText(QString result, bool resultIsInteger, QString resultBase2,
                  QString resultBase8, QString resultBase10,
                  QString resultBase16);
  void calculationTimeout();
  void exchangeRatesUpdated(QString date);

private:
  void worker();
  void runCalculation(const std::string &lock);
  bool checkReturnState();
  bool printResultInBase(const int base, MathStructure &result,
                         QString &result_string);
  bool getBaseEnable(const int base);
  void initHistoryFile();

  std::unique_ptr<Calculator> m_pcalc;
  EvaluationOptions m_eval_options;
  PrintOptions m_print_options;
  QNetworkAccessManager m_netmgr;

  struct {
    bool enable_base2;
    bool enable_base8;
    bool enable_base10;
    bool enable_base16;
    int timeout;
  } m_config;

  struct {
    std::thread thread;
    std::mutex mutex;
    std::condition_variable cond;
    bool aborted;
    QString input;
    State state;
  } m_state;

  struct {
    bool enabled;
    std::string filename;
    QString last_entry;
  } m_history;

private slots:
  void fileDownloaded(QNetworkReply *pReply);
};

#endif // QWRAPPER_H_INCLUDED
