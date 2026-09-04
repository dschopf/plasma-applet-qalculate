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

#include "HistoryFilterModel.h"

HistoryFilterModel::HistoryFilterModel(QObject* parent,
                                       IHistoryCallbacks* callbacks)
    : QSortFilterProxyModel(parent), m_model(this, callbacks)
{
  setSourceModel(&m_model);
  setFilterCaseSensitivity(Qt::CaseInsensitive);
  // setFilterRole(MyModel::NameRole);
}

auto HistoryFilterModel::filterText() const -> QString { return m_filterText; }

auto HistoryFilterModel::setFilterText(const QString& text) -> void
{
  if (m_filterText == text) {
    return;
  }

  m_filterText = text;
  setFilterRegularExpression(
      QRegularExpression(QRegularExpression::escape(text),
                         QRegularExpression::CaseInsensitiveOption));

  Q_EMIT filterTextChanged();
}

auto HistoryFilterModel::onHistoryModelReset() -> void
{
  return m_model.onHistoryModelReset();
}

auto HistoryFilterModel::onHistoryModelChanged(
    const HistoryAdditionEvent& event) -> void
{
  return m_model.onHistoryModelChanged(event);
}

int HistoryFilterModel::findBaseIndex(const int filteredRow)
{
  auto proxyIndex{index(filteredRow, 0)};
  if (!proxyIndex.isValid()) {
    return -1;
  }

  return mapToSource(proxyIndex).row();
}

int HistoryFilterModel::findFilterIndex(const int sourceRow)
{
  auto sourceIndex{sourceModel()->index(sourceRow, 0)};
  if (!sourceIndex.isValid()) {
    return -1;
  }

  auto proxyIndex{mapFromSource(sourceIndex)};

  return proxyIndex.isValid() ? proxyIndex.row() : -1;
}
