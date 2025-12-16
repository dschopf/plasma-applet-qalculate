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

#include <functional>
#include <regex>
#include <string>

#include <libqalculate/Variable.h>
#include <pwd.h>
#include <readline/history.h>
#include <sys/stat.h>

#include <QFile>
#include <QNetworkReply>
#include <QNetworkRequest>
#include <QProcess>

#define TRANSLATION_DOMAIN "plasma_applet_com.dschopf.plasma.qalculate"
#include <klocalizedstring.h>

#include "qwrapper.h"

namespace {
  constexpr const char* MULTIPLY_SIGN{"\u00d7"};

  template <typename T>
  QString expandVector(const std::vector<T>& values,
                       const char* sign = MULTIPLY_SIGN)
  {
    QString res;
    for (size_t i{0}; i < values.size(); ++i) {
      res.append(QString::fromStdString(values[i].print()));
      if (i < values.size() - 1) {
        res.append(QChar::SpecialCharacter::Space).append(QString::fromLatin1(sign)).append(QChar::SpecialCharacter::Space);
      }
    }
    return res;
  }

  auto getFunction(const QString& target, const Qalculate* q)
  {
    static const std::map<QStringList, std::function<bool(const QString&)>> map{
        {{QString::fromLatin1("factors"), i18n("factors")},
         [q](const QString& expr) { return q->handleFactorize(expr); }},
        {{QString::fromLatin1("roman"), i18n("roman")},
         [q](const QString& expr) {
           return q->handleBaseConversion(expr, BASE_ROMAN_NUMERALS);
         }},
        {{QString::fromLatin1("binary"), i18n("Binary")},
         [q](const QString& expr) {
           return q->handleBaseConversion(expr, BASE_BINARY);
         }},
        {{QString::fromLatin1("octal"), i18n("octal")},
         [q](const QString& expr) {
           return q->handleBaseConversion(expr, BASE_OCTAL);
         }},
        {{QString::fromLatin1("decimal"), i18n("decimal")},
         [q](const QString& expr) {
           return q->handleBaseConversion(expr, BASE_DECIMAL);
         }},
        {{QString::fromLatin1("duodecimal"), i18n("duodecimal")},
         [q](const QString& expr) {
           return q->handleBaseConversion(expr, BASE_DUODECIMAL);
         }},
        {{QString::fromLatin1("hex"), QString::fromLatin1("hexadecimal"), i18n("hexadecimal")}, [q](const QString& expr) {
           return q->handleBaseConversion(expr, BASE_HEXADECIMAL);
         }}};

    for (const auto& item : map) {
      if (item.first.contains(target)) {
        return item.second;
      }
    }

    throw std::out_of_range("No matching function found");
  }
} // namespace

bool Qalculate::preprocessInput(const std::string& expr)
{
  if (m_config.detectTimestamps && checkTimestamp(expr)) {
    return true;
  }

  if (checkAssignment(expr)) {
    return true;
  }

  // "to" detection using qalculate library
  if (m_pcalc->hasToExpression(expr)) {
    return handleToExpression(expr);
  }

  // also detect "in" cases, for now only numbers without units
  // separated by space
  const auto items{QString::fromStdString(expr).split(QChar::SpecialCharacter::Space)};

  if (items.size() == 3 && items[1] == QString::fromLatin1("in")) {
    return handleInExpression(items);
  }

  if (items.size() == 4 && items[1] == QString::fromLatin1("in") &&
      (items[2] == QString::fromLatin1("base") || items[2] == i18n("base"))) {
      try {
        const auto base{std::stoul(items[3].toStdString())};
        return handleBaseConversionCustom(items[0], base);
      } catch (const std::exception&) {
        return false;
      }
  }

  return false;
}

bool Qalculate::checkTimestamp(const std::string& expr)
{
  std::smatch m;
  if (!std::regex_match(expr, m, std::regex(R"(^\d{9,12}$)"))) {
    return false;
  }

  QDateTime t{};
  t.setSecsSinceEpoch(QString::fromStdString(m[0].str()).toLongLong());
  m_state.active_cb->onResultText(QLocale().toString(t), {}, {}, {}, {});
  return true;
}

bool Qalculate::checkAssignment(const std::string& expr)
{
  std::smatch m;
  if (!std::regex_match(expr, m, std::regex(R"(^([^=]*?)\s*=\s*([^=]*?)$)"))) {
    return false;
  }

  m_pcalc->addVariable(new KnownVariable(m_pcalc->temporaryCategory(), m[1].str(), m[2].str()));

  // m_pcalc->deleteName(m[1].str());
  m_state.active_cb->onResultText(QString::fromStdString(expr), {}, {}, {}, {});

  return true;
}

bool Qalculate::handleToExpression(const std::string& expr)
{
  std::string value{expr};
  std::string target{};

  if (!m_pcalc->separateToExpression(value, target, m_eval_options)) {
    return false;
  }

  try {
    return getFunction(QString::fromStdString(target),
                       this)(QString::fromStdString(value));
  } catch (const std::out_of_range&) {
    return false;
  }
}

bool Qalculate::handleInExpression(const QStringList& items)
{
  try {
    return getFunction(items[2], this)(items[0]);
  } catch (const std::out_of_range&) {
    return false;
  }
}

bool Qalculate::handleFactorize(const QString& value) const
{
  Number number{value.toStdString()};
  std::vector<Number> result;

  number.factorize(result);

  QString result_string{value};

  result_string += QString::fromLatin1(" = ") + expandVector(result);

  m_state.active_cb->onResultText(result_string, {}, {}, {}, {});

  return true;
}

bool Qalculate::handleBaseConversion(const QString& value, uint16_t base) const
{
  // static const std::map<uint16_t, const char*> prefix{
  //     {2, "0b"}, {8, "0o"}, {16, "0x"}};

  Number number{value.toStdString()};

  PrintOptions po{m_print_options};
  po.base = base;

  std::string res{};
  // if (auto it{prefix.find(base)}; it != prefix.end()) {
  //   res = it->second;
  // }
  res += number.print(po);

  m_state.active_cb->onResultText(QString::fromStdString(res), {}, {}, {}, {});

  return true;
}

bool Qalculate::handleBaseConversionCustom(const QString& value,
                                           uint16_t base) const
{
  Number number{value.toStdString()};

  PrintOptions po{m_print_options};
  po.base = BASE_CUSTOM;
  auto temp{m_pcalc->customOutputBase()};
  m_pcalc->setCustomOutputBase(base);

  std::string res{number.print(po)};

  m_state.active_cb->onResultText(QString::fromStdString(res), {}, {}, {}, {});

  m_pcalc->setCustomOutputBase(temp);

  return true;
}
