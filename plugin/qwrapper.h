#ifndef QWRAPPER_H
#define QWRAPPER_H

#include <memory>
#include <QNetworkAccessManager>
#include <QObject>

#include <libqalculate/qalculate.h>

class Calculator;

class QWrapper : public QObject
{
  Q_OBJECT

  public:
    explicit QWrapper(QObject* parent = 0);
    ~QWrapper();

  public Q_SLOTS:
    QString eval(QString const& expr, QString const& decimal_separator);
    bool last_result_is_integer();
    QString get_last_result_as(int const base);
    QString get_exchange_rates_time();

    // evaluation settings
    void set_auto_post_conversion(int const value);
    void set_structuring_mode(int const mode);
    void set_angle_unit(int const unit);
    void set_expression_base(int const base);
    void set_result_base(int const base);

    // print settings
    void set_number_fraction_format(int const format);
    void set_numerical_display(int const value);
    void set_indicate_infinite_series(bool const value);
    void set_use_all_prefixes(bool const value);
    void set_use_denominator_prefix(bool const value);
    void set_negative_exponents(bool const value);

    void update_exchange_rates();

  private:
    std::unique_ptr<Calculator> m_pcalc;
    MathStructure m_result;
    EvaluationOptions m_eval_options;
    PrintOptions m_print_options;
    QNetworkAccessManager m_netmgr;

  private slots:
    void fileDownloaded(QNetworkReply* pReply);
};

#endif // QWRAPPER_H
