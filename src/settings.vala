using GLib;

public class Settings : Object {
    private string config_dir;
    private string config_file;
    private KeyFile keyfile;
    
    private string _download_folder;
    private string _ytdlp_path;
    private string _ffmpeg_path;
    
    public string download_folder {
        get { return _download_folder; }
        set {
            _download_folder = value;
            save();
        }
    }
    
    public string ytdlp_path {
        get { return _ytdlp_path; }
        set {
            _ytdlp_path = value;
            save();
        }
    }
    
    public string ffmpeg_path {
        get { return _ffmpeg_path; }
        set {
            _ffmpeg_path = value;
            save();
        }
    }
    
    public Settings() {
        string home = Environment.get_home_dir();
        config_dir = Path.build_filename(home, ".config", "smotrim-downloader");
        config_file = Path.build_filename(config_dir, "settings.ini");
        
        keyfile = new KeyFile();
        
        DirUtils.create_with_parents(config_dir, 0755);
        
        load();
        
        // Если пути не заданы, ищем в системе
        if (_ytdlp_path == "") {
            _ytdlp_path = find_in_path("yt-dlp");
            if (_ytdlp_path == "") _ytdlp_path = "yt-dlp";
        }
        if (_ffmpeg_path == "") {
            _ffmpeg_path = find_in_path("ffmpeg");
            if (_ffmpeg_path == "") _ffmpeg_path = "ffmpeg";
        }
        if (_download_folder == "") {
            _download_folder = get_default_download_folder();
        }
    }
    
    private string find_in_path(string program) {
        string path_env = Environment.get_variable("PATH");
        if (path_env == null) return "";
        
        string[] paths = path_env.split(":");
        foreach (string p in paths) {
            string full_path = Path.build_filename(p, program);
            if (FileUtils.test(full_path, FileTest.EXISTS | FileTest.IS_EXECUTABLE)) {
                return full_path;
            }
        }
        return "";
    }
    
    private void load() {
        try {
            keyfile.load_from_file(config_file, KeyFileFlags.NONE);
            
            if (keyfile.has_key("General", "download_folder")) {
                _download_folder = keyfile.get_string("General", "download_folder");
            } else {
                _download_folder = "";
            }
            
            if (keyfile.has_key("Paths", "ytdlp")) {
                _ytdlp_path = keyfile.get_string("Paths", "ytdlp");
            } else {
                _ytdlp_path = "";
            }
            
            if (keyfile.has_key("Paths", "ffmpeg")) {
                _ffmpeg_path = keyfile.get_string("Paths", "ffmpeg");
            } else {
                _ffmpeg_path = "";
            }
            
        } catch (FileError e) {
            // Файл не существует, используем значения по умолчанию
            _download_folder = "";
            _ytdlp_path = "";
            _ffmpeg_path = "";
        } catch (KeyFileError e) {
            _download_folder = "";
            _ytdlp_path = "";
            _ffmpeg_path = "";
        }
    }
    
    private void save() {
        try {
            keyfile.set_string("General", "download_folder", _download_folder);
            keyfile.set_string("Paths", "ytdlp", _ytdlp_path);
            keyfile.set_string("Paths", "ffmpeg", _ffmpeg_path);
            
            string data = keyfile.to_data();
            FileUtils.set_contents(config_file, data);
        } catch (Error e) {
            stderr.printf("Error saving settings: %s\n", e.message);
        }
    }
    
    private string get_default_download_folder() {
        string home = Environment.get_home_dir();
        return Path.build_filename(home, "Видео", "Smotrim");
    }
    
    public void ensure_download_folder_exists() {
        DirUtils.create_with_parents(_download_folder, 0755);
    }
    
    public bool check_ytdlp() {
        if (_ytdlp_path == "") return false;
        try {
            string[] argv = { _ytdlp_path, "--version", null };
            Process.spawn_sync(null, argv, null, SpawnFlags.SEARCH_PATH, null, null, null, null);
            return true;
        } catch (SpawnError e) {
            return false;
        }
    }
    
    public bool check_ffmpeg() {
        if (_ffmpeg_path == "") return false;
        try {
            string[] argv = { _ffmpeg_path, "-version", null };
            Process.spawn_sync(null, argv, null, SpawnFlags.SEARCH_PATH, null, null, null, null);
            return true;
        } catch (SpawnError e) {
            return false;
        }
    }
}