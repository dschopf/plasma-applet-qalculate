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

#include "HistoryManager.h"

#include <filesystem>

#include <pwd.h>
#include <sys/stat.h>
#include <unistd.h>

#include <QDebug>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonParseError>

namespace fs = std::filesystem;

namespace
{
  // history file location
  constexpr auto HISTORY_FILE = "plasma_applet_history.json";
  constexpr auto LOCAL_SHARE = ".local/share";
  constexpr auto QALCULATE_FOLDER = "qalculate";

  // json parsing
  constexpr auto HISTORY_FILE_VERSION = 1;

  constexpr auto ENTRIES_FIELD_ID = "entries";
  constexpr auto INPUT_FIELD_ID = "input";
  constexpr auto RESULT_FIELD_ID = "result";
  constexpr auto VERSION_FIELD_ID = "version";
}

auto HistoryManager::HistoryEntry::to_json() const -> QJsonObject
{
  QJsonObject obj;

  obj[QString::fromUtf8(INPUT_FIELD_ID)] = input;
  obj[QString::fromUtf8(RESULT_FIELD_ID)] = result;

  return obj;
}

HistoryManager::HistoryManager()
{
  initHistoryFile();
  if (m_enabled) {
    load();
  }
  m_thread = std::thread([&]() { worker(); });
}

HistoryManager::~HistoryManager()
{
  save();
  {
    std::unique_lock lock{m_mutex};
    m_cancel = true;
    m_cond.notify_all();
  }
  if (m_thread.joinable()) {
    m_thread.join();
  }
}

auto HistoryManager::enable() -> void
{
  std::unique_lock lock{m_mutex};
  m_enabled = true;
}

auto HistoryManager::disable() -> void
{
  std::unique_lock lock{m_mutex};
  m_enabled = false;
}

auto HistoryManager::set_size(const int size) -> void
{
  if (size > 0 && size <= MAX_HISTORY_SIZE) {
    if (size < m_size) {
      std::unique_lock lock{m_mutex};
      if (size < m_entries.size()) {
        m_entries.erase(m_entries.begin() + size, m_entries.end());
      }
    }
    m_size = size;
  }
}

auto HistoryManager::entry_count() -> int
{
  std::unique_lock lock{m_mutex};
  return m_enabled ? static_cast<int>(m_entries.size()) : 0;
}

auto HistoryManager::get_filename() const -> QString
{
  return m_enabled ? QString::fromStdString(m_history_file.string()) : QString();
}

auto HistoryManager::add(const QString& raw_input, const QString& result, const bool fix_history_position) -> HistoryAdditionEvent
{
  HistoryAdditionEvent res{};

  {
    std::unique_lock lock{m_mutex};
    if (!m_enabled) {
      res.event = HistoryAdditionEvent::Event::SKIPPED;
      return res;
    }
  }

  auto input = raw_input.trimmed();

  if (input.isEmpty()) {
    res.event = HistoryAdditionEvent::Event::SKIPPED;
    return res;
  }

  if (fix_history_position) {
    res.event = HistoryAdditionEvent::Event::SKIPPED;
    return res;
  }

  std::unique_lock lock{m_mutex};

  auto it = std::find_if(m_entries.begin(), m_entries.end(), [&](const auto &entry) { return entry.input == input; });

  if (it == m_entries.begin()) {
    qDebug() << "Skipping identical entry";
    res.event = HistoryAdditionEvent::Event::SKIPPED;
    return res;
  } else if (it != m_entries.end()) {
    qDebug() << "Erasing double entry @" << (it - m_entries.begin());
    res.event = HistoryAdditionEvent::Event::ROW_MOVED;
    res.old_pos = std::distance(m_entries.begin(), it);;
    res.new_pos = 0;
    m_entries.erase(it);
  } else if (m_entries.size() == m_size) {
    res.event = HistoryAdditionEvent::Event::ROW_ADDED_BEGIN_TRUNCATE;
    res.old_pos = m_entries.size() - 1;
    res.new_pos = 0;
    m_entries.pop_back();
  }

  m_entries.push_front({input, result});

  m_dirty = true;

  return res;
}

auto HistoryManager::get(int index) -> QString
{
  std::unique_lock lock{m_mutex};

  if (index >= m_entries.size() || index < 0) {
    return {};
  }

  auto& entry{m_entries[index]};

  return entry.input;
}

