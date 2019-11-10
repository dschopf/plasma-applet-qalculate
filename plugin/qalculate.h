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

#ifndef PLUGIN_QALCULATE_H_INCLUDED
#define PLUGIN_QALCULATE_H_INCLUDED

#include <libqalculate/qalculate.h>

#include <condition_variable>
#include <memory>
#include <mutex>
#include <thread>

#include <QNetworkAccessManager>
#include <QObject>

#if ((QALCULATE_MAJOR_VERSION == 3) && (QALCULATE_MINOR_VERSION >= 3)) || (QALCULATE_MAJOR_VERSION > 3)
#define LOCAL_CURRENCY_SUPPORTED
#endif

#if defined(HAVE_QALCULATE_2_0_0) || defined(HAVE_QALCULATE_2_2_0) || defined(HAVE_QALCULATE_2_5_0) || defined(HAVE_QALCULATE_2_6_0)
#define PRINT_CONTROL_INCLUDED
#endif

#if defined(HAVE_QALCULATE_2_2_0) || defined(HAVE_QALCULATE_2_5_0) || defined(HAVE_QALCULATE_2_6_0)
#define INTERVAL_SUPPORT_INCLUDED
#endif

#if defined(HAVE_QALCULATE_2_5_0) || defined(HAVE_QALCULATE_2_6_0)
#define HAVE_BINARY_TWOS_COMPLEMENT_OPTION
#endif

typedef std::pair<int, QString> print_result_t;
typedef std::vector<print_result_t> res_vector_t;

enum class State {
  Calculating,
  Idle,
#if !defined(PRINT_CONTROL_INCLUDED)
  Printing,
#endif
  Stop
};

class IResultCallbacks {
public:
  virtual ~IResultCallbacks() {}

  virtual void onResultText(QString result, QString resultBase2, QString resultBase8, QString resultBase10, QString resultBase16) = 0;
  virtual void onCalculationTimeout() = 0;
};

class IQWrapperCallbacks {
public:
  virtual ~IQWrapperCallbacks() {}

  virtual void onExchangeRatesUpdated(QString date) = 0;
};

class Qalculate : public QObject {
  Q_OBJECT

private:
  Qalculate();
  ~Qalculate();

public:
  Qalculate(Qalculate const&) = delete;
  Qalculate(Qalculate const&&) = delete;
  void operator=(Qalculate const&) = delete;
  void operator=(Qalculate const&&) = delete;

  static Qalculate& instance() {
    static Qalculate inst;
    return inst;
  }

  void register_callbacks(IQWrapperCallbacks* p);
  void unregister_callbacks(IQWrapperCallbacks* p);

  // main function
  void evaluate(const QString& input, const bool enter_pressed, IResultCallbacks* cb);

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
  bool historyAvailable();
  QString getPrevHistoryLine();
  QString getNextHistoryLine();
  QString getFirstHistoryLine();
  void getLastHistoryLine();

private:
  void worker();
  bool checkInput(std::string& expr);
  void runCalculation(const std::string& expr);
  bool checkReturnState();
  bool printResultInBase(MathStructure& result, print_result_t& output);
  bool isBaseEnabled(const uint8_t base, MathStructure& result);
  void initHistoryFile();
#if defined(LOCAL_CURRENCY_SUPPORTED)
  void initCurrencyList();
#endif

  std::unique_ptr<Calculator> m_pcalc;
  EvaluationOptions m_eval_options;
  PrintOptions m_print_options;
#if defined(INTERVAL_SUPPORT_INCLUDED)
  bool m_is_approximate = false;
#endif
  std::map<int, Number> m_print_limits;
  QNetworkAccessManager m_netmgr;

  struct {
    bool enable_base2 = false;
    bool enable_base8 = false;
    bool enable_base10 = false;
    bool enable_base16 = false;
    int timeout = 10000;
    bool detectTimestamps = false;
  } m_config;

  struct {
    std::thread thread;
    std::mutex mutex;
    std::condition_variable cond;
    bool aborted = false;
    State state = State::Idle;
    std::vector<IQWrapperCallbacks*> cbs;
    bool exchange_rate_updating = false;
    std::vector<std::pair<IResultCallbacks*, QString>> queue;
    IResultCallbacks* active_cb = nullptr;
  } m_state;

  struct {
    bool enabled;
    std::string filename;
    QString last_entry;
  } m_history;

#if defined(LOCAL_CURRENCY_SUPPORTED)
  QStringList m_currencies;
#endif

private slots:
  void fileDownloaded(QNetworkReply* pReply);
};

#endif // PLUGIN_QALCULATE_H_INCLUDED
