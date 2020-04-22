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
					string val = stmt.column_text(i) ?? "<none>";
					// int type_id  = stmt.column_type(i);

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

						case "guid":
							subscription.guid = stmt.column_text(i);
							break;

						case "cover":
							// subscription.cover = new Gdk.Pixbuf.from_bytes(
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

			uint8[] buffer;
			try {
				subscription.cover.save_to_buffer(out buffer, "png");
			}
			catch (Error e) {
				print("Error: %s\n", e.message);
			}

			string query = "INSERT INTO subscriptions (title, description, url, guid, pos, cover) VALUES ('%s', '%s', '%s', '%s', %u, '%s')".printf(
				subscription.title,
				subscription.description,
				subscription.url,
				subscription.guid,
				subscription.pos,
				(string)buffer
			);

			print("%s\n", query); 
			string error_message;
			int ret = this.db.exec(query, null, out error_message);
			if (ret != Sqlite.OK) {
				stderr.printf("Error: %s\n", error_message);
				return;
			}
		}


		public Subscription? getSubscriptionByGuid(string guid) {

			int ret;
			Sqlite.Statement stmt;
			print("CHECK\n");
			var subscription = new Subscription();

			string query = "SELECT * FROM subscriptions WHERE guid = '%s' LIMIT 1".printf(guid);
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
						case "guid":
							subscription.guid = val;
							break;

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
