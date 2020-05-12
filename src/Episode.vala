namespace Podsblitz {

	public class Episode {

		public int id { get; set; }
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


		public Episode.from_sql_row(Sqlite.Statement stmt) {
			read_sql_row(stmt);
		}


		public Episode.by_id(int id) {
			try {
				Sqlite.Statement stmt;

				this.db = new Database();

				const string query = "SELECT * FROM episodes WHERE id=$id";
				this.db.db.prepare_v2(query, query.length, out stmt, null);
				stmt.bind_int(stmt.bind_parameter_index("$id"), id);

				if (stmt.step() != Sqlite.ROW) {
					stderr.printf("Error: %s\n", this.db.db.errmsg());
					return;
				}

				read_sql_row(stmt);
			}
			catch (DatabaseError e) {
				stderr.printf("Database error: %s\n", e.message);
			}
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

					case "enclosure":
						debug("** FOUND ENCLOSURE **");
						Xml.Attr *attr;
						for (attr = item_iter->properties; attr != null; attr = attr->next) {
							if (attr->name == "url") {
								debug(attr->children->content);
								file = File.new_for_uri(attr->children->content);
								break;
							}
						}
						break;


				}
			}
		}


		/**
		 * Read properties from a Sqlite query result row
		 *
		 * @param Sqlite.Statement stmt
		 * @return void
		 */
		protected void read_sql_row(Sqlite.Statement stmt) {
			var cols = stmt.column_count();

			for (int i = 0; i < cols; i++) {

				var column_name = stmt.column_name(i);
				switch (column_name) {

					case "id":
						id = stmt.column_int(i);
						break;

					case "guid":
						guid = stmt.column_text(i);
						break;

					case "title":
						title = stmt.column_text(i);
						break;

					case "description":
						description = stmt.column_text(i);
						break;

					case "link":
						link = stmt.column_text(i);
						break;

					case "pubdate":
						pubdate = new DateTime.from_iso8601(stmt.column_text(i), new TimeZone.local());
						break;

					case "duration":
						duration = stmt.column_int(i);
						break;

					case "subscription_id":
						subscription_id = stmt.column_int(i);
						break;

					case "progress":
						progress = stmt.column_int(i);
						break;

					case "completed":
						completed = (bool)stmt.column_int(i);
						break;

					case "downloaded":
						downloaded = (bool)stmt.column_int(i);
						break;

					case "file":
						file = File.new_for_uri(stmt.column_text(i));
						break;
				}
			}
		}

		/**
		 * @param string guid
		 * @return Podsblitz.Episode
		 */ 
		public Episode.by_guid(string guid) {

			try {
				this.db = new Database();
				Sqlite.Statement stmt;

				const string query = "SELECT * FROM episodes WHERE guid=$guid";
				this.db.db.prepare_v2(query, query.length, out stmt, null);
				stmt.bind_text(stmt.bind_parameter_index("$guid"), guid);

				if (stmt.step() != Sqlite.ROW) {
					stderr.printf("Error: %s\n", this.db.db.errmsg());
					return;
				}

				read_sql_row(stmt);
			}
			catch (DatabaseError e) {
				stderr.printf("Database error: %s\n", e.message);
			}
		}


		public void save() {

			try {
				this.db = new Database();

				Sqlite.Statement stmt;

				// UPSERT: https://stackoverflow.com/a/38463024

				const string query1 = "UPDATE episodes SET guid=$guid, title=$title, description=$description, link=$link, pubdate=$pubdate, duration=$duration, subscription_id=$subscription_id, progress=$progress, completed=$completed, downloaded=$downloaded, file=$file WHERE id=$id";
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
				stmt.bind_int(stmt.bind_parameter_index("$id"), id);

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
			catch (Error e) {
				stderr.printf("%s\n", e.message);
			}
		}


		/**
		 * Return an appropriate image (cover) for the episode, most likely the
		 * cover of its subscription
		 *
		 * @param Podsblitz.CoverSize size
		 * @return Gdk.Pixbuf
		 */
		public Gdk.Pixbuf get_cover(CoverSize size = CoverSize.MEDIUM) {

			Gdk.Pixbuf cover;

			assert(subscription_id > 0);

			var subscription = new Subscription.by_id(subscription_id);

			switch (size) {

				case CoverSize.LARGE:
					cover = subscription.cover_large;
					break;

				case CoverSize.MEDIUM:
					cover = subscription.cover_medium;
					break;

				case CoverSize.SMALL:
				default:
					cover = subscription.cover_small;
					break;

			}

			assert(cover != null);
			return cover.copy();
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
			print("File: %s", file.get_uri());
		}
	}
}
