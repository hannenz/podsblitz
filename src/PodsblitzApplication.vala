namespace Podsblitz {

	public class PodsblitzApplication : Gtk.Application {


		public static GLib.Settings settings;

		protected Gtk.ListStore library;

		protected Gtk.ListStore latest;

		protected List<Subscription> subscriptions;

		protected Database db;


		public static PodsblitzApplication() {
			Object(
				application_id: "de.hannenz.podsblitz",
				flags: ApplicationFlags.FLAGS_NONE
			);

			settings = new GLib.Settings("de.hannenz.podsblitz");

			this.db = new Database();

			this.subscriptions = new List<Subscription>();

			this.library = new Gtk.ListStore (
				4,
				typeof(string),				// Title
				typeof(string), 			// Title shortened
				typeof(Gdk.Pixbuf),			// Cover
				typeof(int) 				// Position (Order)
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

			Gtk.TreeIter iter;
			// Gdk.Pixbuf pixbuf1, pixbuf2, pixbuf3;

			base.startup();

			// Create the menu

			var action = new GLib.SimpleAction("add-subscription", null);
			action.activate.connect(addSubscription);
			add_action(action);

			Menu app_menu = new Menu();
			app_menu.append("Add a podcast", "app.add-subscription");
			set_app_menu(app_menu);


			var db = new Database();
			this.subscriptions = db.getAllSubscriptions();
			
			foreach (Subscription subscription in this.subscriptions) {

				subscription.dump();

				// var pixbuf = new Gdk.Pixbuf.from_file_at_size("/home/hannenz/Downloads/90b94565-0091-46e2-9b1b-52b53e1eb051.png.jpeg", 200, 200);
				this.library.append(out iter);
				this.library.set(iter,
								 0, Markup.escape_text(subscription.title), 
								 1, Markup.escape_text(truncate(subscription.title, 200)),
								 2, subscription.cover,
								 3, subscription.pos
								 -1);
				subscription.iter = iter;
				subscription.changed.connect( (sub) => {
					this.library.set(sub.iter,
							0, Markup.escape_text(sub.title),
							1, Markup.escape_text(truncate(sub.title, 200)),
							2, sub.cover,
							3, sub.pos
							);
					this.db.saveSubscription(sub);
				});
			}
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



			return;
 
			// foreach (Subscription subscription in this.subscriptions) {
			// 	subscription.update();
			// }
		}


		public void addSubscription() {
			print("Activating 'Add Podcast' action\n");
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


		public void updateStream() {
		}


		public Gtk.ListStore get_library() {
			return this.library;
		}


		public Gtk.ListStore get_latest() {
			return this.latest;
		}

	}
}
