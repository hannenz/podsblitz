namespace Podsblitz {

	enum SubscriptionColumn {
		ID,
		TITLE,
		TITLE_SHORT,
		COVER,
		POSITION,
		DESCRIPTION,
		URL,
		N_COLUMNS
	}

	enum EpisodeColumn {
		COVER,
		TITLE,
		DESCRIPTION,
		SUBSCRIPTION_TITLE,
		PUBDATE,
		DURATION,
		N_COLUMNS
	}


	enum CoverSize {
		SMALL = 90,
		MEDIUM = 150,
		LARGE = 300
	}

	public class Application : Gtk.Application {


		public static GLib.Settings settings;

		// protected Gtk.ListStore library;

		protected Gtk.ListStore latest;

		public MainWindow main_window;

		protected Database db;

		public List<Subscription> subscriptions;

		public Gdk.Pixbuf noimage;
		public Gdk.Pixbuf noimage_large;
		public Gdk.Pixbuf noimage_medium;
		public Gdk.Pixbuf noimage_small;


		public static Application() {
			Object(
				application_id: "de.hannenz.podsblitz",
				flags: ApplicationFlags.FLAGS_NONE
			);

			subscriptions = new List<Subscription>();

			settings = new GLib.Settings("de.hannenz.podsblitz");

			try {
				this.db = new Database();
			}
			catch (DatabaseError e) {
				stderr.printf("%s\n", e.message);
				return;
			}

			noimage = null;
			try {
				noimage = new Gdk.Pixbuf.from_resource("/de/hannenz/podsblitz/img/noimage.png");
				noimage_large = noimage.scale_simple(CoverSize.LARGE, CoverSize.LARGE, Gdk.InterpType.BILINEAR);
				noimage_medium = noimage.scale_simple(CoverSize.MEDIUM, CoverSize.MEDIUM, Gdk.InterpType.BILINEAR);
				noimage_small = noimage.scale_simple(CoverSize.SMALL, CoverSize.SMALL, Gdk.InterpType.BILINEAR);
			}
			catch (Error e) {
				stderr.printf("Error while loading noimage.png: %s\n", e.message);
			}


			this.latest = new Gtk.ListStore(
				EpisodeColumn.N_COLUMNS,
				typeof(Gdk.Pixbuf), 			// Cover
				typeof(string), 				// Episode title
				typeof(string), 				// Episode description
				typeof(string), 				// Podcast title
				typeof(DateTime), 				// Publication  date
				typeof(uint) 					// duration (seconds)
			);

			this.latest.set_default_sort_func((model, iter1, iter2) => {
				DateTime date1, date2;
				model.get(iter1, EpisodeColumn.PUBDATE, out date1, -1);
				model.get(iter2, EpisodeColumn.PUBDATE, out date2, -1);
				return date1.compare(date2);
			});
		}

		protected override void startup() {

			base.startup();

			// Create the menu
			var action = new GLib.SimpleAction("add-subscription", null);
			action.activate.connect(add_subscription);
			add_action(action);

			action = new GLib.SimpleAction("update-subscriptions", null);
			action.activate.connect(update_subscriptions);
			add_action(action);

			var app_menu = new Menu();
			app_menu.append("Add a podcast", "app.add-subscription");
			app_menu.append("Update all", "app.update-subscriptions");
			set_app_menu(app_menu);

			// update_subscriptions();
		}


		protected override void activate() {
			int window_x, window_y;
			var rect = Gtk.Allocation();

			settings.get("window-position", "(ii)", out window_x, out window_y);
			settings.get("window-size", "(ii)", out rect.width, out rect.height);

			main_window = new MainWindow(this);

			if (window_x != -1 || window_y != -1) {
				main_window.move(window_x, window_y);
			}

			main_window.set_allocation(rect);

			if (settings.get_boolean("window-maximized")) {
				main_window.maximize();
			}

			main_window.show_all();


			var provider = new Gtk.CssProvider();
			provider.load_from_resource("/de/hannenz/podsblitz/styles/global.css");
			Gtk.StyleContext.add_provider_for_screen(
				Gdk.Screen.get_default(),
				provider,
				Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
			);

			load_subscriptions();
			main_window.cover_view.set_subscriptions(subscriptions);

			// TODO: Store current selection in GSettings and read from there
			main_window.stack.set_visible_child_name("library");
		}



		// Load subscriptions from database
		protected void load_subscriptions() {

			try {
				this.db.query("SELECT * FROM subscriptions");
				var results = this.db.getAll();
				foreach (Gee.HashMap<string,string> result in results) {

					var subscription = new Subscription.from_hash_map(result);
					// subscription.fetch();


					// Add to ListStore and listen for changes
					subscriptions.append(subscription);
					registrate_subscription(subscription);
				}
			}
			catch (DatabaseError e) {
				stderr.printf("Database error: %s\n", e.message);
			}

		}


		public Subscription? get_subscription(int id) {

			foreach (var subscription in subscriptions) {
				if (subscription.id == id) {
					return subscription;
				}
			}
			return null;
		}




		/**
		 * Add a subscription to the ListStore and connect signals
		 *
		 * @param Podsblitz.Subscription subscription
		 * @return void
		 */
		private void registrate_subscription(Subscription subscription) {

			// Gtk.TreeIter iter;
			// this.library.append(out iter);
			// this.library.set(iter,
			// 				 SubscriptionColumn.ID, subscription.id,
			// 				 SubscriptionColumn.COVER, subscription.cover,
			// 				 SubscriptionColumn.TITLE, Markup.escape_text(subscription.title), 
			// 				 SubscriptionColumn.TITLE_SHORT, Markup.escape_text(truncate(subscription.title, 200)),
			// 				 SubscriptionColumn.DESCRIPTION, Markup.escape_text(subscription.description),
			// 				 SubscriptionColumn.POSITION, subscription.pos,
			// 				 SubscriptionColumn.URL, subscription.url,
			// 				 -1);
            //
			// subscription.iter = iter;
            //
			// subscription.changed.connect((subscription) => {
			// 	debug("Subscription has changed, updating TreeStore and saving it to db now\n");
			// 	this.library.set(subscription.iter,
			// 					 SubscriptionColumn.ID, subscription.id,
			// 					 SubscriptionColumn.COVER, subscription.cover,
			// 					 SubscriptionColumn.TITLE, Markup.escape_text(subscription.title), 
			// 					 SubscriptionColumn.TITLE_SHORT, Markup.escape_text(truncate(subscription.title, 200)),
			// 					 SubscriptionColumn.DESCRIPTION, Markup.escape_text(subscription.description),
			// 					 SubscriptionColumn.POSITION, subscription.pos,
			// 					 SubscriptionColumn.URL, subscription.url,
			// 					 -1
			// 			);
			// 	subscription.save();
			// });
		}




		public void add_subscription() {
			var dlg = new AddSubscriptionDialog();
			var ret = dlg.run();
			dlg.close();
			if  (ret != Gtk.ResponseType.APPLY) {
				return;
			}
			var url = dlg.get_url();

			var subscription = new Subscription();

			registrate_subscription(subscription);

			subscription.subscribe(url);
		}


		/**
		 * Update all subscriptions
		 */
		public void update_subscriptions() {
			debug("Updating subsccriptions\n");

			// library.foreach((model, path, iter) => {
            //
			// 	var subscription = get_subscription(iter);
			// 	debug("Updating subscription: %s %s (%s)\n", path.to_string(), subscription.title, subscription.url);
            //
			// 	library.set(iter, SubscriptionColumn.TITLE, "Updating …", -1);
            //
			// 	subscription.fetch_async.begin( (obj, res) => {
			// 		subscription.fetch_async.end(res);
			// 		library.set(iter, SubscriptionColumn.TITLE, subscription.title + "(%u)".printf(subscription.episodes.length()));
			// 		subscription.save();
            //
			// 		foreach (var episode in subscription.episodes) {
            //
			// 			Gtk.TreeIter latest_iter;
			// 			latest.append(out latest_iter);
			// 			latest.set(latest_iter, 
			// 					   EpisodeColumn.COVER, (subscription.cover_small != null) ? subscription.cover_small : noimage_small,
			// 					   EpisodeColumn.TITLE, Markup.escape_text(episode.title),
			// 					   EpisodeColumn.DESCRIPTION, Markup.escape_text(episode.description),
			// 					   EpisodeColumn.SUBSCRIPTION_TITLE, Markup.escape_text(subscription.title),
			// 					   EpisodeColumn.PUBDATE, episode.pubdate,
			// 					   EpisodeColumn.DURATION, episode.duration,
			// 					   -1
			// 				  );
            //
			// 			episode.save();
			// 		}
			// 	});
			// 	subscription.fetch_cover_async.begin((obj, res) => {
			// 		subscription.fetch_cover_async.end(res);
			// 		library.set(iter, SubscriptionColumn.COVER, subscription.cover_small);
			// 		subscription.save();
			// 	});
			// 	return false;
			// });

		}

		public Gtk.ListStore get_latest() {
			return this.latest;
		}

	}
}