auto HistoryManager::search(QString query) const -> QQueue<HistoryManager::HistoryEntry>
{
  query = query.trimmed();

  if (query.isEmpty()) {
    return m_entries;
  }

  QQueue<HistoryEntry> result;

  for (const auto &entry : m_entries)
  {
      if (entry.input.contains(query, Qt::CaseInsensitive) ||
          entry.result.contains(query, Qt::CaseInsensitive))
      {
          result.push_back(entry);
      }
  }

  return result;
}

const QQueue<HistoryManager::HistoryEntry> &
HistoryManager::entries() const
{
    return m_entries;
}

auto HistoryManager::load() -> void
{
  auto file{openHistoryFile()};

  if (!file) {
    return;
  }

  QJsonParseError error;
  const auto doc{QJsonDocument::fromJson(file->readAll(), &error)};

  if (error.error != QJsonParseError::NoError) {
    qDebug() << "Error parsing JSON History file:" << error.errorString();
    return;
  }

  if (!doc.isObject()) {
    qDebug() << "Error getting object from JSON History file!";
    return;
  }

  const auto root_object = doc.object();

  if (auto version{root_object.value(QString::fromUtf8(VERSION_FIELD_ID)).toInt(1)}; version != HISTORY_FILE_VERSION) {
    qDebug() << "Invalid version in JSON History file:" << version;
    return;
  }

  const auto entries = root_object.value(QString::fromUtf8(ENTRIES_FIELD_ID)).toArray();

  m_entries.reserve(entries.size());

  for (const auto& entry : entries) {
    const auto obj = entry.toObject();

    HistoryEntry history_entry;
    history_entry.input = obj.value(QString::fromUtf8(INPUT_FIELD_ID)).toString();
    history_entry.result = obj.value(QString::fromUtf8(RESULT_FIELD_ID)).toString();

    // no need to check for duplicate entries here
    // they are already prevented from enterting in the add() function

    if (!history_entry.input.isEmpty()) {
      m_entries.push_back(std::move(history_entry));
    }
  }

  qDebug() << "Loaded" << m_entries.size() << "entries from history file";

  m_dirty = false;
}

auto HistoryManager::save() -> void
{
  std::unique_lock lock{m_mutex};

  if (!m_dirty) {
    return;
  }

  auto file{openHistoryFileForWrite()};

  if (!file) {
    return;
  }

  QJsonArray entries;

  for (const auto& entry : m_entries) {
    entries.append(entry.to_json());
  }

  QJsonObject root;

  root[QString::fromUtf8(VERSION_FIELD_ID)] = 1;
  root[QString::fromUtf8(ENTRIES_FIELD_ID)] = entries;

  file->write(QJsonDocument(root).toJson(QJsonDocument::Indented));

  if (file->commit()) {
    m_dirty = false;
  } else {
    qDebug() << "Error saving history file";
  }
}

auto HistoryManager::initHistoryFile() -> void
{
  fs::path file_path{};

  if (auto home{getenv("XDG_DATA_HOME")}; home != nullptr) {
    file_path = fs::path(home);
  } else {
    file_path = fs::path(getpwuid(getuid())->pw_dir) / LOCAL_SHARE;
  }

  file_path /= QALCULATE_FOLDER;

  try {
    if (!fs::exists(file_path)) {
      fs::create_directory(file_path);
    }
  } catch (const std::bad_alloc& ex)  {
    qDebug() << "Error allocating resources:" << ex.what();
    return;
  } catch (const fs::filesystem_error& ex ) {
    qDebug() << "Error creating history folder:" << ex.what();
    return;
  }

  m_history_file = file_path / HISTORY_FILE;
  m_enabled = true;
}

auto HistoryManager::openHistoryFile() -> std::unique_ptr<QFile>
{
  auto file{std::make_unique<QFile>(m_history_file)};

  if (file->open(QIODevice::ReadOnly)) {
    return file;
  }

  return {};
}

auto HistoryManager::openHistoryFileForWrite() -> std::unique_ptr<QSaveFile>
{
  auto file{std::make_unique<QSaveFile>(m_history_file)};

  if (file->open(QIODevice::WriteOnly)) {
    return file;
  }

  return {};
}

auto HistoryManager::worker() -> void
{
  std::unique_lock lock{m_mutex};

  while (!m_cancel) {
    m_cond.wait_for(lock, std::chrono::seconds(30), [&]() { return m_cancel == true; });
    if (m_enabled) {
      lock.unlock();
      save();
      lock.lock();
    }
  }
}
