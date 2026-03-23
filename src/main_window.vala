using Gtk;
using GLib;

public class MainWindow : Gtk.ApplicationWindow {
    private Entry url_entry;
    private ListBox listbox;
    private Label status_label;
    private Button start_all_button;
    private DownloadManager download_manager;
    private Settings settings;
    private Label stats_label;
    
    public MainWindow(Gtk.Application app) {
        Object(application: app);
        this.title = "Smotrim Downloader";
        this.set_default_size(900, 600);
        this.window_position = WindowPosition.CENTER;
        
        settings = new Settings();
        settings.ensure_download_folder_exists();
        
        download_manager = new DownloadManager();
        download_manager.set_download_folder(settings.download_folder);
        download_manager.set_ytdlp_path(settings.ytdlp_path);
        download_manager.set_ffmpeg_path(settings.ffmpeg_path);
        download_manager.download_status_changed.connect(on_download_status_changed);
        download_manager.all_completed.connect(on_all_completed);
        download_manager.queue_updated.connect(update_stats);
        
        create_widgets();
        load_css();
        show_all();
        
        status_label.label = @"Папка: $(settings.download_folder)";
    }
    
    private void load_css() {
        var css = """
            .status-label {
                font-size: 10px;
                color: #666;
            }
            .detail-label {
                font-size: 9px;
                color: #888;
                font-family: monospace;
            }
            .queue-label {
                font-size: 10px;
                color: #ff9800;
                font-weight: bold;
                background-color: #fff3e0;
                padding: 2px 6px;
                border-radius: 10px;
            }
            .stats-label {
                font-size: 10px;
                color: #555;
            }
            .download-row {
                padding: 5px;
                border-bottom: 1px solid #ddd;
                background-color: #fafafa;
            }
            .download-row:hover {
                background-color: #f5f5f5;
            }
        """;
        
        var provider = new CssProvider();
        try {
            provider.load_from_data(css, -1);
            Gtk.StyleContext.add_provider_for_screen(
                Gdk.Screen.get_default(),
                provider,
                Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
            );
        } catch (Error e) {
            stderr.printf("CSS loading error: %s\n", e.message);
        }
    }
    
    private void create_widgets() {
        var vbox = new Box(Orientation.VERTICAL, 0);
        add(vbox);
        
        var toolbar = create_toolbar();
        vbox.pack_start(toolbar, false, false, 0);
        
        var scrolled = new ScrolledWindow(null, null);
        scrolled.set_policy(PolicyType.AUTOMATIC, PolicyType.AUTOMATIC);
        scrolled.vexpand = true;
        vbox.pack_start(scrolled, true, true, 0);
        
        listbox = new ListBox();
        listbox.selection_mode = SelectionMode.NONE;
        scrolled.add(listbox);
        
        var statusbar = create_statusbar();
        vbox.pack_start(statusbar, false, false, 0);
    }
    
    private Box create_toolbar() {
        var toolbar = new Box(Orientation.HORIZONTAL, 6);
        toolbar.margin_top = 6;
        toolbar.margin_bottom = 6;
        toolbar.margin_start = 6;
        toolbar.margin_end = 6;
        
        url_entry = new Entry();
        url_entry.placeholder_text = "Введите URL видео...";
        url_entry.hexpand = true;
        url_entry.activate.connect(on_add_clicked);
        toolbar.pack_start(url_entry, true, true, 0);
        
        var add_btn = new Button.with_label("Добавить");
        add_btn.clicked.connect(on_add_clicked);
        toolbar.pack_start(add_btn, false, false, 0);
        
        start_all_button = new Button.with_label("▶ Начать загрузку");
        start_all_button.sensitive = false;
        start_all_button.clicked.connect(on_start_all_clicked);
        toolbar.pack_start(start_all_button, false, false, 0);
        
        var clear_btn = new Button.with_label("Очистить");
        clear_btn.clicked.connect(on_clear_clicked);
        toolbar.pack_start(clear_btn, false, false, 0);
        
        var folder_btn = new Button.with_label("Папка");
        folder_btn.clicked.connect(on_folder_clicked);
        toolbar.pack_start(folder_btn, false, false, 0);
        
        var settings_btn = new Button.with_label("⚙ Настройки");
        settings_btn.clicked.connect(on_settings_clicked);
        toolbar.pack_start(settings_btn, false, false, 0);
        
        return toolbar;
    }
    
