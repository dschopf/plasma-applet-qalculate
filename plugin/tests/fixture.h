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

#ifndef PLUGIN_TESTS_FIXTURE_H_INCLUDED
#define PLUGIN_TESTS_FIXTURE_H_INCLUDED

#include <gmock/gmock.h>
#include <gtest/gtest.h>
#include <QCoreApplication>
#include <QString>

#include "../qalculate.h"

// class Logger {
//   private:
//     std::ostream &stream;
//
//     void print_time() {
//         auto ms{duration_cast<std::chrono::milliseconds>(std::chrono::system_clock::now().time_since_epoch()) % 1000};
//         std::time_t t = std::time(nullptr);
//         stream << "[" << std::put_time(std::localtime(&t), "%F %T") << "." << ms << "] ";
//     }
//   public:
//     //Maybe also take options for how to log?
//     Logger(std::ostream &stream) : stream(stream) { }
//
//     template <typename T>
//     std::ostream &operator<<(const T &thing)  {
//         print_time();
//         return stream << thing;
//     }
// };

class MockResults : public IResultCallbacks {
 public:
  MOCK_METHOD(void, onResultText, (QString result, QString resultBase2, QString resultBase8, QString resultBase10, QString resultBase16), (override));
  MOCK_METHOD(void, onCalculationTimeout, (), (override));
};

class QalculateTest : public testing::Test {
 protected:
  void SetUp() override {
    m_calc = Qalculate::getInstance(QCoreApplication::instance());
  }

  // void TearDown() override {}

  std::shared_ptr<Qalculate> m_calc{};
};

#endif // PLUGIN_TESTS_FIXTURE_H_INCLUDED
