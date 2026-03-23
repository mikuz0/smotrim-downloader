using GLib;

public class DownloadManager : Object {
    private List<DownloadRow> downloads;
    private List<DownloadRow> pending_queue;
    private DownloadRow active_download;
    private bool is_downloading;
    private string download_folder;
    private string ytdlp_path;
    private string ffmpeg_path;
    
    public signal void download_status_changed();
    public signal void all_completed();
    public signal void queue_updated();
    
    public DownloadManager() {
        downloads = new List<DownloadRow>();
        pending_queue = new List<DownloadRow>();
        active_download = null;
        is_downloading = false;
        download_folder = "";
        ytdlp_path = "yt-dlp";
        ffmpeg_path = "ffmpeg";
    }
    
    public void set_download_folder(string folder) {
        download_folder = folder;
        DirUtils.create_with_parents(download_folder, 0755);
    }
    
    public string get_download_folder() {
        return download_folder;
    }
    
    public void set_ytdlp_path(string path) {
        ytdlp_path = path;
    }
    
    public string get_ytdlp_path() {
        return ytdlp_path;
    }
    
    public void set_ffmpeg_path(string path) {
        ffmpeg_path = path;
    }
    
    public string get_ffmpeg_path() {
        return ffmpeg_path;
    }
    
    public void add_download(DownloadRow row) {
        downloads.append(row);
        pending_queue.append(row);
        row.download_finished.connect(on_download_finished);
        update_queue_positions();
        download_status_changed();
        queue_updated();
    }
    
    public void remove_download(DownloadRow row) {
        downloads.remove(row);
        
        if (active_download == row) {
            active_download = null;
            is_downloading = false;
        } else {
            pending_queue.remove(row);
        }
        
        update_queue_positions();
        download_status_changed();
        queue_updated();
    }
    
    public void start_all() {
        if (!is_downloading && pending_queue.length() > 0) {
            start_next();
        }
    }
    
    private void start_next() {
        if (pending_queue.length() == 0) {
            is_downloading = false;
            active_download = null;
            all_completed();
            return;
        }
        
        var row = pending_queue.first().data;
        pending_queue.remove_link(pending_queue.first());
        active_download = row;
        is_downloading = true;
        
        update_queue_positions();
        row.start_download();
        
        download_status_changed();
        queue_updated();
    }
    
    private void on_download_finished(DownloadRow row, bool success, string message) {
        if (active_download == row) {
            active_download = null;
            is_downloading = false;
            start_next();
        }
        
        download_status_changed();
        queue_updated();
    }
    
    private bool is_in_pending_queue(DownloadRow row) {
        foreach (var r in pending_queue) {
            if (r == row) return true;
        }
        return false;
    }
    
    private void update_queue_positions() {
        int pos = 1;
        
        foreach (var row in pending_queue) {
            row.queue_position = pos;
            pos++;
        }
        
        if (active_download != null) {
            active_download.queue_position = 0;
        }
        
        foreach (var row in downloads) {
            if (row != active_download && !is_in_pending_queue(row)) {
                if (row.status == "finished" || row.status == "error" || row.status == "cancelled") {
                    row.queue_position = 0;
                }
            }
        }
    }
    
    public bool has_pending() {
        return pending_queue.length() > 0;
    }
    
    public bool has_active() {
        return active_download != null;
    }
    
    public int get_pending_count() {
        return (int)pending_queue.length();
    }
    
    public int get_active_count() {
        return has_active() ? 1 : 0;
    }
    
    public int get_total_count() {
        return (int)downloads.length();
    }
    
    public DownloadRow? get_active_download() {
        return active_download;
    }
}