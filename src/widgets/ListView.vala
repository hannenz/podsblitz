using Gtk;

/**
 * View episodes in a list (1d tree view
 * This is just a "specialized" Gtk.TreeView
 */
public class Podsblitz.ListView : Bin  {

	private Gtk.TreeView tree_view;
	private Gtk.ScrolledWindow swin;
	private Gtk.ListStore model;

	private bool with_cover = false;

	public signal void select(int episode_id);

	public ListView(bool with_cover) {

		this.with_cover = with_cover;

		model = new Gtk.ListStore(
			EpisodeColumn.N_COLUMNS,
			typeof(int), 					// ID (database)
			typeof(string), 				// GUID
			typeof(Gdk.Pixbuf), 			// Cover
			typeof(string), 				// Episode title
			typeof(string), 				// Episode description
			typeof(string), 				// Podcast title
			typeof(DateTime), 				// Publication  date
			typeof(uint) 					// duration (seconds)
		);

		model.set_default_sort_func((model, iter1, iter2) => {
			DateTime date1, date2;
			model.get(iter1, EpisodeColumn.PUBDATE, out date1, -1);
			model.get(iter2, EpisodeColumn.PUBDATE, out date2, -1);
			return date1.compare(date2);
		});


		tree_view = new TreeView.with_model(model);

		var cell = new Gtk.CellRendererPixbuf();
		var tvcol = new Gtk.TreeViewColumn();
		tvcol.set_title("Cover");
		tvcol.pack_start(cell, false);
		tvcol.set_attributes(cell, "pixbuf", EpisodeColumn.COVER);
		tvcol.set_sizing(Gtk.TreeViewColumnSizing.FIXED);
		tvcol.set_fixed_width(CoverSize.SMALL); // sohuld be SMALL later!!
		tree_view.append_column(tvcol);
		tvcol.set_visible(with_cover);


		var body_cell = new Gtk.CellRendererText();
		body_cell.set("wrap-mode", Pango.WrapMode.WORD_CHAR);
		body_cell.set("wrap-width", 400);
		body_cell.set("yalign", 0);
		tvcol = new Gtk.TreeViewColumn();
		tvcol.set_title("Description");
		tvcol.pack_start(body_cell, false);
		tvcol.set_cell_data_func(body_cell, (cl, cell, model, iter) => {
			Gtk.CellRendererText crt = (Gtk.CellRendererText)cell;
			string title, description, subscription_title, markup;
			model.get(iter, EpisodeColumn.TITLE, out title, EpisodeColumn.DESCRIPTION, out description, EpisodeColumn.SUBSCRIPTION_TITLE, out subscription_title, -1);
			markup = @"<b><big>$title</big></b>\n";
			if (with_cover) {
				markup += @"<b>$subscription_title</b>\n";
			}
			markup += truncate(description, 3000);
			crt.markup = markup;
		});
		tvcol.set_expand(true);
		tree_view.append_column(tvcol);

		var date_cell = new Gtk.CellRendererText();
		date_cell.set("yalign", 0);
		tvcol = new Gtk.TreeViewColumn();
		tvcol.set_title("Date");
		tvcol.pack_start(date_cell, false);
		tvcol.set_cell_data_func(date_cell, (cl, cell, model, iter) => {
			DateTime pubdate;
			Gtk.CellRendererText crt = (Gtk.CellRendererText)cell;
			model.get(iter, EpisodeColumn.PUBDATE, out pubdate, -1);
			crt.markup = pubdate.format("<big>%e.%B %Y</big>\n%H:%M");
		});
		tree_view.append_column(tvcol);

		tree_view.row_activated.connect( (path) => {
			int id;
			Gtk.TreeIter iter;
			var model = tree_view.get_model();
			model.get_iter(out iter, path);
			model.get(iter, EpisodeColumn.ID, out id, -1);
			select(id);
		});

		tree_view.set_headers_visible(true);
		tree_view.set_headers_clickable(true);

		swin = new ScrolledWindow(null, null);
		swin.add(tree_view);
		add(swin);
	}


	public void clear() {
		model.clear();
	}


	public void set_episodes(List<Episode> episodes) {

		this.clear();
		foreach (var episode in episodes) {
			this.append(episode);
		}
	}


	public void append(Episode episode) {
		Gtk.TreeIter iter;
		// var subcription = new Subscription.by_id(episode.subscription_id);
		model.append(out iter);
		model.set(iter,
				  EpisodeColumn.ID, episode.id,
				  EpisodeColumn.GUID, episode.guid,
				  EpisodeColumn.TITLE, episode.title,
				  EpisodeColumn.DESCRIPTION, episode.description,
				  EpisodeColumn.PUBDATE, episode.pubdate,
				  // EpisodeColumn.SUBSCRIPTION_TITLE, subscription.title,
				  -1
				 );
	}
}
