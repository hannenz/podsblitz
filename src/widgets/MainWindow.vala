namespace Podsblitz {

	public class MainWindow : Gtk.ApplicationWindow {


		protected Application app;

		protected uint configure_id;

		public Gtk.Stack stack;
		public Gtk.Stack stack2;

		public CoverView cover_view;
		public ListView latest_episodes_view;
		
		public Player player;
		public Subscription subscription = null;

		public signal void stack_switched(string name);

		public MainWindow(Application app) {
			Object (
				application: app
			);
			this.app = app;

			var paned = new Gtk.Paned(Gtk.Orientation.HORIZONTAL);

			stack = new Gtk.Stack();
			stack.set_transition_type(Gtk.StackTransitionType.SLIDE_LEFT_RIGHT);

			stack2 = new Gtk.Stack();
			stack2.set_transition_type(Gtk.StackTransitionType.SLIDE_UP_DOWN);

			cover_view = new CoverView();


			//////////////////////////////////////////////
			//  Setup TreeView (Stream, "Latest" view)  //
			//////////////////////////////////////////////

			latest_episodes_view = new ListView(true);

			var placeholder2 = new Gtk.Label("Here will be your offline episodes");
			var placeholder3 = new Gtk.Label("Here will be your playlist");

			var sw = new Gtk.ScrolledWindow(null, null);
			sw.add(latest_episodes_view);
			stack.add_titled(sw, "stream", _("Stream"));



			var vbox = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
			// var back_btn = new Gtk.Button.with_label("zurück");
			// back_btn.clicked.connect( () => {
			// 	stack2.set_visible_child_name("library-overview");
			// });
			// vbox.pack_start(back_btn, false, true, 0);


			var episodes_view = new ListView(false);
			episodes_view.play.connect( (id) => {
				// Get episode for id
				var episode = new Episode.by_id(id);
				// episode.dump();
				var cover = episode.get_cover(CoverSize.LARGE);
				this.player.set_cover(cover);
				this.player.set_title(episode.title);
				this.player.play(episode.file.get_uri());
			});

			var detail_header = new SubscriptionDetailHeader();
			detail_header.update_request.connect( () => {

				detail_header.spinner.visible = true;
				detail_header.spinner.start();
				detail_header.update_btn.sensitive = false;

				debug("*** FETCHING ***");
				subscription.fetch_async.begin( (obj, res) => {
					subscription.fetch_async.end(res);
					debug("*** SAVING ***");
					subscription.save();
					detail_header.spinner.visible = false;
					detail_header.spinner.stop();
					detail_header.update_btn.sensitive = true;
					debug("*** UPDATE GUI ***");
					episodes_view.clear();
					episodes_view.set_episodes(subscription.episodes);
				});

				subscription.fetch_cover_async.begin( (obj, res) => {
					subscription.fetch_cover_async.end(res);
					subscription.save();
					detail_header.image.pixbuf = subscription.cover_medium;
				});
			});

			vbox.pack_start(detail_header, false, true, 0);
			vbox.pack_start(episodes_view, true, true, 0);

			stack2.add_named(cover_view, "library-overview");
			stack2.add_named(vbox, "library-detail");

			cover_view.select.connect( (id) => {

				subscription = app.get_subscription(id);
				// subscription.dump();

				detail_header.set_image(subscription.cover_medium);
				// detail_header.set_title(subscription.title);
				// detail_header.set_description(subscription.description);
				detail_header.set_text(subscription.title, subscription.description);

				episodes_view.set_episodes(subscription.episodes);

				stack2.set_visible_child_name("library-detail");
			});

			stack.add_titled(stack2, "library", _("Library"));
			stack.add_titled(placeholder2, "offline", _("Offline"));
			stack.add_titled(placeholder3, "playlist", _("Playlist"));

			sw.map.connect( () => {
				stack_switched("stream");
			});
			stack2.map.connect( () => {
				stack_switched("library");
			});
			placeholder2.map.connect( () => {
				stack_switched("offline");
			});
			placeholder3.map.connect( () => {
				stack_switched("playlist");
			});


			paned.pack1(stack, true, false);


			player = new Player();
			// var player_vbox = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
			// var player_cover = new Gtk.Image();
			paned.pack2(player, false, false);
			player.set_size_request(CoverSize.LARGE, -1);


			add(paned);

			var headerbar = new HeaderBar(this);
			var menu_btn = new Gtk.MenuButton();
			menu_btn.image = new Gtk.Image.from_icon_name("open-menu-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
			menu_btn.tooltip_text = _("Settings");

			var menu_popover = new Gtk.Popover(menu_btn);
			menu_btn.popover = menu_popover;

			cover_view.map.connect( () => {
				headerbar.back_button.sensitive = false;
			});
			vbox.map.connect( () => {
				headerbar.back_button.sensitive = true;
			});

			headerbar.back_button_clicked.connect( () => {
				stack2.set_visible_child_name("library-overview");
			});

			
			headerbar.pack_end(menu_btn);
			set_titlebar(headerbar);
		}


		public override bool configure_event(Gdk.EventConfigure event) {
			if (configure_id != 0) {
				GLib.Source.remove(configure_id);
			}

			configure_id = Timeout.add(500, () => {
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

				var stack_name = stack.get_visible_child_name();
				debug(stack_name);
				Application.settings.set_string("stack-selected", stack_name);

				return false;
			});

			return base.configure_event(event);
		}
	}
}
