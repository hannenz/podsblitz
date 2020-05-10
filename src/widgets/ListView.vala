using Gtk;

/**
 * View episodes in a list (1d tree view
 * This is just a "specialized" Gtk.TreeView
 */
public class Podsblitz.ListView : Bin  {

	private Gtk.ListBox list_box;
	private Gtk.ScrolledWindow swin;

	private bool with_cover = false;

	public signal void select(int episode_id);

	public ListView(bool with_cover) {

		this.with_cover = with_cover;


		list_box = new ListBox();
		// list_box.bind_model(model, create_list_box_item);
		list_box.set_sort_func( (row1, row2) => {
			var episode1 = row1.get_child() as Episode;
			var episode2 = row2.get_child() as Episode;
			return episode1.pubdate.compare(episode2.pubdate);
		});

		list_box.row_activated.connect( (row) => {

			// int id;
			// Gtk.TreeIter iter;
			// var model = tree_view.get_model();
			// model.get_iter(out iter, path);
			// model.get(iter, EpisodeColumn.ID, out id, -1);
			// select(id);
		});

		// tree_view.set_headers_visible(false);
		// tree_view.set_headers_clickable(true);

		swin = new ScrolledWindow(null, null);
		swin.add(list_box);
		add(swin);
	}


	private Widget create_list_box_item(Episode episode) {

		var item = new Grid();
		item.column_spacing = 10;

		var title = new Label(null);
		title.set_markup("<big><b>%s</b></big>".printf(episode.title));
		title.set_line_wrap(true);
		title.set_xalign(0);

		var descr = new Label(episode.description);
		descr.set_line_wrap(true);
		descr.set_xalign(0);

		var action_bar = new ActionBar();

		var play_btn = new Gtk.Button();
		play_btn.set_image(new Gtk.Image.from_icon_name("media-playback-start-symbolic", IconSize.BUTTON));

		var dl_btn = new Gtk.Button();
		dl_btn.set_image(new Gtk.Image.from_icon_name("document-save-symbolic", IconSize.BUTTON));

		action_bar.pack_start(play_btn);
		action_bar.pack_start(dl_btn);

		item.attach(title, 0, 0, 12, 1);
		item.attach(descr, 0, 1, 12, 1);
		item.attach(action_bar, 0, 2, 12, 1);

		item.set_margin_top(20);
		item.show_all();
		return item;
	}


	public void clear() {
		// model.clear();
	}


	public void set_episodes(List<Episode> episodes) {

		this.clear();
		foreach (var episode in episodes) {
			this.append(episode);
		}
	}


	public void append(Episode episode) {
		list_box.add(create_list_box_item(episode));
	}
}
