namespace Podsblitz {

	public class Episode {

		public string guid { get; set; }
		public string title { get; set; }
		public string description { get; set; }
		public string link { get; set; }
		public int duration { get; set; }
		public int progress { get;  set; }
		public bool completed { get; set; }
		public DateTime pubdate { get; set; }
		public int subscription_id { get; set; }
		public bool downloaded { get; set; }
		public File file { get; set; }
		protected Database db;

		public Episode() {

		}



		public Episode.from_xml_node(Xml.Node *node) {
			for (Xml.Node *item_iter = node->children; item_iter != null; item_iter = item_iter->next) {

				if (item_iter->type != Xml.ElementType.ELEMENT_NODE) {
					continue;
				}

				switch (item_iter->name) {
					case "guid":
						guid = item_iter->get_content();
						break;

					case "title":
						title = item_iter->get_content();
						break;

					case "description":
						description = item_iter->get_content();
						break;

					case "link":
						link = item_iter->get_content();
						break;

					case "pubDate":
						var rfc2822_string = item_iter->get_content();

						// Is this really the way to go ?!?
						pubdate = new DateTime.from_iso8601(new Soup.Date.from_string(rfc2822_string).to_string(Soup.DateFormat.ISO8601), null);
						break;

					case "itunes:duration":
						 duration = parse_time(item_iter->get_content());
						break;

				}
			}
		}

		/*
		public void findByGuid(string guid) {

			try {
				Sqlite.Statement stmt;
				const string query = "SELECT * FROM episodes WHERE guid=$guid";
				this.db.db.prepare_v2(query, query.length, out stmt, null);
				stmt.bind_text(stmt.bind_parameter_index("$guid"), guid);
				var cols = stmt.column_count();
				if (stmt.step() != Sqlite.ROW) {
					stderr.printf("Error: %s\n", e.message);
				}
				for (var i = 0; i < cols; i++) {
					var column_name = stmt.column_name(i);
					switch (column_name) {
						case "guid"
				}



			}
			catch (DatabaseError e) {
				stderr.printf("Database error: %s\n", e.message);
			}
		}
*/


		public void save() {

			try {
				this.db = new Database();

				Sqlite.Statement stmt;

				// UPSERT: https://stackoverflow.com/a/38463024

				const string query1 = "UPDATE episodes SET guid=$guid, title=$title, description=$description, link=$link, pubdate=$pubdate, duration=$duration, subscription_id=$subscription_id, progress=$progress, completed=$completed, downloaded=$downloaded, file=$file WHERE guid=$guid";
				this.db.db.prepare_v2(query1, query1.length, out stmt, null);
				stmt.bind_text(stmt.bind_parameter_index("$guid"), guid);
				stmt.bind_text(stmt.bind_parameter_index("$title"), title);
				stmt.bind_text(stmt.bind_parameter_index("$description"), description);
				stmt.bind_text(stmt.bind_parameter_index("$link"), link);
				stmt.bind_text(stmt.bind_parameter_index("$pubdate"), pubdate != null ? pubdate.format("%Y-%m-%d %H:%M:%S") : "");
				stmt.bind_int(stmt.bind_parameter_index("$duration"), duration);
				stmt.bind_int(stmt.bind_parameter_index("$subscription_id"), subscription_id);
				stmt.bind_int(stmt.bind_parameter_index("$progress"), progress);
				stmt.bind_int(stmt.bind_parameter_index("$completed"), (int)completed);
				stmt.bind_int(stmt.bind_parameter_index("$downloaded"), (int)downloaded);
				stmt.bind_text(stmt.bind_parameter_index("$file"), file != null ? file.get_uri() : "");
				if (stmt.step() != Sqlite.DONE) {
					stderr.printf("Error: %s\n", this.db.db.errmsg());
				}
				const string query2 = "INSERT INTO episodes (guid, title, description, link, pubdate, duration, subscription_id, progress, completed, downloaded, file) SELECT $guid, $title, $description, $link, $pubdate, $duration, $subscription_id, $progress, $completed, $downloaded, $file WHERE (Select Changes() = 0)";

				this.db.db.prepare_v2(query2, query2.length, out stmt, null);
				stmt.bind_text(stmt.bind_parameter_index("$guid"), guid);
				stmt.bind_text(stmt.bind_parameter_index("$title"), title);
				stmt.bind_text(stmt.bind_parameter_index("$description"), description);
				stmt.bind_text(stmt.bind_parameter_index("$link"), link);
				stmt.bind_text(stmt.bind_parameter_index("$pubdate"), pubdate != null ? pubdate.format("%Y-%m-%d %H:%M:%S") : "");
				stmt.bind_int(stmt.bind_parameter_index("$duration"), duration);
				stmt.bind_int(stmt.bind_parameter_index("$subscription_id"), subscription_id);
				stmt.bind_int(stmt.bind_parameter_index("$progress"), progress);
				stmt.bind_int(stmt.bind_parameter_index("$completed"), (int)completed);
				stmt.bind_int(stmt.bind_parameter_index("$downloaded"), (int)downloaded);
				stmt.bind_text(stmt.bind_parameter_index("$file"), file != null ? file.get_uri() : "");
				if (stmt.step() != Sqlite.DONE) {
					stderr.printf("Error: %s\n", this.db.db.errmsg());
				}

				stmt.reset();
			}
			catch (DatabaseError e) {
				stderr.printf("Database error: %s\n", e.message);
			}
			catch (Error e) {
				stderr.printf("%s\n", e.message);
			}
		}

			

		public void dump() {
			print("Episode GUID: %s\n", guid);
			print("Title: %s\n", title);
			print("Link: %s\n", link);
			print("Description: %s\n", description);
			print("Duration: %u\n", duration);
			print("Progress: %u\n", progress);
			print("Completed: %s\n", completed ? "yes" : "no");
			print("Date: %s\n", pubdate.format("%d.%m.%Y %H:%M"));
		}
	}
}
