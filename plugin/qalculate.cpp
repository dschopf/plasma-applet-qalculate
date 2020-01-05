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

#include <functional>
#include <regex>

#include <pwd.h>
#include <readline/history.h>
#include <sys/stat.h>

#include <QFile>
#include <QNetworkReply>
#include <QNetworkRequest>
#include <QProcess>

#include "qwrapper.h"

#if defined(PRINT_CONTROL_INCLUDED)
#define PRINT_RESULT(a, b, c) QString::fromStdString(m_pcalc->print(a, b, c))
#define TIMEOUT HUGE_TIMEOUT_MS
#else
#define PRINT_RESULT(a, b, c)                                                  \
  QString::fromStdString(m_pcalc->printMathStructureTimeOut(a, b, c))
#define TIMEOUT m_config.timeout
#endif

namespace
{
  constexpr int HUGE_TIMEOUT_MS = 10000000;
  constexpr auto print_limit_base2 = "0xffffffff";
  constexpr auto print_limit_base8 = "0xffffffffffffffff";
  constexpr auto print_limit_base16 = "0xffffffffffffffffffffffffffffffff";
} // namespace

Qalculate::Qalculate()
    : m_pcalc(), m_eval_options(), m_print_options(),
      m_netmgr(), m_config(), m_state(), m_history()
{
  m_pcalc.reset(new Calculator());
  m_pcalc->loadExchangeRates();
  m_pcalc->loadGlobalCurrencies();
  m_pcalc->loadGlobalDefinitions();
  m_pcalc->loadLocalDefinitions();
  m_pcalc->useDecimalPoint();

  m_eval_options.auto_post_conversion = POST_CONVERSION_BEST;
  m_eval_options.keep_zero_units = false;
  m_eval_options.parse_options.angle_unit = ANGLE_UNIT_RADIANS;
  m_eval_options.parse_options.rpn = false;
  m_eval_options.parse_options.base = 10;
  m_eval_options.parse_options.preserve_format = false;
  m_eval_options.parse_options.read_precision = DONT_READ_PRECISION;
  m_eval_options.structuring = STRUCTURING_SIMPLIFY;

  m_print_options.number_fraction_format = FRACTION_DECIMAL;
  m_print_options.indicate_infinite_series = false;
  m_print_options.use_all_prefixes = false;
  m_print_options.use_denominator_prefix = true;
  m_print_options.negative_exponents = false;
  m_print_options.lower_case_e = true;
  m_print_options.base = 10;
  m_print_options.min_exp = EXP_NONE;
#if defined(HAVE_BINARY_TWOS_COMPLEMENT_OPTION)
  m_print_options.twos_complement = true;
#endif

#if defined(INTERVAL_SUPPORT_INCLUDED)
  m_print_options.is_approximate = &m_is_approximate;
  m_print_options.interval_display = INTERVAL_DISPLAY_MIDPOINT;
#endif

  ParseOptions popts;

  popts.base = 16;

  m_print_limits[2].set(print_limit_base2, popts);
  m_print_limits[8].set(print_limit_base8, popts);
  m_print_limits[16].set(print_limit_base16, popts);

  initHistoryFile();
  using_history();

  m_state.thread = std::thread([&]() { worker(); });
}

Qalculate::~Qalculate()
{
  {
    std::unique_lock<std::mutex> _(m_state.mutex);
    m_state.state = State::Stop;
  }

  m_state.cond.notify_one();
  m_state.thread.join();
  m_pcalc->terminateThreads();
  m_pcalc.reset();
}

void Qalculate::register_callbacks(IQWrapperCallbacks* p)
{
  std::unique_lock<std::mutex> _(m_state.mutex);

  if (std::find_if(std::begin(m_state.cbs), std::end(m_state.cbs), [p](const IQWrapperCallbacks* q) { return p == q; }) == std::end(m_state.cbs))
    m_state.cbs.push_back(p);
}

void Qalculate::unregister_callbacks(IQWrapperCallbacks* p)
{
  std::unique_lock<std::mutex> _(m_state.mutex);

  auto it = std::find_if(std::begin(m_state.cbs), std::end(m_state.cbs), [p](const IQWrapperCallbacks* q) { return p == q; });
  if (it != std::end(m_state.cbs))
    m_state.cbs.erase(it);
}

