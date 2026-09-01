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

#ifndef PLUGIN_HISTORYMANAGER_H_INCLUDED
#define PLUGIN_HISTORYMANAGER_H_INCLUDED

#include <condition_variable>
#include <mutex>
#include <filesystem>
#include <thread>

#include <QFile>
#include <QJsonObject>
#include <QSaveFile>
#include <QString>
#include <QQueue>

#include "IQalculate.h"

class HistoryManager {
  static constexpr int MAX_HISTORY_SIZE{10'000'000};

  struct HistoryEntry {
    QString input;
    QString result;
    // QDateTime timestamp;
    // Future additions:
    // bool favorite;
    // QVariantMap metadata;

    auto to_json() const -> QJsonObject;
  };

public:
  HistoryManager();
  HistoryManager(const HistoryManager&) = delete;
  HistoryManager(const HistoryManager&&) = delete;
  HistoryManager operator=(const HistoryManager&) = delete;
  HistoryManager operator=(const HistoryManager&&) = delete;
  ~HistoryManager();

  auto enable() -> void;
  auto disable() -> void;
  auto set_size(const int size) -> void;
  auto entry_count() -> int;
  auto get_filename() const -> QString;

  auto add(const QString& raw_input, const QString& result, const bool fix_history_position) -> HistoryAdditionEvent;
  auto get(int index) -> QString;
  auto search(QString query) const -> QQueue<HistoryEntry>;

  auto entries() const -> const QQueue<HistoryEntry>&;

private:
  auto load() -> void;
  auto save() -> void;

  auto initHistoryFile() -> void;
  auto openHistoryFile() -> std::unique_ptr<QFile>;
  auto openHistoryFileForWrite() -> std::unique_ptr<QSaveFile>;
  auto worker() -> void;

  QQueue<HistoryEntry> m_entries;
  bool m_cancel{false};
  bool m_dirty{false};
  bool m_enabled{false};
  int m_size{MAX_HISTORY_SIZE};
  std::filesystem::path m_history_file{};
  std::thread m_thread;
  std::mutex m_mutex;
  std::condition_variable m_cond;
};

#endif // PLUGIN_QALCULATE_H_INCLUDED
