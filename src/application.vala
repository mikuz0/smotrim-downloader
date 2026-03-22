using Gtk;

public class SmotrimDownloader : Gtk.Application {
    private MainWindow main_window;
    
    public SmotrimDownloader() {
        Object(application_id: "ru.smotrim.downloader");
    }
    
    public override void activate() {
        if (main_window == null) {
            main_window = new MainWindow(this);
            add_window(main_window);
        }
        main_window.present();
    }
}