void Qalculate::evaluate(const QString& input, const bool enter_pressed, IResultCallbacks* cb)
{
  std::unique_lock<std::mutex> _(m_state.mutex);

  if (m_state.state == State::Stop)
    return;

  if (m_history.enabled && enter_pressed && !input.isEmpty() && (input != m_history.last_entry)) {
    m_history.last_entry = input;
    add_history(m_history.last_entry.toStdString().c_str());
    append_history(1, m_history.filename.c_str());

    for (auto& cb : m_state.cbs)
      cb->onHistoryModelChanged();
  }

  // abort active calculation for the same callback instance
  if (m_state.active_cb == cb) {
#if !defined(PRINT_CONTROL_INCLUDED)
    if (m_state.state == State::Printing)
      m_pcalc->abortPrint();
#endif
    if (m_state.state == State::Calculating)
      m_pcalc->abort();
    m_state.aborted = true;
    m_state.cond.notify_all();
  }

  // remove pending calculation for the same callback instance
  auto it = std::find_if(std::begin(m_state.queue), std::end(m_state.queue), [cb](std::pair<IResultCallbacks*, QString>& q) { return std::get<0>(q) == cb; });
  if (it != std::end(m_state.queue))
    m_state.queue.erase(it);

  m_state.queue.push_back({cb, input});
  m_state.cond.notify_all();
}

void Qalculate::setTimeout(const int timeout) { m_config.timeout = timeout; }

void Qalculate::setDisableHistory(const bool disabled)
{
  m_history.enabled = !disabled;

  if (disabled)
    return;

  auto ret = read_history(m_history.filename.c_str());
  if (ret < 0) {
    m_history.enabled = false;
  } else {
    auto h = history_get(history_length);
    if (h && h->line) {
      m_history.last_entry = h->line;
    } else {
      m_history.last_entry.clear();
    }
  }
}

void Qalculate::setHistorySize(const int size)
{
  if (size > 0 && size < 1e7)
    stifle_history(size);
}

void Qalculate::setAutoPostConversion(const int value)
{
  switch (value) {
    case 0:
      m_eval_options.auto_post_conversion = POST_CONVERSION_NONE;
      break;
    case 1:
      m_eval_options.auto_post_conversion = POST_CONVERSION_BEST;
      break;
    case 2:
      m_eval_options.auto_post_conversion = POST_CONVERSION_BASE;
      break;
  }
}

int Qalculate::getAutoPostConversion()
{
  return m_eval_options.auto_post_conversion;
}

void Qalculate::setStructuringMode(const int mode)
{
  switch (mode) {
    case 0:
      m_eval_options.structuring = STRUCTURING_NONE;
      break;
    case 1:
      m_eval_options.structuring = STRUCTURING_SIMPLIFY;
      break;
    case 2:
      m_eval_options.structuring = STRUCTURING_FACTORIZE;
      break;
  }
}

void Qalculate::setDecimalSeparator(const QString& separator)
{
  if (separator == ",") {
    m_print_options.decimalpoint_sign = ',';
    m_pcalc->useDecimalComma();
  } else {
    m_print_options.decimalpoint_sign = '.';
    m_pcalc->useDecimalPoint();
  }
}

void Qalculate::setAngleUnit(const int unit)
{
  switch (unit) {
    case 0:
      m_eval_options.parse_options.angle_unit = ANGLE_UNIT_NONE;
      break;
    case 1:
      m_eval_options.parse_options.angle_unit = ANGLE_UNIT_RADIANS;
      break;
    case 2:
      m_eval_options.parse_options.angle_unit = ANGLE_UNIT_DEGREES;
      break;
    case 3:
      m_eval_options.parse_options.angle_unit = ANGLE_UNIT_GRADIANS;
      break;
  }
}

void Qalculate::setExpressionBase(const int base)
{
  if (base > 1 && base < 65)
    m_eval_options.parse_options.base = base;
}

void Qalculate::setEnableBase2(const bool enable)
{
  m_config.enable_base2 = enable;
}

void Qalculate::setEnableBase8(const bool enable)
{
  m_config.enable_base8 = enable;
}

void Qalculate::setEnableBase10(const bool enable)
{
  m_config.enable_base10 = enable;
}

void Qalculate::setEnableBase16(const bool enable)
{
  m_config.enable_base16 = enable;
}

