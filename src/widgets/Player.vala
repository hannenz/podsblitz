using Gtk;

public class Podsblitz.Player : Grid {

	public Gtk.Image image;
	public Gtk.Button play_button;
	public Gtk.Button fwd_button;
	public Gtk.Button bck_button;
	public Gtk.Button skip_button;
	public Gtk.Scale progress_bar;
	public Gtk.Label progress_label;
	public Gtk.Label title_label;
	public Gst.Player player;
	public Gst.PlayerState state;
	public Gtk.Scale speed_scale;

	private Gtk.Image play_icon;
	private Gtk.Image pause_icon;

	private int current_duration;

	public double speed { get; set; default = 1.0; }
	public int speed_index = 0;
	public double[] speeds = { 1, 1.25, 1.75, 2.5 };

	public Player () {

		player = new Gst.Player(null, null);
		image = new Image.from_resource("/de/hannenz/podsblitz/img/noimage.png");

		play_icon = new Gtk.Image.from_icon_name("media-playback-start-symbolic", IconSize.LARGE_TOOLBAR);
		pause_icon = new Gtk.Image.from_icon_name("media-playback-pause-symbolic", IconSize.LARGE_TOOLBAR);

		play_button = new Button();
		play_button.set_image(play_icon);
		play_button.set_relief(ReliefStyle.NONE);

		fwd_button = new Button.from_icon_name("media-seek-forward-symbolic");
		bck_button = new Button.from_icon_name("media-seek-backward-symbolic");
		skip_button = new Button.from_icon_name("media-skip-forward-symbolic");
		fwd_button.set_relief(ReliefStyle.NONE);
		bck_button.set_relief(ReliefStyle.NONE);
		skip_button.set_relief(ReliefStyle.NONE);

		title_label = new Label(null);

		progress_bar = new Scale(Orientation.HORIZONTAL, null);
		progress_bar.name = "progress-bar";
		progress_bar.set_draw_value(false);
		progress_label = new Label(null);
		progress_bar.button_press_event.connect( (event) => {
			var perc = (double)event.x / (double)progress_bar.get_allocated_width();
			player.seek((Gst.ClockTime)(player.get_duration() * perc));
			return true;
		});

		var speed_button = new Gtk.Button();
		speed_button.set_label("%g×".printf(speed));
		this.notify["speed"].connect( (sender, property) => {
			speed_button.set_label("%g×".printf(speed));
			player.set_rate(speed);
		});
		speed_button.clicked.connect( ()  => {
			if (++speed_index >= speeds.length) {
				speed_index = 0;
			}
			speed = speeds[speed_index];
		});

		// player.set_uri("https://cdn.podigee.com/media/podcast_17255_unter_pfarrerstochtern_episode_208542_sodom_und_gomorra.m4a?v=1587646976&amp;source=feed");
		// player.play();
		// play_button.set_image(pause_icon);


		state = Gst.PlayerState.PLAYING;
		player.duration_changed.connect( () => {
			current_duration = (int)(player.get_duration() / 1000000000);
			var adj = new Adjustment(0, 0, current_duration, 1, 10, 10);
			progress_bar.set_adjustment(adj);
		});


		int y = 0;

		attach(image, 0, y, 8, 8);
		y = 8;
		attach(progress_bar, 1, y++, 6, 1);
		attach(progress_label, 2, y++, 4, 1);
		var button_box = new ButtonBox(Orientation.HORIZONTAL);
		button_box.set_layout(ButtonBoxStyle.EXPAND);
		button_box.set_halign(Gtk.Align.CENTER);
		button_box.add(bck_button);
		button_box.add(play_button);
		button_box.add(fwd_button);
		attach(button_box, 2, y++, 4, 1);
		// attach(speed_scale, 3, y++, 3, 1);
		attach(speed_button, 3, y++, 2, 1);
		attach(title_label, 0, y++, 8, 1);



		/**
		 * Handle play / pause
		 */
		play_button.clicked.connect( () => {

			switch (state) {

				case Gst.PlayerState.PLAYING:
					player.pause();
					state = Gst.PlayerState.PAUSED;
					play_button.set_image(play_icon);
					break;

				case Gst.PlayerState.PAUSED:
				case Gst.PlayerState.STOPPED:
					player.play();
					state = Gst.PlayerState.PLAYING;
					play_button.set_image(pause_icon);
					break;

				default:
					break;
			}

		});


		/**
		 * Seek backwards
		 */
		bck_button.clicked.connect( () => {
			seek(-15);
		});


		/**
		 * Seek forward
		 */
		fwd_button.clicked.connect( () => {
			seek(30);
		});


		/**
		 * Update progress bar and label while playback goes on
		 */
		player.position_updated.connect( (_pos) => {
			int pos = (int)(player.get_position() / 1000000000);
			progress_label.set_text("%s / %s".printf( time_to_str(pos), time_to_str(current_duration)));
			progress_bar.set_value(pos);
		});



	}

	public void set_title(string title) {
		title_label.set_markup(title);
	}

	public void set_cover(Gdk.Pixbuf pixbuf) {
		image.set_from_pixbuf(pixbuf);
	}
	

	public void play(string uri) {
		player.set_uri(uri);
		player.play();

		state = Gst.PlayerState.PLAYING;
		play_button.set_image(pause_icon);
	}


	protected void seek(int seconds) {
		Gst.ClockTime curpos = player.get_position();
		Gst.ClockTime newpos = curpos + (uint64)seconds * 1000000000;
		player.seek(newpos);
	}
}
