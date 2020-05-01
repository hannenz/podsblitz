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
			icon_view.set_markup_column(ListStoreColumn.TITLE);
			icon_view.set_pixbuf_column(ListStoreColumn.COVER);
			icon_view.set_tooltip_column(Podsblitz.ListStoreColumn.DESCRIPTION);
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
						  ListStoreColumn.ID, out id,
						  ListStoreColumn.TITLE, out title,
						  -1
						 );
				print("Clicked on an icon view item: %u: %s\n", id, title);
			});

			var tree_view = new Gtk.TreeView();
			tree_view.set_model(this.app.get_latest());

			var cell = new Gtk.CellRendererPixbuf();

			var tvcol = new Gtk.TreeViewColumn();
			tvcol.set_title("Cover");
			tvcol.pack_start(cell, false);
			tvcol.set_attributes(cell, "pixbuf", 0);
			tvcol.set_sizing(Gtk.TreeViewColumnSizing.FIXED);
			tvcol.set_fixed_width(CoverSize.MEDIUM); // sohuld be SMALL later!!

			tree_view.append_column(tvcol);
			tree_view.insert_column_with_attributes(-1, "Description", new Gtk.CellRendererText(), "markup", 1);
			// tree_view.insert_column_with_attributes(-1, "Datum", new Gtk.CellRendererText(), "text", 2);
			tree_view.set_headers_visible(false);

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
