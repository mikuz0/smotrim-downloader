using Gtk;
using GLib;

public class DownloadRow : Box {
    private string url;
    private string title;
    private string _status;
    private int _queue_position;
    private string file_size;
    
    private Label url_label;
    private Label status_label;
    private Label detail_label;
    private Label queue_label;
    private Button cancel_btn;
    
    private int child_pid;
    private uint child_watch_id;
    private bool is_cancelled;
    private bool is_finished;
    
    private string stream_url;
    
    public signal void download_started(DownloadRow row);
    public signal void download_finished(DownloadRow row, bool success, string message);
    
    public string status {
        get { return _status; }
        set {
            _status = value;
            update_display();
        }
    }
    
    public int queue_position {
        get { return _queue_position; }
        set {
            _queue_position = value;
            update_display();
        }
    }
    
    public DownloadRow(string url, string download_folder) {
        Object(orientation: Orientation.HORIZONTAL, spacing: 6);
        this.url = url;
        this.download_folder = download_folder;
        this._status = "pending";
        this._queue_position = 0;
        this.file_size = "";
        this.title = "";
        this.stream_url = "";
        this.is_cancelled = false;
        this.is_finished = false;
        
        margin_top = 3;
        margin_bottom = 3;
        margin_start = 6;
        margin_end = 6;
        set_size_request(-1, 60);
        get_style_context().add_class("download-row");
        
        var info_box = new Box(Orientation.VERTICAL, 2);
        info_box.hexpand = true;
        
        var header_box = new Box(Orientation.HORIZONTAL, 6);
        header_box.hexpand = true;
        
        url_label = new Label(url);
        url_label.xalign = 0;
        url_label.ellipsize = Pango.EllipsizeMode.END;
        url_label.hexpand = true;
        header_box.pack_start(url_label, true, true, 0);
        
        queue_label = new Label("");
        queue_label.xalign = 1;
        queue_label.get_style_context().add_class("queue-label");
        header_box.pack_start(queue_label, false, false, 0);
        
        info_box.pack_start(header_box, false, false, 0);
        
        status_label = new Label("В очереди...");
        status_label.xalign = 0;
        status_label.get_style_context().add_class("status-label");
        info_box.pack_start(status_label, false, false, 0);
        
        detail_label = new Label("");
        detail_label.xalign = 0;
        detail_label.get_style_context().add_class("detail-label");
        info_box.pack_start(detail_label, false, false, 0);
        
        pack_start(info_box, true, true, 0);
        
        var button_box = new Box(Orientation.HORIZONTAL, 3);
        button_box.halign = Align.END;
        
        cancel_btn = new Button.with_label("✖");
        cancel_btn.tooltip_text = "Отменить";
        cancel_btn.sensitive = false;
        cancel_btn.clicked.connect(on_cancel);
        button_box.pack_start(cancel_btn, false, false, 0);
        
        pack_start(button_box, false, false, 0);
    }
    
    private void update_display() {
        if (queue_position > 0 && status == "pending") {
            queue_label.label = @"№$queue_position";
        } else {
            queue_label.label = "";
        }
        
        if (status == "downloading") {
            status_label.label = "⏬ Загрузка...";
            if (title != "") {
                detail_label.label = title;
            } else if (file_size != "") {
                detail_label.label = @"Размер: $file_size";
            } else {
                detail_label.label = "";
            }
            cancel_btn.sensitive = true;
            
        } else if (status == "processing") {
            status_label.label = "⏳ Получение информации...";
            detail_label.label = "";
            cancel_btn.sensitive = true;
            
        } else if (status == "finished") {
            status_label.label = @"✓ Завершено: $(get_filename())";
            detail_label.label = "";
            cancel_btn.sensitive = false;
            
        } else if (status == "error") {
            status_label.label = "✗ Ошибка загрузки";
            detail_label.label = "";
            cancel_btn.sensitive = false;
            
        } else if (status == "cancelled") {
            status_label.label = "⊗ Отменено";
            detail_label.label = "";
            cancel_btn.sensitive = false;
            
        } else {
            status_label.label = "⏸ В очереди...";
            detail_label.label = "";
            cancel_btn.sensitive = false;
        }
    }
    
    public void start_download() {
        if (is_finished) return;
        
        status = "processing";
        download_started(this);
        get_video_info();
    }
    
    private string download_folder;
    
