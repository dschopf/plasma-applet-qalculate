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

#ifndef PLUGIN_QALCULATE_H_INCLUDED
#define PLUGIN_QALCULATE_H_INCLUDED

#include "Iqalculate.h"
#include <condition_variable>
#include <memory>
#include <mutex>
#include <thread>
#include <vector>

#include <QCoreApplication>
#include <QNetworkAccessManager>
#include <QObject>

#include <libqalculate/qalculate.h>

using print_result_t = std::pair<int, QString>;
using res_vector_t = std::vector<print_result_t>;

class Qalculate : public QObject, public IHistoryCallbacks {
  Q_OBJECT

private:
  enum class State {
    Calculating,
    Idle,
    Stop
  };

public:
  explicit Qalculate(QObject* parent);
  Qalculate(Qalculate const&) = delete;
  Qalculate(Qalculate const&&) = delete;
  void operator=(Qalculate const&) = delete;
  void operator=(Qalculate const&&) = delete;
  ~Qalculate();
#if defined(ENABLE_TESTS)
  void shutdown();
#endif // ENABLE_TESTS

  static std::shared_ptr<Qalculate> getInstance(QObject* parent = nullptr);

  void registerCallbacks(IQWrapperCallbacks* p);
  void unregisterCallbacks(IQWrapperCallbacks* p);

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
  void setUnicodeEnabled(const bool value);

  // currency settings
  void updateExchangeRates();
  QString getExchangeRatesUpdateTime();
  QStringList getSupportedCurrencies();
  void setDefaultCurrency(const int currency_idx);

  // history management
  int historyEntries() override;
  QString getHistoryEntry(int index) override;
  QString historyFilename() const;

private:
  void worker();
  void runCalculation(const std::string& expr);
  bool checkReturnState();
  bool printResultInBase(MathStructure& result, print_result_t& output);
  bool isBaseEnabled(const uint8_t base, MathStructure& result);
  void initHistoryFile();
  void initCurrencyList();

  // conversion handling in conversion.cpp

  /**
   * Function for handling internal input processing.
   *
   * @param expr The expression to process
   * @return Whether or not the input was handled
   */
  bool preprocessInput(const std::string& expr);
  bool checkTimestamp(const std::string& expr);
  bool checkAssignment(const std::string& expr);
  bool checkComparison(const std::string& expr);
  bool handleToExpression(const std::string& expr);
  bool handleInExpression(const QStringList& items);

public:
  // final handler functions need to be public for function map
  bool handleFactorize(const QString& value) const;
  bool handleBaseConversion(const QString& value, uint16_t base) const;
  bool handleBaseConversionCustom(const QString& value, uint16_t base) const;

private:
  std::unique_ptr<Calculator> m_pcalc;
  EvaluationOptions m_eval_options{};
  PrintOptions m_print_options{};
  bool m_is_approximate{false};
  std::map<int, Number> m_print_limits;
  QNetworkAccessManager m_netmgr;

  struct {
    bool enable_base2{false};
    bool enable_base8{false};
    bool enable_base10{false};
    bool enable_base16{false};
    int timeout{10000};
    bool detectTimestamps{false};
  } m_config{};

  struct {
    std::thread thread;
    std::mutex mutex;
    std::condition_variable cond;
    bool aborted{false};
    State state = State::Idle;
    std::vector<IQWrapperCallbacks*> cbs;
    bool exchange_rate_updating{false};
    std::vector<std::pair<IResultCallbacks*, QString>> queue;
    IResultCallbacks* active_cb{nullptr};
  } m_state{};

  struct {
    bool enabled{true};
    std::string filename;
    QString last_entry;
  } m_history{};

  QStringList m_currencies{};

private Q_SLOTS:
  void fileDownloaded(QNetworkReply* pReply);
};

#endif // PLUGIN_QALCULATE_H_INCLUDED
