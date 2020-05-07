using Gtk;

public class Podsblitz.Player : Grid {

	public Gtk.Image image;
	public Gtk.Button play_button;
	public Gtk.Button fwd_button;
	public Gtk.Button bck_button;
	public Gtk.Button skip_button;
	public Gtk.Scale progress_bar;
	public Gtk.Label progress_label;
	public Gst.Player player;
	public Gst.PlayerState state;

	public signal void play();
	public signal void pause();
	public signal void seek(int seconds);
	public signal void skip();


	public Player () {

		image = new Image.from_resource("/de/hannenz/podsblitz/img/noimage.png");
		play_button = new Button.from_icon_name("media-playback-start");
		fwd_button = new Button.from_icon_name("media-seek-forward");
		bck_button = new Button.from_icon_name("media-seek-backward");
		skip_button = new Button.from_icon_name("media-skip-forward");
		progress_bar = new Scale(Orientation.HORIZONTAL, null);
		progress_label = new Label(null);
		player = new Gst.Player(null, null);

		player.set_uri("https://cdn.podigee.com/media/podcast_17255_unter_pfarrerstochtern_episode_208542_sodom_und_gomorra.m4a?v=1587646976&amp;source=feed");

		player.play();
		state = Gst.PlayerState.PLAYING;
		player.duration_changed.connect( () => {
			var adj = new Adjustment(0, 0, player.get_duration() / 1000000000, 1, 10, 10);
			progress_bar.set_adjustment(adj);
		});

		progress_bar.value_changed.connect( () => {
			player.seek((Gst.ClockTime)(progress_bar.get_value() * 1000000000));
		});

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


		play_button.clicked.connect( () => {
			debug("Play Buttton has been clicked");
			debug(state.to_string());
			switch (state) {
				case Gst.PlayerState.PLAYING:
					player.pause();
					state = Gst.PlayerState.PAUSED;
					break;
				case Gst.PlayerState.PAUSED:
				case Gst.PlayerState.STOPPED:
					player.play();
					state = Gst.PlayerState.PLAYING;
					break;
				default:
					break;
			}
		});

		bck_button.clicked.connect( () => {
			seek(-15);
		});

		fwd_button.clicked.connect( () => {
			seek(30);
		});

		player.position_updated.connect( (pos) => {

			progress_label.set_text("%s / %s".printf(
									time_to_str((int)(pos / 1000000000)), 
									time_to_str((int)(player.get_duration() / 1000000000))
									));

			progress_bar.set_value(pos / 1000000000);
		});

	}
	

	public void play(string uri) {
		player.set_uri(uri);
		player.play();
	}


	protected void seek(int seconds) {
		Gst.ClockTime curpos = player.get_position();
		Gst.ClockTime newpos = curpos + (uint64)seconds * 1000000000;
		player.seek(newpos);
		double perc = curpos / player.get_duration();
	}
}
