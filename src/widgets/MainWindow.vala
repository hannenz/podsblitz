namespace Podsblitz {

	public class MainWindow : Gtk.ApplicationWindow {


		protected Application app;

		protected uint configure_id;

		public Gtk.Stack stack;


		public MainWindow(Application app) {
			Object (
				application: app
			);
			this.app = app;

			var paned = new Gtk.Paned(Gtk.Orientation.HORIZONTAL);

			// default_height = 600;
			// default_width = 600;

			// var vbox = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
			// vbox.margin = 4;

			stack = new Gtk.Stack();
			stack.set_transition_type(Gtk.StackTransitionType.SLIDE_LEFT_RIGHT);

			var icon_view = new Gtk.IconView.with_model(this.app.get_library());
			icon_view.set_markup_column(SubscriptionColumn.TITLE);
			icon_view.set_pixbuf_column(SubscriptionColumn.COVER);
			icon_view.set_tooltip_column(Podsblitz.SubscriptionColumn.DESCRIPTION);
			icon_view.set_item_width(64);
			icon_view.set_item_padding(0);
			icon_view.reorderable = true;
			icon_view.item_activated.connect( (path) => {

				string title;
				int id;
				Gtk.TreeIter iter;

				var model = icon_view.get_model();
				model.get_iter(out iter, path);
				model.get(iter, 
						  SubscriptionColumn.ID, out id,
						  SubscriptionColumn.TITLE, out title,
						  -1
						 );
				print("Clicked on an icon view item: %u: %s\n", id, title);

				// subscription.fetch_cover_async.begin( (obj, res) => {
				// 	subscription.fetch_cover_async.end();
				// 	subscription.save();
				// });

			});


			//////////////////////////////////////////////
			//  Setup TreeView (Stream, "Latest" view)  //
			//////////////////////////////////////////////

			var tree_view = new Gtk.TreeView();
			tree_view.set_model(this.app.get_latest());

			var cell = new Gtk.CellRendererPixbuf();
			var tvcol = new Gtk.TreeViewColumn();
			tvcol.set_title("Cover");
			tvcol.pack_start(cell, false);
			tvcol.set_attributes(cell, "pixbuf", EpisodeColumn.COVER);
			tvcol.set_sizing(Gtk.TreeViewColumnSizing.FIXED);
			tvcol.set_fixed_width(CoverSize.MEDIUM); // sohuld be SMALL later!!
			tree_view.append_column(tvcol);

			var body_cell = new Gtk.CellRendererText();
			body_cell.set("wrap-mode", Pango.WrapMode.WORD_CHAR);
			body_cell.set("wrap-width", 400);
			body_cell.set("yalign", 0);
			tvcol = new Gtk.TreeViewColumn();
			tvcol.set_title("Description");
			tvcol.pack_start(body_cell, false);
			tvcol.set_cell_data_func(body_cell, (cl, cell, model, iter) => {
				Gtk.CellRendererText crt = (Gtk.CellRendererText)cell;

				string title, description, subscription_title;
				model.get(iter, EpisodeColumn.TITLE, out title, EpisodeColumn.DESCRIPTION, out description, EpisodeColumn.SUBSCRIPTION_TITLE, out subscription_title, -1);
				crt.markup = "<b><big>%s</big></b>\n<b>%s</b>\n%s".printf(title, subscription_title, truncate(description, 100));
			});
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
				crt.markup = pubdate.format("<b>%d.%B %Y</b>\n%H:%M");
			});
			tree_view.append_column(tvcol);

			tree_view.row_activated.connect( (path) => {
				DateTime pubdate;
				Gtk.TreeIter iter;

				var model = tree_view.get_model();
				model.get_iter(out iter, path);
				model.get(iter, EpisodeColumn.PUBDATE, out pubdate, -1);

				if (pubdate != null) {
					debug(pubdate.format("%d.%m.%Y %T"));
				}
				else {
					debug("NO Date");
				}
			});

			tree_view.set_headers_visible(true);
			tree_view.set_headers_clickable(true);



			var placeholder2 = new Gtk.Label("Here will be your offline episodes");
			var placeholder3 = new Gtk.Label("Here will be your playlist");

			var sw = new Gtk.ScrolledWindow(null, null);
			sw.add(tree_view);
			stack.add_titled(sw, "stream", _("Stream"));

			sw = new Gtk.ScrolledWindow(null, null);
			sw.add(icon_view);

			stack.add_titled(sw, "library", _("Library"));
			stack.add_titled(placeholder2, "offline", _("Offline"));
			stack.add_titled(placeholder3, "playlist", _("Playlist"));


			stack.set_visible_child_name(Application.settings.get_string("stack-selected"));
			stack.map.connect( (source) => {
				var name = stack.get_visible_child_name();
				print("Saving state: %s\n", name);
				Application.settings.set_string("stack-selected", name);
			});

			paned.pack1(stack, true, false);


			var player_vbox = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
			// var player_cover = new Gtk.Image();
			paned.pack2(player_vbox, false, false);
			player_vbox.set_size_request(300, -1);


			add(paned);

			var headerbar = new HeaderBar(this);
			set_titlebar(headerbar);
		}


		public override bool configure_event(Gdk.EventConfigure event) {
			if (configure_id != 0) {
				GLib.Source.remove(configure_id);
			}

			configure_id = Timeout.add(100, () => {
				configure_id = 0;

				if (is_maximized) {
					Application.settings.set_boolean("window-maximized", true);
				}
				else {
					Application.settings.set_boolean("window-maximized", false);

					Gdk.Rectangle rect;
					get_allocation(out rect);
					Application.settings.set("window-size", "(ii)", rect.width, rect.height);

					int root_x, root_y;
					get_position(out root_x, out root_y);
					Application.settings.set("window-position", "(ii)", root_x, root_y);
				}

				return false;
			});

			return base.configure_event(event);
		}
	}
}