void Qalculate::setResultBase(const int base)
{
  if (base > 1 && base < 65)
    m_print_options.base = base;
}

void Qalculate::setDetectTimestamps(const bool enable)
{
  m_config.detectTimestamps = enable;
}

void Qalculate::setNumberFractionFormat(const int format)
{
  switch (format) {
    case 0:
      m_print_options.number_fraction_format = FRACTION_DECIMAL;
      break;
    case 1:
      m_print_options.number_fraction_format = FRACTION_DECIMAL_EXACT;
      break;
    case 2:
      m_print_options.number_fraction_format = FRACTION_FRACTIONAL;
      break;
    case 3:
      m_print_options.number_fraction_format = FRACTION_COMBINED;
      break;
  }
}

void Qalculate::setNumericalDisplay(const int value)
{
  switch (value) {
    case 0:
      m_print_options.min_exp = EXP_NONE;
      break;
    case 1:
      m_print_options.min_exp = EXP_PURE;
      break;
    case 2:
      m_print_options.min_exp = EXP_SCIENTIFIC;
      break;
    case 3:
      m_print_options.min_exp = EXP_PRECISION;
      break;
    case 4:
      m_print_options.min_exp = EXP_BASE_3;
      break;
  }
}

void Qalculate::setIndicateInfiniteSeries(const bool value)
{
  m_print_options.indicate_infinite_series = value;
}

void Qalculate::setUseAllPrefixes(const bool value)
{
  m_print_options.use_all_prefixes = value;
}

void Qalculate::setUseDenominatorPrefix(const bool value)
{
  m_print_options.use_denominator_prefix = value;
}

void Qalculate::setNegativeExponents(const bool value)
{
  m_print_options.negative_exponents = value;
}

void Qalculate::setNegativeBinaryTwosComplement(const bool value)
{
#if defined(HAVE_BINARY_TWOS_COMPLEMENT_OPTION)
  m_print_options.twos_complement = value;
#else
  (void)value;
#endif
}

void Qalculate::updateExchangeRates()
{
  std::unique_lock<std::mutex> _(m_state.mutex);

  if (m_state.exchange_rate_updating)
    return;

  connect(&m_netmgr, SIGNAL(finished(QNetworkReply*)),
          SLOT(fileDownloaded(QNetworkReply*)));
  QNetworkRequest req(QUrl(m_pcalc->getExchangeRatesUrl().c_str()));
  req.setAttribute(QNetworkRequest::FollowRedirectsAttribute, true);
  m_netmgr.get(req);

  m_state.exchange_rate_updating = true;
}

QString Qalculate::getExchangeRatesUpdateTime()
{
  QDateTime dt;

#if defined(HAVE_QALCULATE_2_6_0)
  auto t = m_pcalc->getExchangeRatesTime(1);
#else
  auto t = m_pcalc->getExchangeRatesTime();
#endif

#if QT_VERSION >= QT_VERSION_CHECK(5, 8, 0)
  dt.setSecsSinceEpoch(t);
#else
  dt.setTime_t(t);
#endif

  return QLocale().toString(dt);
}

QStringList Qalculate::getSupportedCurrencies()
{
#if defined(LOCAL_CURRENCY_SUPPORTED)
  if (!m_currencies.length())
    initCurrencyList();

  return m_currencies;
#else
  return QStringList();
#endif
}

void Qalculate::setDefaultCurrency(const int currency_idx)
{
#if defined(LOCAL_CURRENCY_SUPPORTED)
  if (!m_currencies.length())
    initCurrencyList();

  if (currency_idx < 0 || currency_idx >= m_currencies.length())
    return;

  auto c = m_currencies[currency_idx].toStdString().c_str();
  m_pcalc->setLocalCurrency(m_pcalc->getActiveUnit(c));
#else
  (void)currency_idx;
#endif
}

int Qalculate::historyEntries()
{
  return m_history.enabled ? history_length : 0;
}

QString Qalculate::getHistoryEntry(int index)
{
  if (index > history_length || index < 0)
    return QString();

  auto* entry = history_get(history_length - index);

  return entry ? QString(entry->line): QString();
}

QString Qalculate::historyFilename() const
{
  if (m_history.filename.empty())
    return QString();

  return QString(m_history.filename.c_str());
}

