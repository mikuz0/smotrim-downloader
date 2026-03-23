using Gtk;

public class SettingsDialog : Dialog {
    private Entry download_folder_entry;
    private Entry ytdlp_entry;
    private Entry ffmpeg_entry;
    private Settings settings;
    private DownloadManager download_manager;
    
    public SettingsDialog(Window parent, Settings settings, DownloadManager download_manager) {
        Object(transient_for: parent, modal: true, title: "Настройки");
        this.settings = settings;
        this.download_manager = download_manager;
        
        set_default_size(500, 250);
        set_border_width(12);
        
        var content = get_content_area();
        content.spacing = 12;
        
        // Папка загрузок
        var folder_box = create_file_chooser_row("Папка загрузок:", settings.download_folder, true);
        download_folder_entry = (Entry)folder_box.get_children().nth_data(1);
        content.pack_start(folder_box, false, false, 0);
        
        // yt-dlp
        var ytdlp_box = create_file_chooser_row("yt-dlp:", settings.ytdlp_path, false);
        ytdlp_entry = (Entry)ytdlp_box.get_children().nth_data(1);
        content.pack_start(ytdlp_box, false, false, 0);
        
        // ffmpeg
        var ffmpeg_box = create_file_chooser_row("ffmpeg:", settings.ffmpeg_path, false);
        ffmpeg_entry = (Entry)ffmpeg_box.get_children().nth_data(1);
        content.pack_start(ffmpeg_box, false, false, 0);
        
        // Кнопки
        var button_box = new Box(Orientation.HORIZONTAL, 6);
        button_box.halign = Align.END;
        
        var cancel_btn = new Button.with_label("Отмена");
        cancel_btn.clicked.connect(() => { destroy(); });
        button_box.pack_start(cancel_btn, false, false, 0);
        
        var save_btn = new Button.with_label("Сохранить");
        save_btn.get_style_context().add_class("suggested-action");
        save_btn.clicked.connect(on_save);
        button_box.pack_start(save_btn, false, false, 0);
        
        content.pack_start(button_box, false, false, 0);
        
        show_all();
    }
    
    private Box create_file_chooser_row(string label_text, string current_path, bool is_folder) {
        var hbox = new Box(Orientation.HORIZONTAL, 6);
        hbox.hexpand = true;
        
        var label = new Label(label_text);
        label.width_request = 100;
        label.xalign = 0;
        hbox.pack_start(label, false, false, 0);
        
        var entry = new Entry();
        entry.text = current_path;
        entry.hexpand = true;
        hbox.pack_start(entry, true, true, 0);
        
        var browse_btn = new Button.with_label("Обзор...");
        browse_btn.clicked.connect(() => {
            var dialog = new FileChooserDialog("Выберите " + (is_folder ? "папку" : "файл"),
                                                this,
                                                is_folder ? FileChooserAction.SELECT_FOLDER : FileChooserAction.OPEN,
                                                "_Отмена", ResponseType.CANCEL,
                                                "_OK", ResponseType.ACCEPT);
            
            if (entry.text != "" && FileUtils.test(entry.text, FileTest.EXISTS)) {
                dialog.set_filename(entry.text);
            }
            
            if (dialog.run() == ResponseType.ACCEPT) {
                entry.text = dialog.get_filename();
            }
            
            dialog.destroy();
        });
        hbox.pack_start(browse_btn, false, false, 0);
        
        return hbox;
    }
    
    private void on_save() {
        // Сохраняем в файл настроек
        settings.download_folder = download_folder_entry.text;
        settings.ytdlp_path = ytdlp_entry.text;
        settings.ffmpeg_path = ffmpeg_entry.text;
        
        // Обновляем пути в менеджере загрузок
        download_manager.set_ytdlp_path(ytdlp_entry.text);
        download_manager.set_ffmpeg_path(ffmpeg_entry.text);
        
        // Проверяем доступность yt-dlp
        if (!settings.check_ytdlp()) {
            var msg = new MessageDialog(this, 0, MessageType.WARNING, ButtonsType.OK,
                                        "yt-dlp не найден по указанному пути:\n%s\n\nЗагрузка может не работать.", 
                                        ytdlp_entry.text);
            msg.run();
            msg.destroy();
        }
        
        // Проверяем доступность ffmpeg
        if (!settings.check_ffmpeg()) {
            var msg = new MessageDialog(this, 0, MessageType.WARNING, ButtonsType.OK,
                                        "ffmpeg не найден по указанному пути:\n%s\n\nЗагрузка может не работать.", 
                                        ffmpeg_entry.text);
            msg.run();
            msg.destroy();
        }
        
        destroy();
    }
}