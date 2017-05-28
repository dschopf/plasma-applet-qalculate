#include <functional>

#include <readline/history.h>
#include <sys/stat.h>

#include <QFile>
#include <QNetworkReply>
#include <QNetworkRequest>

#include "qwrapper.h"

QWrapper::QWrapper(QObject* parent)
  : QObject(parent)
  , m_thread()
  , m_mutex()
  , m_cond()
  , m_state(State::Idle)
  , m_pcalc()
  , m_eval_options()
  , m_print_options()
  , m_latest_result()
  , m_netmgr()
  , m_timeout(10000)
  , m_input()
  , m_history()
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

  m_history.enabled = true;

  initHistoryFile();

  using_history();

  m_thread = std::thread(std::bind(&QWrapper::worker, this));
}

QWrapper::~QWrapper()
{
  {
    std::unique_lock<std::mutex> _(m_mutex);
    m_state = State::Stop;
  }

  m_cond.notify_one();
  m_thread.join();
}

void QWrapper::evaluate(QString const& input, bool const enter_pressed)
{
  {
    std::unique_lock<std::mutex> _(m_mutex);

    switch (m_state) {
      case State::Idle:
      case State::Stop:
        break;
      case State::Calculating:
        if (m_pcalc->busy())
          m_pcalc->abort();
        break;
      case State::Printing:
        m_pcalc->abortPrint();
        break;
    }

    m_input = input;
  }

  m_cond.notify_all();

  if (enter_pressed && !input.isEmpty() && (input != m_history.last_entry)) {
    m_history.last_entry = input;
    add_history(m_history.last_entry.toStdString().c_str());
    history_set_pos(history_length);
    append_history(1, m_history.filename.c_str());
  }
}

bool QWrapper::lastResultIsInteger()
{
  return m_latest_result.representsInteger(false);
}

QString QWrapper::getLastResultInBase(int const base)
{
  if (base < 2 || base > 64)
    return QString();

  PrintOptions po(m_print_options);

  po.base = base;

  m_latest_result.format(po);

  return m_latest_result.print(po).c_str();
}

void QWrapper::setTimeout(int const timeout)
{
  m_timeout = timeout;
}

void QWrapper::setDisableHistory(bool disabled)
{
  if (disabled) {
    m_history.enabled = false;
    return;
  }

  m_history.enabled = true;

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

void QWrapper::setHistorySize(int const size)
{
  if (size > 0 && size < 1e7)
    stifle_history(size);
}

void QWrapper::setAutoPostConversion(int const value)
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

void QWrapper::setStructuringMode(int const mode)
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

void QWrapper::setDecimalSeparator(QString const& separator)
{
  if (separator.compare(",") == 0) {
    m_print_options.decimalpoint_sign = ',';
    m_pcalc->useDecimalComma();
  } else {
    m_print_options.decimalpoint_sign = '.';
    m_pcalc->useDecimalPoint();
  }
}

void QWrapper::setAngleUnit(int const unit)
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

void QWrapper::setExpressionBase(int const base)
{
  if (base > 1 && base < 65)
    m_eval_options.parse_options.base = base;
}

void QWrapper::setResultBase(int const base)
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
  connect(&m_netmgr, SIGNAL (finished(QNetworkReply*)), SLOT (fileDownloaded(QNetworkReply*)));
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

bool QWrapper::historyAvailable()
{
  return m_history.enabled;
}

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
  std::unique_lock<std::mutex> _(m_mutex);
  while (m_state != State::Stop)
  {
    if (!m_input.isEmpty())
    {
      m_state = State::Calculating;
      auto expr = m_pcalc->unlocalizeExpression(m_input.toStdString(), m_eval_options.parse_options);
      m_input.clear();

      _.unlock();

      QString result;

      if (m_pcalc->calculate(&m_latest_result, expr, m_timeout, m_eval_options))
      {
        if (!m_latest_result.isAborted())
        {
          _.lock();
          m_state = State::Printing;
          _.unlock();

          m_pcalc->startPrintControl(m_timeout);
          m_latest_result.format(m_print_options);
          result = m_latest_result.print(m_print_options).c_str();
          if (m_pcalc->printingAborted())
            emit calculationTimeout();
          else
            emit resultText(result);
          m_pcalc->stopPrintControl();
        }
      }
      else
      {
        emit calculationTimeout();
      }

      _.lock();
    }

    m_state = State::Idle;
    if (m_input.isEmpty())
      m_cond.wait(_);
  }
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

void QWrapper::fileDownloaded(QNetworkReply* pReply)
{
  if (pReply->error() != QNetworkReply::NoError)
    qDebug() << "[Qalculate!] Error downloading exchange rates (" << pReply->error() << "): " << pReply->errorString();

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