    private Box create_statusbar() {
        var statusbar = new Box(Orientation.HORIZONTAL, 6);
        statusbar.margin_top = 6;
        statusbar.margin_bottom = 6;
        statusbar.margin_start = 6;
        statusbar.margin_end = 6;
        
        status_label = new Label("Готов");
        status_label.xalign = 0;
        status_label.ellipsize = Pango.EllipsizeMode.END;
        statusbar.pack_start(status_label, true, true, 0);
        
        stats_label = new Label("");
        stats_label.xalign = 1;
        stats_label.get_style_context().add_class("stats-label");
        statusbar.pack_start(stats_label, false, false, 0);
        
        return statusbar;
    }
    
    private void update_stats() {
        int active = download_manager.get_active_count();
        int pending = download_manager.get_pending_count();
        int total = download_manager.get_total_count();
        
        if (active > 0) {
            var active_row = download_manager.get_active_download();
            string filename = active_row != null ? active_row.get_filename() : "";
            stats_label.label = @"Загружается: $filename | Очередь: $pending | Всего: $total";
        } else if (pending > 0) {
            stats_label.label = @"Ожидание: $pending | Всего: $total";
            start_all_button.sensitive = true;
        } else {
            stats_label.label = @"Всего загрузок: $total";
            start_all_button.sensitive = false;
        }
    }
    
    private void on_add_clicked() {
        string url = url_entry.text.strip();
        if (url != "") {
            var row = new DownloadRow(
                url,
                settings.download_folder,
                download_manager.get_ytdlp_path(),
                download_manager.get_ffmpeg_path()
            );
            row.download_finished.connect(on_download_finished);
            
            listbox.add(row);
            listbox.show_all();
            
            download_manager.add_download(row);
            url_entry.text = "";
            status_label.label = @"Добавлено: $url";
            
            update_stats();
            start_all_button.sensitive = true;
        }
    }
    
    private void on_start_all_clicked() {
        if (download_manager.has_pending() && !download_manager.has_active()) {
            download_manager.start_all();
            start_all_button.sensitive = false;
            status_label.label = "Загрузка запущена...";
        }
    }
    
    private void on_clear_clicked() {
        var rows = listbox.get_children();
        var to_remove = new List<weak DownloadRow>();
        
        foreach (var child in rows) {
            var row = child as DownloadRow;
            if (row != null && row.can_remove()) {
                to_remove.append(row);
            }
        }
        
        foreach (var row in to_remove) {
            listbox.remove(row);
            download_manager.remove_download(row);
        }
        
        update_stats();
        status_label.label = "Очищено";
    }
    
    private void on_folder_clicked() {
        var dialog = new FileChooserDialog("Выберите папку для загрузок",
                                            this,
                                            FileChooserAction.SELECT_FOLDER,
                                            "_Отмена", ResponseType.CANCEL,
                                            "_OK", ResponseType.ACCEPT);
        
        dialog.set_current_folder(settings.download_folder);
        
        if (dialog.run() == ResponseType.ACCEPT) {
            string folder = dialog.get_filename();
            settings.download_folder = folder;
            settings.ensure_download_folder_exists();
            download_manager.set_download_folder(folder);
            status_label.label = @"Папка загрузок: $folder";
        }
        
        dialog.destroy();
    }
    
    private void on_settings_clicked() {
        var dialog = new SettingsDialog(this, settings, download_manager);
        dialog.run();
        
        // Обновляем пути в менеджере
        download_manager.set_ytdlp_path(settings.ytdlp_path);
        download_manager.set_ffmpeg_path(settings.ffmpeg_path);
        
        status_label.label = @"Папка: $(settings.download_folder)";
    }
    
    private void on_download_finished(DownloadRow row, bool success, string message) {
        status_label.label = message;
        update_stats();
        
        if (!download_manager.has_pending() && !download_manager.has_active()) {
            start_all_button.sensitive = false;
        }
    }
    
    private void on_download_status_changed() {
        if (download_manager.has_pending() && !download_manager.has_active()) {
            start_all_button.sensitive = true;
        } else if (download_manager.has_active()) {
            start_all_button.sensitive = false;
        }
    }
    
    private void on_all_completed() {
        status_label.label = "Все загрузки завершены!";
        update_stats();
    }
}