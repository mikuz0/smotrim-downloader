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
    private uint timeout_id;
    private bool is_cancelled;
    private bool is_finished;
    private bool process_completed;
    
    private string stream_url;
    private string ytdlp_path;
    private string ffmpeg_path;
    private string download_folder;
    
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
    
    public DownloadRow(string url, string download_folder, string ytdlp_path, string ffmpeg_path) {
        Object(orientation: Orientation.HORIZONTAL, spacing: 6);
        this.url = url;
        this.download_folder = download_folder;
        this.ytdlp_path = ytdlp_path;
        this.ffmpeg_path = ffmpeg_path;
        this._status = "pending";
        this._queue_position = 0;
        this.file_size = "";
        this.title = "";
        this.stream_url = "";
        this.is_cancelled = false;
        this.is_finished = false;
        this.process_completed = false;
        this.child_pid = 0;
        this.child_watch_id = 0;
        this.timeout_id = 0;
        
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
    
    private void get_video_info() {
        string[] argv = {
            ytdlp_path,
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
            process_completed = false;
            
            // Таймаут 30 секунд на получение информации
            timeout_id = Timeout.add_seconds(30, () => {
                if (!process_completed && child_pid > 0) {
                    print("Timeout: yt-dlp is taking too long, killing process %d\n", child_pid);
                    Posix.kill(child_pid, Posix.SIGTERM);
                    Timeout.add_seconds(2, () => {
                        if (!process_completed && child_pid > 0) {
                            Posix.kill(child_pid, Posix.SIGKILL);
                        }
                        return false;
                    });
                }
                timeout_id = 0;
                return false;
            });
            
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
            
            // Ждём завершения процесса с таймаутом
            int status;
            int64 start_time = get_monotonic_time();
            int64 timeout_us = 30 * 1000000;
            
            while (true) {
                int ret = Posix.waitpid(child_pid, out status, Posix.WNOHANG);
                if (ret == child_pid) {
                    process_completed = true;
                    if (timeout_id > 0) {
                        Source.remove(timeout_id);
                        timeout_id = 0;
                    }
                    break;
                }
                if (ret == -1) {
                    process_completed = true;
                    break;
                }
                int64 elapsed = get_monotonic_time() - start_time;
                if (elapsed >= timeout_us) {
                    print("Timeout: yt-dlp process %d did not finish\n", child_pid);
                    Posix.kill(child_pid, Posix.SIGTERM);
                    Thread.usleep(2000000);
                    Posix.kill(child_pid, Posix.SIGKILL);
                    Posix.waitpid(child_pid, out status, 0);
                    process_completed = true;
                    break;
                }
                Thread.usleep(100000);
            }
            
            if (process_completed && status == 0 && stream_url == "") {
                string[] lines = output.split("\n");
                foreach (string l in lines) {
                    string ln = l.strip();
                    if (ln.has_prefix("http")) {
                        stream_url = ln;
                    } else if (title == "" && !ln.has_prefix("http") && ln != "") {
                        title = ln;
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
            }
            
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
        DirUtils.create_with_parents(download_folder, 0755);
        
        string safe_title = title != "" ? title : "video";
        string output_file = Path.build_filename(download_folder, safe_title + ".mp4");
        
        string[] argv = {
            ffmpeg_path,
            "-i", stream_url,
            "-c", "copy",
            "-y",
            output_file,
            null
        };
        
        try {
            int child_pid;
            
            Process.spawn_async_with_pipes(null,
                                           argv,
                                           null,
                                           SpawnFlags.SEARCH_PATH | SpawnFlags.DO_NOT_REAP_CHILD,
                                           null,
                                           out child_pid,
                                           null,
                                           null,
                                           null);
            
            this.child_pid = child_pid;
            status = "downloading";
            process_completed = false;
            
            this.child_watch_id = ChildWatch.add((Pid)child_pid, on_ffmpeg_exit);
            
        } catch (SpawnError e) {
            status = "error";
            download_finished(this, false, @"Ошибка: $(e.message)");
        }
    }
    
    private void on_ffmpeg_exit(Pid pid, int status) {
        process_completed = true;
        
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
        if (timeout_id > 0) {
            Source.remove(timeout_id);
            timeout_id = 0;
        }
        child_pid = 0;
    }
    
    public void on_cancel() {
        if (is_cancelled || is_finished) return;
        is_cancelled = true;
        
        if (child_pid > 0) {
            Posix.kill(child_pid, Posix.SIGTERM);
            
            Timeout.add_seconds(2, () => {
                if (!process_completed && child_pid > 0) {
                    Posix.kill(child_pid, Posix.SIGKILL);
                }
                return false;
            });
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