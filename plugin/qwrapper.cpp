#include "qwrapper.h"

#include <QDebug>
#include <QFile>
#include <QLocale>
#include <QNetworkReply>
#include <QNetworkRequest>

QWrapper::QWrapper(QObject *parent)
  : QObject(parent)
  , m_pcalc()
  , m_result()
  , m_eval_options()
  , m_print_options()
  , m_netmgr()
{
  m_pcalc.reset(new Calculator());
  m_pcalc->loadGlobalDefinitions();
  m_pcalc->loadLocalDefinitions();
  m_pcalc->loadExchangeRates();

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
  m_print_options.decimalpoint_sign = ".";
  m_print_options.min_exp = EXP_NONE;
}

QWrapper::~QWrapper()
{
}

QString QWrapper::eval(QString const& expr, QString const& decimal_separator)
{
  if (expr.isEmpty())
    return QString();

  QString temp = expr;
  if (!decimal_separator.isEmpty() && decimal_separator.compare(".") != 0)
    temp.replace(decimal_separator, ".");
  QByteArray ba = temp.replace(QChar(0xA3), "GBP").replace(QChar(0xA5), "JPY").replace("$", "USD").replace(QChar(0x20AC), "EUR").toLatin1();
  char const* ctext = ba.data();

  m_result = m_pcalc->calculate(ctext, m_eval_options);
  m_result.format(m_print_options);

  temp = m_result.print(m_print_options).c_str();

  if (!decimal_separator.isEmpty() && decimal_separator.compare(".") != 0)
    temp.replace(".", decimal_separator);

  return temp;
}

bool QWrapper::last_result_is_integer()
{
  return m_result.representsInteger(false);
}

QString QWrapper::get_last_result_as(int const base)
{
  if (base < 2 || base > 64)
    return QString();

  PrintOptions po(m_print_options);

  po.base = base;

  m_result.format(po);

  return m_result.print(po).c_str();
}

QString QWrapper::get_exchange_rates_time()
{
#if defined(HAVE_QALCULATE_0_9_8)
  QDateTime dt;
  dt.setTime_t(m_pcalc->getExchangeRatesTime());
  return QLocale().toString(dt);
#else
  return QString();
#endif // HAVE_QALCULATE_0_9_8
}

void QWrapper::set_auto_post_conversion(int const value)
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

void QWrapper::set_structuring_mode(int const mode)
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

void QWrapper::set_angle_unit(int const unit)
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

void QWrapper::set_expression_base(int const base)
{
  if (base > 1 && base < 65)
    m_eval_options.parse_options.base = base;
}

void QWrapper::set_result_base(int const base)
{
  if (base > 1 && base < 65)
    m_print_options.base = base;
}

void QWrapper::set_number_fraction_format(const int format)
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

void QWrapper::set_numerical_display(const int value)
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

void QWrapper::set_indicate_infinite_series(const bool value)
{
  m_print_options.indicate_infinite_series = value;
}

void QWrapper::set_use_all_prefixes(const bool value)
{
  m_print_options.use_all_prefixes = value;
}

void QWrapper::set_use_denominator_prefix(const bool value)
{
  m_print_options.use_denominator_prefix = value;
}

void QWrapper::set_negative_exponents(const bool value)
{
  m_print_options.negative_exponents = value;
}

bool QWrapper::supports_exchange_rates_time()
{
#if defined(HAVE_QALCULATE_0_9_8)
  return true;
#else
  return false;
#endif // HAVE_QALCULATE_0_9_8
}

void QWrapper::update_exchange_rates()
{
  connect(&m_netmgr, SIGNAL (finished(QNetworkReply*)), SLOT (fileDownloaded(QNetworkReply*)));

  QNetworkRequest req(QUrl(m_pcalc->getExchangeRatesUrl().c_str()));

  req.setAttribute(QNetworkRequest::FollowRedirectsAttribute, true);

  m_netmgr.get(req);
}

void QWrapper::fileDownloaded(QNetworkReply* pReply)
{
  if (pReply->error() != QNetworkReply::NoError) {
    qDebug() << "[Qalculate!] Error downloading exchange rates (" << pReply->error() << "): " << pReply->errorString();
  }

  QByteArray data = pReply->readAll();

  pReply->deleteLater();

  QFile file(m_pcalc->getExchangeRatesFileName().c_str());

  if (!file.open(QIODevice::WriteOnly)) {
    qDebug() << "[Qalculate!] Error opening echange rates file";
    return;
  }

  QTextStream stream(&file);
  stream << data;
  stream.flush();
  file.close();

  m_pcalc->loadExchangeRates();
}
