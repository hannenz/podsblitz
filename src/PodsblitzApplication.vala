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


			// try {
			// 	pixbuf1 = new Gdk.Pixbuf.from_file_at_size("/home/hannenz/Downloads/90b94565-0091-46e2-9b1b-52b53e1eb051.png.jpeg", 200, 200);
			// }
			// catch (Error e) {
			// 	stderr.printf("Failed to create pixbuf from file\n");
			// 	return;
			// }
            //
			// this.library.append(out iter);
			// this.library.set(iter, 0, "True Kleincrime", 1, pixbuf1, -1);
            //
			// try {
			// 	pixbuf2 = new Gdk.Pixbuf.from_file_at_size("/home/hannenz/Downloads/dd50b44d-03ac-41b3-8258-7a2c228319b5.jpeg", 200, 200);
			// }
			// catch (Error e) {
			// 	stderr.printf("Failed to create pixbuf from file\n");
			// 	return;
			// }
            //
			// this.library.append(out iter);
			// this.library.set(iter, 0, "Tagesticket", 1, pixbuf2, -1);
            //
			// try {
			// 	pixbuf3 = new Gdk.Pixbuf.from_file_at_size("/home/hannenz/Downloads/df6d708f45c10c57f0f46b6fc9ea8e279fc3e006.jpg", 200, 200);
			// }
			// catch (Error e) {
			// 	stderr.printf("Failed to create pixbuf from file\n");
			// 	return;
			// }
            //
			// this.library.append(out iter);
			// this.library.set(iter, 0, "Deutschlandfunk - der Tag", 1, pixbuf3, -1);
            //
            //
			this.latest = new Gtk.ListStore(
				6,
				typeof(Gdk.Pixbuf), 			// Cover
				typeof(string), 				// Episode title
				typeof(string), 				// Episode description
				typeof(string), 				// Podcast title
				typeof(GLib.Date), 				// Publication  date
				typeof(uint) 					// duration (seconds)
				);
            //
			// this.latest.append(out iter);
			// this.latest.set(iter, 
			// 				0, pixbuf3.scale_simple(96, 96, Gdk.InterpType.BILINEAR),
			// 				1, "<b>Der lange Weg zurück zur Normalität - Der Tag</b>\n<small><b>Deutschlandfunk - Der Tag</b></small>\nDie massiven Beschränkungen der letzen Wochen wirken. Die Infektionskurve flacht sich stark ab. Warum die Rückkehr …",
			// 				2, "Lorem ipsum dolor sit amet",
			// 				3, "True Kleincrime",
			// 				4, new DateTime.now_local(),
			// 				5, 72 * 60,
			// 				-1
			// 			   );
            //
			// this.latest.append(out iter);
			// this.latest.set(iter, 
			// 				0, pixbuf2.scale_simple(96, 96, Gdk.InterpType.BILINEAR),
			// 				1, "<b>Was die Corona-Isolation mit Suchtkranken macht</b>\n<small><b>Tagesticket - der Frühpodcast</b></small>\nDas Kontaktverbot macht es Suchtberatungsstellen schwer, sich um Betroffene zu kümmern. Viele gleiten wieder …",
			// 				2, "Lorem ipsum dolor sit amet",
			// 				3, "Tagesticket",
			// 				4, new DateTime.now_local(),
			// 				5, 24 * 60,
			// 				-1
			// 			   );
            //
			// this.latest.append(out iter);
			// this.latest.set(iter, 
			// 				0, pixbuf1.scale_simple(96, 96, Gdk.InterpType.BILINEAR),
			// 				1, "<b>Peter, Peter, Fußabtreter</b>\n<small><b>True Klein Crime - der Kurzgeschichten-Podcast mit Willy Nachdenklich</b></small>\n",
			// 				2, "Lorem ipsum dolor sit amet",
			// 				3, "Tagesticket",
			// 				4, new DateTime.now_local(),
			// 				5, 24 * 60,
			// 				-1
			// 			   );
            //


		}



		protected override void startup() {

			Gtk.TreeIter iter;
			Gdk.Pixbuf pixbuf1, pixbuf2, pixbuf3;

			base.startup();

			try {
				var db = new Database();
				this.subscriptions = db.getAllSubscriptions();
				
				foreach (Subscription subscription in this.subscriptions) {

					subscription.dump();

					// var pixbuf = new Gdk.Pixbuf.from_file_at_size("/home/hannenz/Downloads/90b94565-0091-46e2-9b1b-52b53e1eb051.png.jpeg", 200, 200);
					this.library.append(out iter);
					this.library.set(iter,
									 0, subscription.title, 
									 1, truncate(subscription.title, 200),
									 2, null,
									 3, subscription.pos
									 -1);
					subscription.iter = iter;
					subscription.changed.connect( (sub) => {
						this.library.set(sub.iter,
								0, sub.title,
								1, truncate(sub.title, 200),
								2, sub.cover,
								3, sub.pos
								);
						this.db.saveSubscription(sub);
					});
				}
			}
			catch (Error e) {
				stdout.printf(e.message);
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



			// var db = new Database();
			// var sbscr = db.getSubscriptionByGuid("7441a641-990e-531e-a474-d3f5ddc66baf");
			// if (sbscr != null) {
			// 	sbscr.dump();
			// }
			// return;



			foreach (Subscription subscription in this.subscriptions) {
				subscription.update();
			}
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
