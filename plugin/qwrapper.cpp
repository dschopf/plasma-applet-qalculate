//  Copyright (c) 2016 - 2017 Daniel Schopf <schopfdan@gmail.com>
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

#include "qwrapper.h"

#include <functional>

#include <readline/history.h>
#include <sys/stat.h>

#include <QFile>
#include <QNetworkReply>
#include <QNetworkRequest>

#if defined(HAVE_QALCULATE_2_0_0)
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
  const Number BASE_PRINT_LIMIT(1, 1, 64);
} // namespace

QWrapper::QWrapper(QObject *parent)
    : QObject(parent), m_pcalc(), m_eval_options(), m_print_options(),
      m_netmgr(), m_config(), m_state(), m_history()
{
  m_pcalc.reset(new Calculator());
  m_pcalc->loadGlobalDefinitions();
  m_pcalc->loadLocalDefinitions();
  m_pcalc->loadExchangeRates();
  m_pcalc->useDecimalPoint();

  m_eval_options.auto_post_conversion = POST_CONVERSION_NONE;
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

  m_config.enable_base2 = false;
  m_config.enable_base8 = false;
  m_config.enable_base10 = false;
  m_config.enable_base16 = false;
  m_config.timeout = 10000;

  m_state.aborted = false;
  m_state.input.clear();
  m_state.state = State::Idle;

  m_history.enabled = true;

  initHistoryFile();

  using_history();

  m_state.thread = std::thread([&]() { worker(); });
}

QWrapper::~QWrapper()
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

void QWrapper::evaluate(QString const &input, bool const enter_pressed)
{
  {
    std::unique_lock<std::mutex> _(m_state.mutex);

    switch (m_state.state) {
      case State::Stop:
        return;
      case State::Idle:
        break;
#if !defined(HAVE_QALCULATE_2_0_0)
      case State::Printing:
        m_pcalc->abortPrint();
        m_state.aborted = true;
        break;
#endif
      case State::Calculating:
        m_pcalc->abort();
        m_state.aborted = true;
        break;
    }

    m_state.input = input;
  }

  m_state.cond.notify_all();

  if (enter_pressed && !input.isEmpty() && (input != m_history.last_entry)) {
    m_history.last_entry = input;
    add_history(m_history.last_entry.toStdString().c_str());
    history_set_pos(history_length);
    append_history(1, m_history.filename.c_str());
  }
}

void QWrapper::setTimeout(const int timeout) { m_config.timeout = timeout; }

void QWrapper::setDisableHistory(const bool disabled)
{
  m_history.enabled = !disabled;

  if (disabled)
    return;

  auto ret = read_history(m_history.filename.c_str());
  if (ret < 0) {
    m_history.enabled = false;
  } else {
    ret = history_set_pos(history_length);
    auto h = history_get(history_length);
    if (h && h->line) {
      m_history.last_entry = h->line;
    } else {
      m_history.last_entry.clear();
    }
  }
}

void QWrapper::setHistorySize(const int size)
{
  if (size > 0 && size < 1e7)
    stifle_history(size);
}

void QWrapper::setAutoPostConversion(const int value)
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

void QWrapper::setStructuringMode(const int mode)
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

void QWrapper::setDecimalSeparator(const QString &separator)
{
  if (separator == ",") {
    m_print_options.decimalpoint_sign = ',';
    m_pcalc->useDecimalComma();
  } else {
    m_print_options.decimalpoint_sign = '.';
    m_pcalc->useDecimalPoint();
  }
}

void QWrapper::setAngleUnit(const int unit)
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

void QWrapper::setExpressionBase(const int base)
{
  if (base > 1 && base < 65)
    m_eval_options.parse_options.base = base;
}

void QWrapper::setEnableBase2(const bool enable)
{
  m_config.enable_base2 = enable;
}

void QWrapper::setEnableBase8(const bool enable)
{
  m_config.enable_base8 = enable;
}

void QWrapper::setEnableBase10(const bool enable)
{
  m_config.enable_base10 = enable;
}

void QWrapper::setEnableBase16(const bool enable)
{
  m_config.enable_base16 = enable;
}

void QWrapper::setResultBase(const int base)
{
  if (base > 1 && base < 65)
    m_print_options.base = base;
}

void QWrapper::setNumberFractionFormat(const int format)
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

void QWrapper::setNumericalDisplay(const int value)
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

void QWrapper::setIndicateInfiniteSeries(const bool value)
{
  m_print_options.indicate_infinite_series = value;
}

void QWrapper::setUseAllPrefixes(const bool value)
{
  m_print_options.use_all_prefixes = value;
}

void QWrapper::setUseDenominatorPrefix(const bool value)
{
  m_print_options.use_denominator_prefix = value;
}

void QWrapper::setNegativeExponents(const bool value)
{
  m_print_options.negative_exponents = value;
}

void QWrapper::updateExchangeRates()
{
  connect(&m_netmgr, SIGNAL(finished(QNetworkReply *)),
          SLOT(fileDownloaded(QNetworkReply *)));
  QNetworkRequest req(QUrl(m_pcalc->getExchangeRatesUrl().c_str()));
  req.setAttribute(QNetworkRequest::FollowRedirectsAttribute, true);
  m_netmgr.get(req);
}

