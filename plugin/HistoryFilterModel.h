//  Copyright (c) 2016 - 2026 Daniel Schopf <schopfdan@gmail.com>
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

#ifndef PLUGIN_HISTORYFILTERMODEL_H_INCLUDED
#define PLUGIN_HISTORYFILTERMODEL_H_INCLUDED

#include "IQalculate.h"

#include "HistoryListModel.h"

#include <memory>

#include <QSortFilterProxyModel>

class HistoryFilterModel : public QSortFilterProxyModel {
  Q_OBJECT
  Q_PROPERTY(QString filterText READ filterText WRITE setFilterText NOTIFY
                 filterTextChanged)

public:
  explicit HistoryFilterModel(QObject* parent, IHistoryCallbacks* callbacks);

  auto filterText() const -> QString;
  auto setFilterText(const QString& text) -> void;

  auto onHistoryModelReset() -> void;
  auto onHistoryModelChanged(const HistoryAdditionEvent& event) -> void;

  Q_INVOKABLE auto findBaseIndex(const int index) -> int;
  Q_INVOKABLE auto findFilterIndex(const int index) -> int;

Q_SIGNALS:
  void filterTextChanged();

private:
  HistoryListModel m_model;
  QString m_filterText;
};

#endif // PLUGIN_HISTORYFILTERMODEL_H_INCLUDED
