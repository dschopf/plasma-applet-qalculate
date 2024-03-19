//  Copyright (c) 2016 - 2023 Daniel Schopf <schopfdan@gmail.com>
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

#define TRANSLATION_DOMAIN "plasma_applet_org.kde.plasma.qalculate"
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
      res += values[i].print().c_str();
      if (i < values.size() - 1) {
        res.append(' ').append(sign).append(' ');
      }
    }
    return res;
  }
} // namespace

bool Qalculate::handleToExpression(const std::string& expr)
{
  std::string value{expr};
  std::string target{};
  if (!m_pcalc->separateToExpression(value, target, m_eval_options)) {
    return true;
  }

  if (target == "factors" ||
      QString::fromStdString(target) == i18n("factors")) {
    return handleFactorize(value);
  }

  return true;
}

bool Qalculate::handleFactorize(const std::string& value)
{
  Number number{value};
  std::vector<Number> result;

  number.factorize(result);

  QString result_string{value.c_str()};

  result_string += QString(" = ") + expandVector(result);

  m_state.active_cb->onResultText(result_string, {}, {}, {}, {});

  return false;
}
