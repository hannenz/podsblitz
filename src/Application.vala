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


	public enum CoverSize {
		SMALL = 90,
		MEDIUM = 150,
		LARGE = 300
	}


	public class Application : Gtk.Application {


		public static GLib.Settings settings;

		public MainWindow main_window;

		protected Database db;

		public List<Subscription> subscriptions;


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


			load_subscriptions.begin( (obj, res) => {
				load_subscriptions.end(res);
				main_window.cover_view.set_subscriptions(subscriptions);
			});


			var n = settings.get_string("stack-selected");
			main_window.stack.set_visible_child_name(n);
			main_window.stack_switched.connect( (name) => {
				settings.set_string("stack-selected", name);
			});

			main_window.latest_episodes_view.play.connect(play_episode);
			main_window.episodes_view.play.connect(play_episode);
		}



		// Load subscriptions from database
		protected async void load_subscriptions() {

			Idle.add(load_subscriptions.callback);
			yield;

			try {
				var stream = new List<Episode>();

				this.db.query("SELECT * FROM subscriptions");
				var results = this.db.getAll();

				foreach (Gee.HashMap<string,string> result in results) {
					var subscription = new Subscription.from_hash_map(result);
					subscriptions.append(subscription);

					// Fill stream (latest episodes from all subscriptions)
					int i = 0;
					foreach (var episode in subscription.episodes) {
						stream.insert_sorted(episode, (a, b) => {
							return b.pubdate.compare(a.pubdate);
						});
						if (i++ > 5) {
							break;
						}
					}
				}

				main_window.latest_episodes_view.clear();
				main_window.latest_episodes_view.set_episodes(stream);
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
		 * Play an episode
		 *
		 * @param int 		episode id
		 * @return void
		 */
		public void play_episode(int id) {
			// Get episode for id
			var episode = new Episode.by_id(id);
			episode.dump();
			var cover = episode.get_cover(CoverSize.LARGE);
			main_window.player.set_cover(cover);
			main_window.player.set_title(episode.title);
			main_window.player.play(episode.file.get_uri());
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

			subscription.subscribe(url);
		}


		/**
		 * Update all subscriptions
		 */
		public void update_subscriptions() {
			debug("Updating subscriptions\n");

			foreach (var subscription in subscriptions) {
				debug("Updating subscription: %s (%s)\n", subscription.title, subscription.url);

				// library.set(iter, SubscriptionColumn.TITLE, "Updating …", -1);

				subscription.fetch_async.begin( (obj, res) => {
					subscription.fetch_async.end(res);
					// library.set(iter, SubscriptionColumn.TITLE, subscription.title + "(%u)".printf(subscription.episodes.length()));
					subscription.save();

					main_window.latest_episodes_view.set_episodes(subscription.episodes);
				});

				subscription.fetch_cover_async.begin((obj, res) => {
					subscription.fetch_cover_async.end(res);
					// library.set(iter, SubscriptionColumn.COVER, subscription.cover_small);
					subscription.save();
				});
			}

		}
	}
}