    private void get_video_info() {
        string[] argv = {
            "yt-dlp",
            "--print", "%(title)s",
            "--print", "%(filesize_approx)s",
            "-g",
            "-f", "best",
            url,
            null
        };
        
        try {
            int stdout_fd;
            int child_pid;
            
            Process.spawn_async_with_pipes(null,
                                           argv,
                                           null,
                                           SpawnFlags.SEARCH_PATH | SpawnFlags.DO_NOT_REAP_CHILD,
                                           null,
                                           out child_pid,
                                           null,
                                           out stdout_fd,
                                           null);
            
            this.child_pid = child_pid;
            
            var channel = new IOChannel.unix_new(stdout_fd);
            try {
                channel.set_encoding("UTF-8");
            } catch (IOChannelError e) {}
            
            string output = "";
            string line;
            size_t term_pos;
            
            while (channel.read_line(out line, out term_pos, null) == IOStatus.NORMAL) {
                if (line != null) {
                    output += line;
                }
            }
            
            Posix.close(stdout_fd);
            
            // Парсим вывод
            string[] lines = output.split("\n");
            foreach (string l in lines) {
                string ln = l.strip();
                if (ln.has_prefix("http")) {
                    stream_url = ln;
                } else if (title == "" && !ln.has_prefix("http") && ln != "") {
                    title = ln;
                    // Очищаем название
                    title = title.replace("/", "_");
                    title = title.replace("\\", "_");
                    title = title.replace(":", "_");
                    title = title.replace("*", "_");
                    title = title.replace("?", "_");
                    title = title.replace("\"", "_");
                    title = title.replace("<", "_");
                    title = title.replace(">", "_");
                    title = title.replace("|", "_");
                } else if (file_size == "" && ln != "") {
                    int64 size = int64.parse(ln);
                    if (size > 0) {
                        file_size = format_size(size);
                    }
                }
            }
            
            int status;
            Posix.waitpid(child_pid, out status, 0);
            
            if (stream_url != "") {
                start_ffmpeg_download();
            } else {
                this.status = "error";
                download_finished(this, false, "Не удалось получить ссылку");
            }
            
        } catch (SpawnError e) {
            status = "error";
            download_finished(this, false, @"Ошибка: $(e.message)");
        }
    }
    
    private string format_size(int64 bytes) {
        if (bytes < 1024) return @"$bytes B";
        if (bytes < 1024 * 1024) return @"$(bytes / 1024) KB";
        if (bytes < 1024 * 1024 * 1024) return @"$(bytes / (1024 * 1024)) MB";
        return @"$(bytes / (1024 * 1024 * 1024)) GB";
    }
    
    private void start_ffmpeg_download() {
        string download_dir = download_folder;
        DirUtils.create_with_parents(download_dir, 0755);
        
        string safe_title = title != "" ? title : "video";
        string output_file = Path.build_filename(download_dir, safe_title + ".mp4");
        
        string[] argv = {
            "ffmpeg",
            "-i", stream_url,
            "-c", "copy",
            "-y",
            output_file,
            null
        };
        
        try {
            int child_pid;
            
            // Запускаем ffmpeg БЕЗ чтения вывода (stdout и stderr = null)
            Process.spawn_async_with_pipes(null,
                                           argv,
                                           null,
                                           SpawnFlags.SEARCH_PATH | SpawnFlags.DO_NOT_REAP_CHILD,
                                           null,
                                           out child_pid,
                                           null,   // stdin
                                           null,   // stdout — не читаем!
                                           null);  // stderr — не читаем!
            
            this.child_pid = child_pid;
            status = "downloading";
            
            // Просто ждём завершения
            this.child_watch_id = ChildWatch.add((Pid)child_pid, on_ffmpeg_exit);
            
        } catch (SpawnError e) {
            status = "error";
            download_finished(this, false, @"Ошибка: $(e.message)");
        }
    }
    
    private void on_ffmpeg_exit(Pid pid, int status) {
        Idle.add(() => {
            if (is_cancelled) return false;
            
            if (status == 0) {
                this.status = "finished";
                download_finished(this, true, @"Завершено: $(get_filename())");
            } else {
                this.status = "error";
                download_finished(this, false, "Ошибка загрузки");
            }
            
            cleanup();
            return false;
        });
        
        if (child_watch_id > 0) {
            Source.remove(child_watch_id);
            child_watch_id = 0;
        }
    }
    
    private void cleanup() {
        is_finished = true;
        child_pid = 0;
    }
    
    public void on_cancel() {
        if (is_cancelled || is_finished) return;
        is_cancelled = true;
        
        if (child_pid > 0) {
            Posix.kill(child_pid, Posix.SIGTERM);
        }
        
        status = "cancelled";
        download_finished(this, false, "Загрузка отменена");
        cleanup();
    }
    
    public bool can_remove() {
        return status == "finished" || status == "error" || status == "cancelled";
    }
    
    public string get_filename() {
        if (title != "") return title + ".mp4";
        return "video.mp4";
    }
}