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

#ifndef PLUGIN_IQALCULATE_H_INCLUDED
#define PLUGIN_IQALCULATE_H_INCLUDED

#include <QString>

class IHistoryCallbacks {
public:
  virtual ~IHistoryCallbacks() {}

  virtual int historyEntries() = 0;
  virtual QString getHistoryEntry(int index) = 0;
};

class IResultCallbacks {
public:
  virtual ~IResultCallbacks() {}

  virtual void onResultText(QString result, QString resultBase2, QString resultBase8, QString resultBase10, QString resultBase16) = 0;
  virtual void onCalculationTimeout() = 0;
};

class IQWrapperCallbacks {
public:
  virtual ~IQWrapperCallbacks() {}

  virtual void onHistoryModelChanged() = 0;
  virtual void onExchangeRatesUpdated(QString date) = 0;
};

#endif // PLUGIN_IQALCULATE_H_INCLUDED