QString QWrapper::getExchangeRatesUpdateTime()
{
  QDateTime dt;
  dt.setTime_t(m_pcalc->getExchangeRatesTime());
  return QLocale().toString(dt);
}

bool QWrapper::historyAvailable() { return m_history.enabled; }

QString QWrapper::getPrevHistoryLine()
{
  auto h = previous_history();
  if (h)
    return h->line;
  return "FIRST_ENTRY";
}

QString QWrapper::getNextHistoryLine()
{
  auto h = next_history();
  if (h)
    return h->line;
  return "LAST_ENTRY";
}

QString QWrapper::getFirstHistoryLine()
{
  history_set_pos(0);
  auto h = current_history();
  if (h)
    return h->line;
  return QString("NOT_FOUND");
}

void QWrapper::getLastHistoryLine()
{
  history_set_pos(history_length);
  return;
}

void QWrapper::worker()
{
  std::unique_lock<std::mutex> lock(m_state.mutex);

  while (m_state.state != State::Stop) {
    if (!m_state.input.isEmpty()) {
      m_state.state = State::Calculating;
      auto expr = m_pcalc->unlocalizeExpression(m_state.input.toStdString(),
                                                m_eval_options.parse_options);
      m_state.input.clear();
      lock.unlock();
#if defined(HAVE_QALCULATE_2_0_0)
      m_pcalc->startControl(m_config.timeout);
#endif
      runCalculation(expr);
#if defined(HAVE_QALCULATE_2_0_0)
      m_pcalc->stopControl();
#endif
      lock.lock();
    }

    m_state.state = State::Idle;
    while (m_state.input.isEmpty() && m_state.state != State::Stop)
      m_state.cond.wait(lock);
  }
}

void QWrapper::runCalculation(const std::string &expr)
{
  MathStructure result;

  // use a huge timeout values here, the wrapping control should handle our real
  // timeout

  const bool res = m_pcalc->calculate(&result, expr, TIMEOUT, m_eval_options);
  if (!res && checkReturnState())
    return;

#if defined(HAVE_QALCULATE_2_0_0)
  {
    std::unique_lock<std::mutex> lock(m_state.mutex);
    m_state.state = State::Printing;
  }
  m_pcalc->startPrintControl(m_config.timeout);
#endif
  QString result_string(PRINT_RESULT(result, HUGE_TIMEOUT_MS, m_print_options));
  if (result_string.isEmpty() || checkReturnState()) {
#if defined(HAVE_QALCULATE_2_0_0)
    m_pcalc->stopPrintControl();
#endif
    return;
  }

  const bool isInteger =
      result.representsNonNegative() && result.representsInteger();

  if (!isInteger || result.number().isGreaterThan(BASE_PRINT_LIMIT)) {
    emit resultText(result_string, false, "", "", "", "");
#if defined(HAVE_QALCULATE_2_0_0)
    m_pcalc->stopPrintControl();
#endif
    return;
  }

  QString result_base[4];

  for (auto &i : std::map<int, int>{{0, 2}, {1, 8}, {2, 10}, {3, 16}})
    if (printResultInBase(i.second, result, result_base[i.first])) {
#if defined(HAVE_QALCULATE_2_0_0)
      m_pcalc->stopPrintControl();
#endif
      return;
    }

  emit resultText(result_string, true, result_base[0], result_base[1],
                  result_base[2], result_base[3]);
#if defined(HAVE_QALCULATE_2_0_0)
  m_pcalc->stopPrintControl();
#endif
}

bool QWrapper::checkReturnState()
{
  {
    std::unique_lock<std::mutex> lock(m_state.mutex);
    if (m_state.aborted) {
      m_state.aborted = false;
      return true;
    }
  }
#if defined(HAVE_QALCULATE_2_0_0)
  if (m_pcalc->aborted()) {
#else
  if (m_pcalc->printingAborted()) {
#endif
    emit calculationTimeout();
    return true;
  }
  return false;
}

bool QWrapper::printResultInBase(const int base, MathStructure &result,
                                 QString &result_string)
{
  if (getBaseEnable(base) && m_print_options.base != base) {
    PrintOptions po(m_print_options);
    po.base = base;
    result_string = PRINT_RESULT(result, HUGE_TIMEOUT_MS, po);
    return checkReturnState();
  }
  return false;
}

bool QWrapper::getBaseEnable(const int base)
{
  switch (base) {
    case 2:
      return m_config.enable_base2;
    case 8:
      return m_config.enable_base8;
    case 10:
      return m_config.enable_base10;
    case 16:
      return m_config.enable_base16;
  }
  return false;
}

void QWrapper::initHistoryFile()
{
  std::string file_path(getenv("HOME"));

  file_path.append("/.local/share/plasma");

  struct stat st;

  auto ret = stat(file_path.c_str(), &st);
  if (ret < 0 || !S_ISDIR(st.st_mode)) {
    m_history.enabled = false;
    return;
  }

  file_path.append("/qalculate_history");

  m_history.filename.swap(file_path);
}

void QWrapper::fileDownloaded(QNetworkReply *pReply)
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
  dt.setTime_t(m_pcalc->getExchangeRatesTime());
  emit exchangeRatesUpdated(QLocale().toString(dt));
}