void Qalculate::worker()
{
  std::unique_lock<std::mutex> lock(m_state.mutex);

  while (m_state.state != State::Stop) {
    if (!m_state.queue.empty()) {
      std::pair<IResultCallbacks*, QString> input = m_state.queue.front();
      m_state.queue.erase(std::begin(m_state.queue));
      m_state.state = State::Calculating;
      m_state.active_cb = std::get<0>(input);
      auto expr = m_pcalc->unlocalizeExpression(std::get<1>(input).toStdString(),
                                                m_eval_options.parse_options);
#if defined(INTERVAL_SUPPORT_INCLUDED)
      m_is_approximate = false;
#endif
      lock.unlock();
#if defined(PRINT_CONTROL_INCLUDED)
      m_pcalc->startControl(m_config.timeout);
#endif
      if (checkInput(expr))
        runCalculation(expr);
#if defined(PRINT_CONTROL_INCLUDED)
      m_pcalc->stopControl();
#endif
      lock.lock();
    }

    m_state.state = State::Idle;
    m_state.active_cb = nullptr;
    while (m_state.queue.empty() && m_state.state != State::Stop)
      m_state.cond.wait(lock);
  }
}

bool Qalculate::checkInput(std::string& expr)
{
  if (!m_config.detectTimestamps)
    return true;

  std::smatch m;

  if (std::regex_match(expr, m, std::regex(R"(^\d{9,12}$)"))) {
    QDateTime t;

#if QT_VERSION >= QT_VERSION_CHECK(5, 8, 0)
    t.setSecsSinceEpoch(QString(m[0].str().c_str()).toLongLong());
#else
    t.setTime_t(std::atoll(m[0].str().c_str()));
#endif

    m_state.active_cb->onResultText(t.toString(Qt::SystemLocaleLongDate), QString(), QString(), QString(), QString());
    return false;
  }

  return true;
}

void Qalculate::runCalculation(const std::string& expr)
{
  MathStructure result;

  // use a huge timeout values here, the wrapping control should handle our real
  // timeout

  const bool res = m_pcalc->calculate(&result, expr, TIMEOUT, m_eval_options);
  if (!res && checkReturnState())
    return;

#if !defined(PRINT_CONTROL_INCLUDED)
  {
    std::unique_lock<std::mutex> lock(m_state.mutex);
    m_state.state = State::Printing;
  }
  m_pcalc->startPrintControl(m_config.timeout);
#endif
  QString result_string(PRINT_RESULT(result, HUGE_TIMEOUT_MS, m_print_options));
  if (result_string.isEmpty() || checkReturnState()) {
#if !defined(PRINT_CONTROL_INCLUDED)
    m_pcalc->stopPrintControl();
#endif
    return;
  }

  // map of base and result string
  res_vector_t output = {{2, ""}, {8, ""}, {10, ""}, {16, ""}};

  for (auto& i : output) {
    if (printResultInBase(result, i)) {
#if !defined(PRINT_CONTROL_INCLUDED)
      m_pcalc->stopPrintControl();
#endif
      return;
    }
  }

#if defined(INTERVAL_SUPPORT_INCLUDED)
  if (m_is_approximate)
    result_string.prepend(QString::fromUtf8("\u2248"));
#endif

  m_state.active_cb->onResultText(result_string, output[0].second, output[1].second, output[2].second, output[3].second);
#if !defined(PRINT_CONTROL_INCLUDED)
  m_pcalc->stopPrintControl();
#endif
}

