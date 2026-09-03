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

#include "HistoryListModel.h"

HistoryListModel::HistoryListModel(QObject* parent,
                                   IHistoryCallbacks* callbacks)
    : QAbstractListModel(parent), m_callbacks(callbacks)
{
}

int HistoryListModel::rowCount(const QModelIndex& parent) const
{
  return !parent.isValid() ? m_callbacks->historyEntries() : 0;
}

QVariant HistoryListModel::data(const QModelIndex& index, int /*role*/) const
{
  return index.isValid() ? m_callbacks->getHistoryEntry(index.row())
                         : QVariant();
}

QHash<int, QByteArray> HistoryListModel::roleNames() const
{
  QHash<int, QByteArray> roles;
  roles[History] = "history";
  return roles;
}

void HistoryListModel::onHistoryModelReset()
{
  beginResetModel();
  endResetModel();
}

void HistoryListModel::onHistoryModelChanged(const HistoryAdditionEvent& event)
{
  switch (event.event) {
    case HistoryAdditionEvent::Event::ROW_ADDED_BEGIN:
      beginInsertRows(QModelIndex(), 0, 0);
      endInsertRows();
      return;
    case HistoryAdditionEvent::Event::ROW_ADDED_BEGIN_TRUNCATE:
      beginRemoveRows(QModelIndex(), event.old_pos, event.old_pos);
      endRemoveRows();
      beginInsertRows(QModelIndex(), 0, 0);
      endInsertRows();
      return;
    case HistoryAdditionEvent::Event::ROW_MOVED:
      beginMoveRows(QModelIndex(), event.old_pos, event.old_pos, QModelIndex(),
                    0);
      endMoveRows();
      return;
    case HistoryAdditionEvent::Event::SKIPPED:
      return;
  }
}
