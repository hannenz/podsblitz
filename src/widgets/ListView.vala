using Gtk;

/**
 * View episodes in a list (1d tree view
 * This is just a "specialized" Gtk.TreeView
 */
public class Podsblitz.ListView : Bin  {

	private Gtk.ListBox list_box;
	private Gtk.ScrolledWindow swin;

	private bool with_cover = false;

	public signal void play(int episode_id);

	public ListView(bool with_cover) {

		this.with_cover = with_cover;
		list_box = new ListBox();
		swin = new ScrolledWindow(null, null);
		swin.add(list_box);
		add(swin);
	}


	private Widget create_list_box_item(Episode episode) {
		var item = new EpisodeItem(episode, false);
		item.play.connect( (episode_id) => {
			this.play(episode_id);
		});
		item.show_all();
		return item;
	}


	public void clear() {
		list_box.get_children().foreach( (row) => list_box.remove(row));
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
