using Gtk;

public class Podsblitz.EpisodeItem : Grid {

	public bool with_cover { get; set; }

	public Episode episode;

	public signal void play(int episode_id);

	public EpisodeItem(Episode episode, bool with_cover = false) {
		this.episode = episode;
		column_spacing = 10;
		column_homogeneous = false;
		row_homogeneous = false;

		var title = new Label(null);
		title.set_markup("<big><b>%s</b></big>".printf(episode.title));
		title.set_line_wrap(true);
		title.set_xalign(0);
		title.hexpand = true;

		var descr = new Label(episode.description);
		descr.set_line_wrap(true);
		descr.set_xalign(0);
		descr.hexpand = true;

		var date = new Label(null);
		date.set_markup("<b>%s</b>\n%s".printf(
				episode.pubdate.format("%d.%m"),
				episode.pubdate.format("%Y")
		));
		date.set_yalign(0);

		var action_bar = new ActionBar();

		var play_btn = new Gtk.Button.from_icon_name("media-playback-start-symbolic", IconSize.BUTTON);
		play_btn.clicked.connect( () => {
			this.play(episode.id);
		});

		var download_btn = new Gtk.Button.from_icon_name("document-save-symbolic", IconSize.BUTTON);
		var bookmark_btn = new Gtk.Button.from_icon_name("bookmark-new-symbolic", IconSize.BUTTON);

		action_bar.pack_start(play_btn);
		action_bar.pack_start(download_btn);
		action_bar.pack_start(bookmark_btn);

		attach(date, 0, 0, 2, 2);
		if (with_cover == true) {
			var image = new Gtk.Image.from_pixbuf(episode.get_cover(CoverSize.SMALL));
			attach(image, 2, 0, 2, 2);
		}
		attach(title, 4, 0, 8, 1);
		attach(descr, 4, 1, 8, 1);
		attach(action_bar, 0, 2, 12, 1);

		set_margin_top(20);

		var style_context = this.get_style_context();
		style_context.add_class("episode-item");
	}
}
