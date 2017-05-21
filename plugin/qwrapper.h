#ifndef QWRAPPER_H_INCLUDED
#define QWRAPPER_H_INCLUDED

#include <condition_variable>
#include <memory>
#include <mutex>
#include <thread>

#include <QNetworkAccessManager>
#include <QObject>

#include <libqalculate/qalculate.h>

enum class State {
  Calculating,
  Idle,
  Printing,
  Stop
};

class QWrapper
  : public QObject
{
  Q_OBJECT

  public:
    explicit QWrapper(QObject* parent = 0);
    ~QWrapper();

  public Q_SLOTS:
    void evaluate(QString const& input, bool const enter_pressed);

    bool lastResultIsInteger();
    QString getLastResultInBase(int const base);

    // general settings
    void setTimeout(int const timeout);
    void setDisableHistory(bool disabled);
    void setHistorySize(int const size);

    // evaluation settings
    void setAutoPostConversion(int const value);
    void setStructuringMode(int const mode);
    void setDecimalSeparator(QString const& separator);
    void setAngleUnit(int const unit);
    void setExpressionBase(int const base);
    void setResultBase(int const base);

    // print settings
    void setNumberFractionFormat(int const format);
    void setNumericalDisplay(int const value);
    void setIndicateInfiniteSeries(bool const value);
    void setUseAllPrefixes(bool const value);
    void setUseDenominatorPrefix(bool const value);
    void setNegativeExponents(bool const value);

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
    void resultText(QString result);
    void calculationTimeout();
    void exchangeRatesUpdated(QString date);

  private:
    void worker();

    // history file handling
    void initHistoryFile();

    // threading
    std::thread m_thread;
    std::mutex m_mutex;
    std::condition_variable m_cond;
    State m_state;

    std::unique_ptr<Calculator> m_pcalc;
    EvaluationOptions m_eval_options;
    PrintOptions m_print_options;

    MathStructure m_latest_result;

    QNetworkAccessManager m_netmgr;
    int m_timeout;
    QString m_input;

    // history
    struct {
      bool enabled;
      std::string filename;
      QString last_entry;
    } m_history;

  private slots:
    void fileDownloaded(QNetworkReply* pReply);
};

#endif // QWRAPPER_H_INCLUDED
