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
	public Gtk.Scale speed_scale;

	private Gtk.Image play_icon;
	private Gtk.Image pause_icon;

	private int current_duration;

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

		progress_bar = new Scale(Orientation.HORIZONTAL, null);
		progress_bar.set_draw_value(false);
		progress_label = new Label(null);
		var event_box = new EventBox();
		event_box.add(progress_bar);
		event_box.button_press_event.connect( (event) => {
			debug("%u,%u".printf((uint)event.x, (uint)event.y));
			return true;
		});

		speed_scale = new Gtk.Scale(Orientation.HORIZONTAL, new Gtk.Adjustment(0, 0.75, 3, 0.25, 0.25, 0.25));
		speed_scale.set_draw_value(false);
		speed_scale.add_mark(0.75, PositionType.BOTTOM, "0.75x");
		speed_scale.add_mark(1, PositionType.BOTTOM, "1x");
		speed_scale.add_mark(1.25, PositionType.BOTTOM, "1.25x");
		speed_scale.add_mark(2, PositionType.BOTTOM, "2x");
		speed_scale.add_mark(3, PositionType.BOTTOM, "3x");

		speed_scale.set_value(1.0);
		speed_scale.value_changed.connect( (range) => {
			player.set_rate(range.get_value());
		});

		// player.set_uri("https://cdn.podigee.com/media/podcast_17255_unter_pfarrerstochtern_episode_208542_sodom_und_gomorra.m4a?v=1587646976&amp;source=feed");
		player.set_uri("file:///home/hannenz/__Nextcloud/Messer_Banzani-Anthology_Vol_2-Skagga_Yo/01-19-Messer_Banzani-Peace_is_Wonder-128.mp3");
		player.play();
		play_button.set_image(pause_icon);


		state = Gst.PlayerState.PLAYING;
		player.duration_changed.connect( () => {
			current_duration = (int)(player.get_duration() / 1000000000);
			var adj = new Adjustment(0, 0, current_duration, 1, 10, 10);
			progress_bar.set_adjustment(adj);
		});

		// progress_bar.clicked.connect( () => {
		// 	player.seek((Gst.ClockTime)(progress_bar.get_value() * 1000000000));
		// });

		int y = 0;

		attach(image, 0, y, 8, 8);
		y = 8;
		attach(event_box, 1, y++, 6, 1);
		attach(progress_label, 3, y++, 3, 1);
		var button_box = new ButtonBox(Orientation.HORIZONTAL);
		button_box.set_layout(ButtonBoxStyle.EXPAND);
		button_box.add(bck_button);
		button_box.add(play_button);
		button_box.add(fwd_button);
		attach(button_box, 3, y++, 3, 1);
		attach(speed_scale, 3, y++, 3, 1);



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

		bck_button.clicked.connect( () => {
			seek(-15);
		});

		fwd_button.clicked.connect( () => {
			seek(30);
		});

		var config = player.get_config();
		Gst.Player.config_set_position_update_interval(config, 5000);


		player.position_updated.connect( (_pos) => {

			int pos = (int)(player.get_position() / 1000000000);
			
			progress_label.set_text("%s / %s".printf(
									time_to_str(pos),
									time_to_str(current_duration)
									));

			progress_bar.set_value(pos);
			// return  true;
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
	}
}
