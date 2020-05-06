using Gtk;

public class Podsblitz.Player : Grid {

	public Gtk.Image image;
	public Gtk.Button play_button;
	public Gtk.Button fwd_button;
	public Gtk.Button bck_button;
	public Gtk.Button skip_button;
	public Gtk.ProgressBar progress_bar;
	public Gtk.Label progress_label;


	public Player () {

		image = new Image.from_resource("/de/hannenz/podsblitz/img/noimage.png");
		play_button = new Button.from_icon_name("media-playback-start");
		fwd_button = new Button.from_icon_name("media-seek-forward");
		bck_button = new Button.from_icon_name("media-seek-backward");
		skip_button = new Button.from_icon_name("media-skip-forward");
		progress_bar = new ProgressBar();
		progress_label = new Label("00:00 / 00:00");

		int y = 0;

		attach(image, 0, y, 8, 8);
		y = 8;
		attach(progress_bar, 2, y++, 6, 1);
		attach(progress_label, 3, y++, 5, 1);
		var button_box = new ButtonBox(Orientation.HORIZONTAL);
		button_box.add(bck_button);
		button_box.add(play_button);
		button_box.add(fwd_button);
		attach(button_box, 3, y++, 5, 1);
	}

