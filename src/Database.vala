using Sqlite; 


namespace Podsblitz {

	public class Database : Object {

		protected Sqlite.Database db;


		public Database() {
			this.open();
		}


		public void open() {

			int ret;
			var dbfile = "/home/hannenz/podsblitz/data/podsblitz.db";

			ret = Sqlite.Database.open(dbfile, out this.db);
			if (ret != Sqlite.OK) {
				stdout.printf("Failed to open sqlite database at %s\n", dbfile);
				// throw new Error("Failed to open sqlite database at %s", dbfile);
			}
		}

		

		/**
		 * Get all subscriptions from database
		 *
		 * @return List<Podsblitz.Subscription>
		 */
		public List<Subscription> getAllSubscriptions() {

			var subscriptions = new List<Subscription>();

			int ret;
			Sqlite.Statement stmt;

			const string query = "SELECT * FROM subscriptions ORDER BY pos ASC";
			ret = this.db.prepare_v2(query, query.length, out stmt);
			if (ret != Sqlite.OK) {
				stderr.printf("Error: %d: %s\n", db.errcode(), db.errmsg());
				return subscriptions;
			}
			
			int cols = stmt.column_count();
			while (stmt.step() == Sqlite.ROW) {

				var subscription = new Subscription();

				for (int i = 0; i < cols; i++) {
					string col_name = stmt.column_name(i) ?? "<none>";

					switch (col_name) {
						case "title":
							subscription.title = stmt.column_text(i);
							break;

						case "url":
							subscription.url = stmt.column_text(i);
							break;

						case "description":
							subscription.description = stmt.column_text(i);
							break;

						case "pos":
							subscription.pos = stmt.column_int(i);
							break;

						case "cover":
							try {
								var base64encoded_data = stmt.column_text(i);
								InputStream istream = new MemoryInputStream.from_data(Base64.decode(base64encoded_data), GLib.free);
								subscription.cover = new Gdk.Pixbuf.from_stream_at_scale(istream, 150, -1, true, null);
							}
							catch (Error e) {
								print("Error: %s\n", e.message);
							}

							break;
					}

				}

				subscriptions.append(subscription);
				// subscription.dump();
			}
			stmt.reset();

			return subscriptions;
		}


		public void saveSubscription(Subscription subscription) {

			int ret;
			string query;
			string error_message;
			uint8[] buffer;

			try {
				subscription.cover.save_to_buffer(out buffer, "png");
			}
			catch (Error e) {
				print("Error: %s\n", e.message);
			}



			// UPSERT: https://stackoverflow.com/a/38463024
			query = "UPDATE subscriptions  SET title='%s', description='%s', url='%s', pos=%u, cover='%s' WHERE url='%s'".printf(
				subscription.title,
				subscription.description,
				subscription.url,
				subscription.pos,
				Base64.encode(buffer),
				subscription.url
			);

			ret = this.db.exec(query, null, out error_message);
			if (ret != Sqlite.OK) {
				stderr.printf("Error: %s\n", error_message);
				return;
			}

			query = "INSERT INTO subscriptions (title, description, url, pos, cover) SELECT '%s', '%s', '%s', %u, '%s' WHERE (Select Changes() = 0)".printf(
				subscription.title,
				subscription.description,
				subscription.url,
				subscription.pos,
				Base64.encode(buffer)
			);

			ret = this.db.exec(query, null, out error_message);
			if (ret != Sqlite.OK) {
				stderr.printf("Error: %s\n", error_message);
				return;
			}
		}


		public Subscription? getSubscriptionByUrl(string url) {

			int ret;
			Sqlite.Statement stmt;
			print("CHECK\n");
			var subscription = new Subscription();

			string query = "SELECT * FROM subscriptions WHERE url = '%s' LIMIT 1".printf(url);
			print(query);

			ret = this.db.prepare_v2(query, query.length, out stmt);
			if (ret != Sqlite.OK) {
				stderr.printf("Error: %d: %s\n", db.errcode(), db.errmsg());
				return null;
			}

			int cols = stmt.column_count();
			int rc = stmt.step();
			print("rc = %d\n", rc);
			if (rc == Sqlite.ROW) {

				for (int i = 0; i < cols; i++) {
					string col_name = stmt.column_name(i) ?? "<none>";
					string val = stmt.column_text(i) ?? "<none>";

					switch (col_name) {

						case "title":
							subscription.title = val;
							break;

						case "url":
							subscription.url = val;
							break;

						case "description":
							subscription.description = val;
							break;
					}

				}
			}

			return subscription;
		}
	}
}
