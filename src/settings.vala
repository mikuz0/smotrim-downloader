using GLib;

public class AppSettings : Object {
    private string config_dir;
    private string config_file;
    private KeyFile keyfile;
    
    private string _download_folder;
    
    public string download_folder {
        get { return _download_folder; }
        set {
            _download_folder = value;
            save();
        }
    }
    
    public AppSettings() {
        string home = Environment.get_home_dir();
        config_dir = Path.build_filename(home, ".config", "smotrim-downloader");
        config_file = Path.build_filename(config_dir, "settings.ini");
        
        keyfile = new KeyFile();
        
        DirUtils.create_with_parents(config_dir, 0755);
        
        load();
    }
    
    private void load() {
        try {
            keyfile.load_from_file(config_file, KeyFileFlags.NONE);
            
            if (keyfile.has_key("General", "download_folder")) {
                _download_folder = keyfile.get_string("General", "download_folder");
            } else {
                _download_folder = get_default_download_folder();
            }
        } catch (FileError e) {
            _download_folder = get_default_download_folder();
        } catch (KeyFileError e) {
            _download_folder = get_default_download_folder();
        }
    }
    
    private void save() {
        try {
            keyfile.set_string("General", "download_folder", _download_folder);
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
}