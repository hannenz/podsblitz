namespace Podsblitz {

	enum ListStoreColumn {
		ID,
		TITLE,
		TITLE_SHORT,
		COVER,
		POSITION,
		DESCRIPTION,
		URL,
		N_COLUMNS
	}

	enum CoverSize {
		SMALL = 90,
		MEDIUM = 150,
		LARGE = 300
	}

	public class PodsblitzApplication : Gtk.Application {


		public static GLib.Settings settings;

		protected Gtk.ListStore library;

		protected Gtk.ListStore latest;

		protected Database db;


		public static PodsblitzApplication() {
			Object(
				application_id: "de.hannenz.podsblitz",
				flags: ApplicationFlags.FLAGS_NONE
			);

			settings = new GLib.Settings("de.hannenz.podsblitz");

			try {
				this.db = new Database();
			}
			catch (DatabaseError.OPEN_FAILED e) {
				stderr.printf("%s\n", e.message);
				return;
			}

			// this.subscriptions = new List<Subscription>();

			this.library = new Gtk.ListStore (
				ListStoreColumn.N_COLUMNS,
				typeof(int), 				// ID (database)
				typeof(string),				// Title
				typeof(string), 			// Title shortened
				typeof(Gdk.Pixbuf),			// Cover
				typeof(int), 				// Position (Order)
				typeof(string),				// Description
				typeof(string) 				// URL
			);


			this.latest = new Gtk.ListStore(
				6,
				typeof(Gdk.Pixbuf), 			// Cover
				typeof(string), 				// Episode title
				typeof(string), 				// Episode description
				typeof(string), 				// Podcast title
				typeof(GLib.Date), 				// Publication  date
				typeof(uint) 					// duration (seconds)
				);
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

			load_subscriptions();

			library.foreach( (model, path, iter) => {
				var subscription = get_subscription(iter);
				subscription.dump();
				return false;
			});
		}


		// Load subscriptions from database
		protected void load_subscriptions() {

			try {
				this.db.query("SELECT * FROM subscriptions");
				var results = this.db.getAll();
				foreach (Gee.HashMap<string,string> result in results) {

					var subscription = new Subscription.from_hash_map(result);
					// subscription.fetch();
					// subscription.dump();

					// Add to ListStore and listen for changes
					registrate_subscription(subscription);
				}
			}
			catch (DatabaseError e) {
				stderr.printf("Database error: %s\n", e.message);
			}

		}


		private Subscription get_subscription(Gtk.TreeIter iter) {

			string title, description, url;
			int pos;
			var subscription = new Subscription(); 

			library.get(
						iter,
						ListStoreColumn.TITLE, out title,
						ListStoreColumn.POSITION, out pos,
						ListStoreColumn.DESCRIPTION, out description,
						ListStoreColumn.URL, out url,
						-1
					);

			subscription.title = title;
			subscription.description = description;
			subscription.url = url;
			subscription.pos = pos;

			return subscription;
		}




		/**
		 * Add a subscription to the ListStore and connect signals
		 *
		 * @param Podsblitz.Subscription subscription
		 * @return void
		 */
		private void registrate_subscription(Subscription subscription) {

			Gtk.TreeIter iter;
			this.library.append(out iter);
			this.library.set(iter,
							 ListStoreColumn.ID, subscription.id,
							 ListStoreColumn.TITLE, Markup.escape_text(subscription.title), 
							 ListStoreColumn.TITLE_SHORT, Markup.escape_text(truncate(subscription.title, 200)),
							 ListStoreColumn.COVER, subscription.cover,
							 ListStoreColumn.POSITION, subscription.pos,
							 ListStoreColumn.DESCRIPTION, subscription.description,
							 ListStoreColumn.URL, subscription.url,
							 -1);

			subscription.iter = iter;

			subscription.changed.connect((subscription) => {
				print("Subscription has changed, updating TreeStore and saving it to db now\n");
				this.library.set(subscription.iter,
								 ListStoreColumn.ID, subscription.id,
								 ListStoreColumn.TITLE, Markup.escape_text(subscription.title), 
								 ListStoreColumn.TITLE_SHORT, Markup.escape_text(truncate(subscription.title, 200)),
								 ListStoreColumn.COVER, subscription.cover,
								 ListStoreColumn.POSITION, subscription.pos,
								 ListStoreColumn.DESCRIPTION, subscription.description,
								 ListStoreColumn.URL, subscription.url,
								 -1
						);
				subscription.save();
			});
		}


		protected override void activate() {
			int window_x, window_y;
			var rect = Gtk.Allocation();


			settings.get("window-position", "(ii)", out window_x, out window_y);
			settings.get("window-size", "(ii)", out rect.width, out rect.height);

			var main_window = new MainWindow(this);


			if (window_x != -1 || window_y != -1) {
				main_window.move(window_x, window_y);
			}

			main_window.set_allocation(rect);

			if (settings.get_boolean("window-maximized")) {
				main_window.maximize();
			}

			main_window.show_all();

			// TODO: Store current selection in GSettings and read from there
			main_window.stack.set_visible_child_name("library");
		}


		public void add_subscription() {
			print("Activating 'Add Podcast' action\n");
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
			print("Updating subsccriptions\n");

			library.foreach((model, path, iter) => {
				if (path.to_string() == "2") {
					var subscription = get_subscription(iter);
					print("Updating subscription: %s %s (%s)\n", path.to_string(), subscription.title, subscription.url);
					subscription.fetch();
				}
				return false;
			});

		}

		public void update_stream() {
		}


		public Gtk.ListStore get_library() {
			return this.library;
		}


		public Gtk.ListStore get_latest() {
			return this.latest;
		}

	}
}
