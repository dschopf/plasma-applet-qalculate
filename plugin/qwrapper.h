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
    void evaluate(const QString& input, const bool enter_pressed);

    // general settings
    void setTimeout(const int timeout);
    void setDisableHistory(const bool disabled);
    void setHistorySize(const int size);

    // evaluation settings
    void setAutoPostConversion(const int value);
    void setStructuringMode(const int mode);
    void setDecimalSeparator(const QString& separator);
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
    void resultText(QString result, bool resultIsInteger, QString resultBase2, QString resultBase8, QString resultBase10, QString resultBase16);
    void calculationTimeout();
    void exchangeRatesUpdated(QString date);

  private:
    void worker();
    void runCalculation(const std::string& lock);
    bool checkReturnState();
    bool printResultInBase(const int base, MathStructure& result, QString& result_string);
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
    void fileDownloaded(QNetworkReply* pReply);
};

#endif // QWRAPPER_H_INCLUDED
