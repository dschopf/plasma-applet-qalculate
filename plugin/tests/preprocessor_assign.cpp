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

#include <chrono>
#include <future>

#include "fixture.h"
#include "helpers.h"

using namespace Qt::Literals::StringLiterals;

// Demonstrate some basic assertions.
TEST_F(QalculateTest, BasicAssertions) {
  MockResults results{};

  // Assign a value
  std::promise<void> promise{};
  auto future{promise.get_future()};

  const auto assignA{u"A = 1"_s};

  EXPECT_CALL(results, onResultText).WillOnce([&promise, assignA](QString result, QString, QString, QString, QString) {
    EXPECT_QSTREQ(assignA, result);
    promise.set_value();
  });

  m_calc->evaluate(assignA, false, &results);
  ASSERT_EQ(future.wait_for(std::chrono::seconds(1)), std::future_status::ready);

  // Check if assignment worked
  promise = {};
  future = promise.get_future();

  const auto add1{u"A + 1"_s};
  const auto expected{u"2"_s};

  EXPECT_CALL(results, onResultText).WillOnce([&promise, expected](QString result, QString, QString, QString, QString) {
    EXPECT_QSTREQ(expected, result);
    promise.set_value();
  });

  m_calc->evaluate(add1, false, &results);
  ASSERT_EQ(future.wait_for(std::chrono::seconds(1)), std::future_status::ready);
}
