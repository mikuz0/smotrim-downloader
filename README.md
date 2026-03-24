# Smotrim Downloader

Простой и надёжный графический загрузчик видео с сайта smotrim.ru.

![Версия](https://img.shields.io/badge/version-0.1.0-blue.svg)
![Лицензия](https://img.shields.io/badge/license-GPLv3-green.svg)
![GTK3](https://img.shields.io/badge/GTK-3.24-orange.svg)
![Vala](https://img.shields.io/badge/Vala-0.56-purple.svg)

## Возможности

- ✅ Загрузка видео с smotrim.ru в формате MP4
- ✅ Очередь загрузок (последовательная, по одному файлу)
- ✅ Отмена текущей загрузки
- ✅ Сохранение папки загрузок в настройках
- ✅ Выбор путей к yt-dlp и ffmpeg
- ✅ Отображение размера файла
- ✅ Очистка завершённых загрузок
- ✅ Интеграция с KDE/GNOME (меню приложений)
- ✅ Работа в фоновом режиме без блокировки интерфейса

## Требования

### Системные зависимости
- **Ubuntu 25.10** или другой дистрибутив с GTK3
- **yt-dlp** (>= 2025.09.23) — для получения ссылок на видео
- **ffmpeg** (>= 7.0) — для загрузки и конвертации

### Пакеты для сборки из исходников
```bash
sudo apt install build-essential libgtk-3-dev meson ninja-build valac yt-dlp ffmpeg

Установка
Из готового DEB-пакета
bash

# Установка
sudo dpkg -i smotrim-downloader_0.1.0-1_amd64.deb
sudo apt-get install -f  # исправление зависимостей

# Запуск
smotrim-downloader

Из исходников
bash

# Клонирование репозитория
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

Использование
Основные действия

    Добавление URL

        Вставьте ссылку на видео в поле ввода

        Нажмите "Добавить" или Enter

    Начало загрузки

        После добавления видео нажмите "▶ Начать загрузку"

        Загрузка идёт последовательно (по одному файлу)

    Управление загрузкой

        Отмена — нажмите ✖ на строке загрузки

        Очистка — удаляет завершённые, ошибочные и отменённые загрузки

    Настройки

        Нажмите "⚙ Настройки"

        Выберите папку для сохранения

        Укажите пути к yt-dlp и ffmpeg (если они не в PATH)

Скриншоты

(здесь будут скриншоты приложения)
Структура проекта
text

smotrim-downloader/
├── meson.build              # Главный файл сборки
├── debian/                  # Файлы для сборки DEB-пакета
│   ├── changelog
│   ├── control
│   ├── copyright
│   ├── rules
│   └── source/
├── src/
│   ├── meson.build          # Сборка исходников
│   ├── main.vala            # Точка входа
│   ├── application.vala     # Класс приложения
│   ├── main_window.vala     # Главное окно
│   ├── download_row.vala    # Строка загрузки
│   ├── download_manager.vala# Менеджер очереди
│   ├── settings.vala        # Настройки (сохранение)
│   └── settings_dialog.vala # Диалог настроек
└── data/
    ├── smotrim-downloader.desktop  # Интеграция в меню
    └── icons/
        └── smotrim-downloader.svg  # Иконка приложения

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

        Сохраняются: папка загрузок, пути к yt-dlp и ffmpeg

Настройки

Файл конфигурации: ~/.config/smotrim-downloader/settings.ini
ini

[General]
download_folder=/home/username/Видео/Smotrim

[Paths]
ytdlp=/usr/bin/yt-dlp
ffmpeg=/usr/bin/ffmpeg

Удаление
bash

# Удаление пакета
sudo dpkg -r smotrim-downloader

# Удаление настроек (опционально)
rm -rf ~/.config/smotrim-downloader

Сборка DEB-пакета
bash

# Установка инструментов
sudo apt install devscripts debhelper build-essential

# Сборка
cd smotrim-downloader
debuild -us -uc -b

# Результат
# ../smotrim-downloader_0.1.0-1_amd64.deb

Лицензия

GNU General Public License v3.0
Авторы

    Ваше Имя email@example.com

Благодарности

    yt-dlp — загрузка видео

    FFmpeg — обработка потоков

    GTK — графический интерфейс

    Vala — язык программирования