bool Qalculate::checkReturnState()
{
  {
    std::unique_lock<std::mutex> lock(m_state.mutex);
    if (m_state.aborted) {
      m_state.aborted = false;
      return true;
    }
  }
#if defined(PRINT_CONTROL_INCLUDED)
  if (m_pcalc->aborted()) {
#else
  if (m_pcalc->printingAborted()) {
#endif
    m_state.active_cb->onCalculationTimeout();
    return true;
  }
  return false;
}

bool Qalculate::printResultInBase(MathStructure& result, print_result_t& output)
{
  if (isBaseEnabled(output.first, result) &&
      m_print_options.base != output.first) {
    PrintOptions po(m_print_options);
    po.base = output.first;
    output.second = PRINT_RESULT(result, HUGE_TIMEOUT_MS, po);
    return checkReturnState();
  }
  return false;
}

bool Qalculate::isBaseEnabled(const uint8_t base, MathStructure& result)
{
  if (!result.representsInteger())
    return false;

  switch (base) {
    case 2:
#if defined(HAVE_BINARY_TWOS_COMPLEMENT_OPTION)
      if (m_config.enable_base2 && m_print_options.twos_complement) {
        auto num = result.number();
        if (num.isNegative())
          num.negate();
        return result.representsNumber() && !result.isZero() &&
               num.isLessThan(m_print_limits[2]);
      } else
        return result.representsPositive() &&
               result.number().isLessThan(m_print_limits[2]);
#else
      return m_config.enable_base2 && result.representsPositive() &&
             result.number().isLessThan(m_print_limits[2]);
#endif
    case 8:
      return m_config.enable_base8 && result.representsPositive() &&
             result.number().isLessThan(m_print_limits[8]);
    case 10:
      return m_config.enable_base10 && result.representsPositive();
    case 16:
      return m_config.enable_base16 && result.representsPositive() &&
             result.number().isLessThan(m_print_limits[16]);
  }
  return false;
}

void Qalculate::initHistoryFile()
{
  std::string file_path;

  if (getenv("XDG_DATA_HOME")) {
    file_path = std::string(getenv("XDG_DATA_HOME")) + "/qalculate";
  } else {
    file_path = std::string(getpwuid(getuid())->pw_dir) + "/.local/share/qalculate";
  }

  struct stat st;

  auto ret = stat(file_path.c_str(), &st);
  if (ret < 0) {
    if (errno == ENOENT)
      ret = mkdir(file_path.c_str(), S_IRWXU);
    if (ret < 0) {
      m_history.enabled = false;
      return;
    }
  } else if (!S_ISDIR(st.st_mode)) {
    m_history.enabled = false;
    return;
  }

  file_path.append("/plasma_applet_history");

  ret = stat(file_path.c_str(), &st);
  if (ret < 0) {
    if (errno == ENOENT) {
      write_history(file_path.c_str());
    } else {
      m_history.enabled = false;
      return;
    }
  }

  m_history.filename.swap(file_path);
}

#if defined(LOCAL_CURRENCY_SUPPORTED)

void Qalculate::initCurrencyList()
{
  m_currencies.clear();

  for (auto &u : m_pcalc->units) {
    if (u->isActive() && u->isCurrency()) {
      QString s = u->referenceName().c_str();
      QString p = u->print(false, false, false).c_str();
      if (p == s) p.clear();
      QString a = u->abbreviation(false, true).c_str();
      if (a == s) a.clear();
      if (a == p) a.clear();
      if (!p.isEmpty() || !a.isEmpty()) {
        s += " (";
        if (!p.isEmpty()) {
          s += p;
          if (!a.isEmpty())
            s += " - ";
        }
        if (!a.isEmpty())
          s += a;
        s += ")";
      }
      m_currencies << s;
    }
  }

  m_currencies.sort();
}

#endif

void Qalculate::fileDownloaded(QNetworkReply* pReply)
{
  if (pReply->error() != QNetworkReply::NoError)
    qDebug() << "[Qalculate!] Error downloading exchange rates ("
             << pReply->error() << "): " << pReply->errorString();

  QByteArray data = pReply->readAll();

  pReply->deleteLater();

  QFile file(m_pcalc->getExchangeRatesFileName().c_str());

  if (!file.open(QIODevice::WriteOnly)) {
    qDebug() << "[Qalculate!] Error opening exchange rates file";
    return;
  }

  QTextStream stream(&file);
  stream << data;
  stream.flush();
  file.close();

  m_pcalc->loadExchangeRates();

  QDateTime dt;

#if defined(HAVE_QALCULATE_2_6_0)
  auto t = m_pcalc->getExchangeRatesTime(1);
#else
  auto t = m_pcalc->getExchangeRatesTime();
#endif

#if QT_VERSION >= QT_VERSION_CHECK(5, 8, 0)
  dt.setSecsSinceEpoch(t);
#else
  dt.setTime_t(t);
#endif

  std::unique_lock<std::mutex> _(m_state.mutex);

  for (auto& cb : m_state.cbs)
    cb->onExchangeRatesUpdated(QLocale().toString(dt));

  m_state.exchange_rate_updating = false;
}
