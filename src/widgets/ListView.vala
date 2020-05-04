using Gtk;

/**
 * View episodes in a list (1d tree view
 * This is just a "specialized" Gtk.TreeView
 */
public class Podsblitz.ListView : TreeView  {

	private Gtk.ListStore items;

	public ListView() {

		items = new Gtk.ListStore(
			EpisodeColumn.N_COLUMNS,
			typeof(Gdk.Pixbuf), 			// Cover
			typeof(string), 				// Episode title
			typeof(string), 				// Episode description
			typeof(string), 				// Podcast title
			typeof(DateTime), 				// Publication  date
			typeof(uint) 					// duration (seconds)
		);
	}


	public void set_episodes(List<Episode> episodes) {

	}
}
