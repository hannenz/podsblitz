using Gtk;

/**
 * View subscriptions in a IconView 
 * This is just a "specialized" Gtk.IconView
 */
public class Podsblitz.CoverView : Bin {

	private Gtk.IconView icon_view;
	private Gtk.ScrolledWindow swin;
	private Gtk.ListStore model;

	public signal void select(int subscription_id);

	public CoverView() {


		model = new Gtk.ListStore(
			SubscriptionColumn.N_COLUMNS,
			typeof(int), 				// ID (database)
			typeof(string),				// Title
			typeof(string), 			// Title shortened
			typeof(Gdk.Pixbuf),			// Cover
			typeof(int), 				// Position (Order)
			typeof(string),				// Description
			typeof(string) 				// URL
		);

		icon_view = new IconView.with_model(model);

		// icon_view.column_spacing = ;
		icon_view.item_padding = 0;
		icon_view.item_width = 64;
		// icon_view.margin = ;
		// icon_view.column_spacing = ;
		// icon_view.row_spacing = ;

		icon_view.activate_on_single_click = true;
		icon_view.markup_column = SubscriptionColumn.TITLE_SHORT;
		icon_view.pixbuf_column = SubscriptionColumn.COVER;
		icon_view.tooltip_column = SubscriptionColumn.DESCRIPTION;

		swin = new ScrolledWindow(null, null);
		swin.add(icon_view);

		icon_view.item_activated.connect( (path) => {
			Gtk.TreeIter iter;
			int id;
			model.get_iter(out iter, path);
			model.get(iter, SubscriptionColumn.ID, out id, -1);
			select(id);
		});

		add(swin);
	}


	public void clear() {
		model.clear();
	}


	public void set_subscriptions(List<Subscription> subscriptions) {
		this.clear();
		foreach (var subscription in subscriptions) {
			this.append(subscription);
		}
	}


	public void append(Subscription subscription) {

		Gtk.TreeIter iter;
		model.append(out iter);
		model.set(iter,
				  SubscriptionColumn.ID, subscription.id,
				  SubscriptionColumn.COVER, subscription.cover_medium,
				  SubscriptionColumn.TITLE, Markup.escape_text(subscription.title), 
				  SubscriptionColumn.TITLE_SHORT, Markup.escape_text(truncate(subscription.title, 200)),
				  SubscriptionColumn.DESCRIPTION, Markup.escape_text(subscription.description),
				  SubscriptionColumn.POSITION, subscription.pos,
				  SubscriptionColumn.URL, subscription.url,
				  -1
			 );
	}
}

