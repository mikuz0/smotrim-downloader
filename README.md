# Smotrim Downloader

Простой и надёжный графический загрузчик видео с сайта smotrim.ru.

![Версия](https://img.shields.io/badge/version-0.1.0-blue.svg)
![Лицензия](https://img.shields.io/badge/license-GPLv3-green.svg)
![GTK3](https://img.shields.io/badge/GTK-3.24-orange.svg)

## Возможности

- ✅ Загрузка видео с smotrim.ru в формате MP4
- ✅ Очередь загрузок (последовательная, по одному файлу)
- ✅ Отмена текущей загрузки
- ✅ Сохранение папки загрузок в настройках
- ✅ Отображение размера файла
- ✅ Очистка завершённых загрузок
- ✅ Работа в фоновом режиме без блокировки интерфейса

## Требования

### Системные зависимости
- **Ubuntu 25.10** или другой дистрибутив с GTK3
- **yt-dlp** — для получения ссылок на видео
- **ffmpeg** — для загрузки и конвертации

### Пакеты для сборки
```bash
sudo apt install build-essential libgtk-3-dev meson ninja-build valac yt-dlp ffmpeg

Установка
Из исходников
bash

# Клонируем репозиторий
git clone https://github.com/username/smotrim-downloader.git
cd smotrim-downloader

# Сборка
meson setup builddir
cd builddir
meson compile

# Запуск без установки
./src/smotrim-downloader

# Установка в систему
sudo meson install

Запуск после установки
bash

smotrim-downloader

Использование

    Добавление URL

        Вставьте ссылку на видео в поле ввода

        Нажмите "Добавить" или Enter

    Начало загрузки

        После добавления видео нажмите "▶ Начать загрузку"

        Загрузка идёт последовательно (по одному файлу)

    Управление загрузкой

        Отмена — нажмите ✖ на строке загрузки

        Очистка — удаляет завершённые, ошибочные и отменённые загрузки

    Выбор папки

        Нажмите "Папка" и выберите директорию для сохранения

        Папка сохраняется в настройках и используется при следующем запуске

Структура проекта
text

smotrim-downloader/
├── meson.build              # Главный файл сборки
├── src/
│   ├── meson.build          # Сборка исходников
│   ├── main.vala            # Точка входа
│   ├── application.vala     # Класс приложения
│   ├── main_window.vala     # Главное окно
│   ├── download_row.vala    # Строка загрузки
│   ├── download_manager.vala# Менеджер очереди
│   └── settings.vala        # Настройки (сохранение папки)
└── data/
    ├── meson.build          # Установка .desktop файла
    └── smotrim-downloader.desktop.in

Как это работает

    Получение информации

        yt-dlp извлекает название видео и размер

        Получает прямую ссылку на HLS-поток

    Загрузка

        ffmpeg скачивает поток в MP4 без перекодирования

        Процесс запускается без чтения вывода (нет буферизации)

    Очередь

        Загрузки выполняются последовательно

        После завершения одной автоматически начинается следующая

Настройки

Файл конфигурации: ~/.config/smotrim-downloader/settings.ini
ini

[General]
download_folder=/home/username/Видео/Smotrim

Удаление
bash

sudo apt remove smotrim-downloader
# или если устанавливали вручную:
sudo rm /usr/bin/smotrim-downloader
rm -rf ~/.config/smotrim-downloader

Лицензия

GNU General Public License v3.0
Авторы

    Ваше Имя email@example.com

Благодарности

    yt-dlp — загрузка видео

    FFmpeg — обработка потоков

    GTK — графический интерфейс
    
