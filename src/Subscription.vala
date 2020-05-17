namespace Podsblitz {

	public class Subscription : Object {

		public int id { get; set; }
		public string title { get; set; }
		public string description { get; set; }
		public string url { get; set; }

		public int pos;

		protected uint8[] xml;
		protected Xml.Doc *xml_doc { get; set; default = null; }

		public List<Episode> episodes;

		public Gdk.Pixbuf cover; 				// Original size
		public Gdk.Pixbuf cover_large; 			// 300px
		public Gdk.Pixbuf cover_medium; 		// 150px
		public Gdk.Pixbuf cover_small; 			// 90px
		private Gdk.Pixbuf noimage;

		public Gtk.TreeIter iter; 				// Iter referencing this subscription inside the Model (IconView)

		protected Database db;

		private bool isItem;


		public signal void changed();


		public Subscription() {

			this.episodes = new List<Episode>();

			try {
				this.db = new Database();
				noimage = null; //new Gdk.Pixbuf.from_resource("/de/hannenz/podsblitz/img/noimage.png");
			}
			catch (Error e) {
				stderr.printf("%s\n", e.message);
				return;
			}

			// When cover changes, automatically update / create diff. sizes
			this.notify["cover"].connect( (source, property) => {
				debug("Updating cover size\n");
				cover_large = cover.scale_simple(CoverSize.LARGE, CoverSize.LARGE, Gdk.InterpType.BILINEAR);
				cover_medium = cover.scale_simple(CoverSize.MEDIUM, CoverSize.MEDIUM, Gdk.InterpType.BILINEAR);
				cover_small = cover.scale_simple(CoverSize.SMALL, CoverSize.SMALL, Gdk.InterpType.BILINEAR);
			});

			Xml.Parser.init();
		}



		/**
		 * Constructor from HashMap
		 * When loading from db we get a HashMap
		 */
		public Subscription.from_hash_map(Gee.HashMap<string, string> map) {

			this();

			id = int.parse(map["id"]);
			title = map["subscription_title"];
			description = map["subscription_description"];
			url = map["subscription_url"];
			
			cover = noimage;

			// try {
			// 	var loader = new Gdk.PixbufLoader();
			// 	loader.write(Base64.decode(map["cover"]));
			// 	cover = loader.get_pixbuf();
			// 	loader.close();
			// }
			// catch (Error e) {
			// 	stderr.printf("Failed to create pixbuf for cover: %s\n", e.message);
			// }


			// cover_large = cover.scale_simple(CoverSize.LARGE, CoverSize.LARGE, Gdk.InterpType.BILINEAR);
			// cover_medium = cover.scale_simple(CoverSize.MEDIUM, CoverSize.MEDIUM, Gdk.InterpType.BILINEAR);
			// cover_small = cover.scale_simple(CoverSize.SMALL, CoverSize.SMALL, Gdk.InterpType.BILINEAR);

			// Load episodes
			Sqlite.Statement stmt;

			const string query = "SELECT * FROM episodes LEFT JOIN subscriptions ON episodes.episode_subscription_id=subscriptions.id WHERE episode_subscription_id=$subscription_id";
			int ec = this.db.db.prepare_v2(query, query.length, out stmt);
			if (ec == Sqlite.OK) {
				stmt.bind_int(stmt.bind_parameter_index("$subscription_id"), id);

				while (stmt.step() == Sqlite.ROW) {
					var episode = new Episode.from_sql_row(stmt);
					episodes.append(episode);
				}
			}
		}


		public Subscription.by_id(int id) {

			assert(id > 0);

			this();

			Sqlite.Statement stmt;

			const string query = "SELECT * FROM subscriptions WHERE id=$id";
			this.db.db.prepare_v2(query, query.length, out stmt, null);
			stmt.bind_int(stmt.bind_parameter_index("$id"), id);

			if (stmt.step() != Sqlite.ROW) {
				stderr.printf("Error: %s\n", this.db.db.errmsg());
				return;
			}

			read_sql_row(stmt);
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

					case "subscription_title":
						title = stmt.column_text(i);
						break;

					case "subscription_description":
						description = stmt.column_text(i);
						break;

					case "subscription_url":
						url = stmt.column_text(i);
						break;

					case "subscription_cover":
						cover = noimage;
						// try {
						// 	uint8[] buffer;
						// 	buffer = Base64.decode(stmt.column_text(i));
						// 	var istream = new MemoryInputStream.from_data(buffer, GLib.free);
						// 	cover = new Gdk.Pixbuf.from_stream(istream, null);
						// }
						// catch (Error e) {
						// 	stderr.printf("Failed to create pixbuf for cover: %s\n", e.message);
						// }
                        //
						// cover_large = cover.scale_simple(CoverSize.LARGE, CoverSize.LARGE, Gdk.InterpType.BILINEAR);
						// cover_medium = cover.scale_simple(CoverSize.MEDIUM, CoverSize.MEDIUM, Gdk.InterpType.BILINEAR);
						// cover_small = cover.scale_simple(CoverSize.SMALL, CoverSize.SMALL, Gdk.InterpType.BILINEAR);
						break;

					case "subscription_pos":
						pos = stmt.column_int(i);
						break;
				}
			}
		}



		/**
		 * Subscribe to a new podcast
		 *
		 * @param string
		 * @return bool
		 */
		public bool subscribe(string url) {
			this.url = url;
			fetch_async.begin( (obj, res) => {
				fetch_async.end(res);
				save();
			});
			return true;
		}



		/**
		 * Load XML from URI and parse, async.
		 */
		public async void load_xml_async() {

			// if (xml_doc != null) {
			// 	return;
			// }

			try {
				string etag_out;

				var file = File.new_for_uri(url);
				yield file.load_contents_async(null, out xml, out etag_out);

				xml_doc = Xml.Parser.parse_memory((string)xml, xml.length);
				if (xml_doc == null) {
					stderr.printf("[DOC] Failed to parse RSS Feed at %s\n", url);
				}
			}
			catch (Error e) {
				stderr.printf("Error: %s\n", e.message);
			}
		}



		/**
		 * Update a subscription from online, async.
		 */
		public async void fetch_async() {

			// "Push to background"
			Idle.add(fetch_async.callback);
			yield;

			string etag_out;
			var file = File.new_for_uri(url);
			yield file.load_contents_async(null, out xml, out etag_out);

			xml_doc = Xml.Parser.parse_memory((string)xml, xml.length);
			if (xml_doc == null) {
				stderr.printf("[DOC] Failed to parse RSS Feed at %s\n", url);
			}

			title = get_xpath("/rss/channel/title");
			description = get_xpath("/rss/channel/description");

			// Fetch episodes
			parse_node(xml_doc->get_root_element());
		}


		public async void fetch_cover_async() {

			yield load_xml_async(); // .begin((obj, res) => {
				// load_xml_async.end(res);

			var imageurl = get_xpath("/rss/channel/image/url");
			if (imageurl == null) {
				stderr.printf("No image url\n");
				return;
			}

			debug("Loading image from %s\n", imageurl);

			File imagefile = File.new_for_uri(imageurl);

			uint8[] contents;
			string etag_out;
			try {
				yield imagefile.load_contents_async(null, out contents, out etag_out); //.begin(null, (obj, res) => {
			// imagefile.load_contents_async.callback(res, out contents, out etag_out);
				InputStream istream= new MemoryInputStream.from_data(contents, GLib.free);

				cover = new Gdk.Pixbuf.from_stream(istream, null);
				cover_large = cover.scale_simple(CoverSize.LARGE, CoverSize.LARGE, Gdk.InterpType.BILINEAR);
				cover_medium = cover.scale_simple(CoverSize.MEDIUM, CoverSize.MEDIUM, Gdk.InterpType.BILINEAR);
				cover_small = cover.scale_simple(CoverSize.SMALL, CoverSize.SMALL, Gdk.InterpType.BILINEAR);

				debug("Loaded image successfully from %s\n", imageurl);

			}
			catch (Error e) {
				stderr.printf("Error loading image: %s\n", e.message);
			}
			// });
		}



		private void parse_node(Xml.Node *node) {

			this.isItem = false;
			int max = 5;

			for (Xml.Node *iter = node->children; iter != null; iter = iter->next) {

				if (iter->type != Xml.ElementType.ELEMENT_NODE) {
					continue;
				}

				if (iter->name == "item") {
					debug("Fetching an episode");
					var episode = new Episode.from_xml_node(iter);
					episode.subscription_id = this.id;
					this.episodes.insert_sorted(episode, (a, b) => {
						return b.pubdate.compare(a.pubdate);
					});

					if (--max < 0) {
						break;
					}
				}

				parse_node(iter);
			}
		}



		protected string? get_xpath(string xpath) {

			var ctx = new Xml.XPath.Context(xml_doc);
			if (ctx == null) {
				return null;
			}

			Xml.XPath.Object *obj = ctx.eval_expression(xpath);
			if (obj == null) {
				return null;
			}

			Xml.Node *node = null;
			if (obj->nodesetval != null && obj->nodesetval->item(0) != null) {
				node = obj->nodesetval->item(0);
			}

			return (node != null) ? node->get_content() : null;
		}



		public void save() {

			uint8[] buffer = { 0 };
			Sqlite.Statement stmt, stmt1, stmt2;

			try {
				debug("Saving subscription: %s, cover: %s", title, cover != null ? "not null" : "null");
				if (this.cover != null) {
					this.cover.save_to_buffer(out buffer, "png");
				}



				// To increase SQLite WRITE performance, we save all episodes in
				// one single transaction, and set some PRAGMAs
				int ec;
				string errmssg;

				// ec = this.db.db.exec("PRAGMA SYNCHRONOUS=OFF", null, out errmssg);
				// if (ec != Sqlite.OK) {
				// 	error(errmssg);
				// }
				// ec = this.db.db.exec("PRAGMA JOURNAL_MODE=MEMEORY", null, out errmssg);
				// if (ec != Sqlite.OK) {
				// 	error(errmssg);
				// }
				// ec = this.db.db.exec("PRAGMA TEMP_STORE=MEMEORY", null, out errmssg);
				// if (ec != Sqlite.OK) {
				// 	error(errmssg);
				// }
				// ec = this.db.db.exec("PRAGMA LOCKING_MODE=EXCLUSIVE", null, out errmssg);
				// if (ec != Sqlite.OK) {
				// 	error(errmssg);
				// }

				ec = this.db.db.exec("BEGIN TRANSACTION", null, out errmssg);
				if (ec != Sqlite.OK) {
					error(errmssg);
				}

				debug("### Saving Subscription ###");
				// UPSERT: https://stackoverflow.com/a/38463024
				const string query1 = "UPDATE subscriptions  SET subscription_title=$title, subscription_description=$description, subscription_url=$url, subscription_pos=$pos, subscription_cover=$cover WHERE id=$id";
				this.db.db.prepare_v2(query1, query1.length, out stmt, null);
				stmt.bind_text(stmt.bind_parameter_index("$title"), title);
				stmt.bind_text(stmt.bind_parameter_index("$description"), description);
				stmt.bind_text(stmt.bind_parameter_index("$url"), url);
				stmt.bind_int(stmt.bind_parameter_index("$pos"), pos);
				stmt.bind_text(stmt.bind_parameter_index("$cover"), Base64.encode(buffer));
				stmt.bind_int(stmt.bind_parameter_index("$id"), id);
				if (stmt.step() != Sqlite.DONE) {
					stderr.printf("Error: %s\n", this.db.db.errmsg());
				}

				const string query2 = "INSERT INTO subscriptions (subscription_title, subscription_description, subscription_url, subscription_pos, subscription_cover) SELECT $title, $descrition, $url, $pos, $cover WHERE (Select Changes() = 0)";
				this.db.db.prepare_v2(query2, query2.length, out stmt, null);
				stmt.bind_text(stmt.bind_parameter_index("$title"), title);
				stmt.bind_text(stmt.bind_parameter_index("$description"), description);
				stmt.bind_text(stmt.bind_parameter_index("$url"), url);
				stmt.bind_int(stmt.bind_parameter_index("$pos"), pos);
				stmt.bind_text(stmt.bind_parameter_index("$cover"), Base64.encode(buffer));
				if (stmt.step() != Sqlite.DONE) {
					stderr.printf("Error: %s\n", this.db.db.errmsg());
				}

				stmt.reset();

				debug("### Saving Episodes ###");

				const string query3 = "UPDATE episodes SET episode_guid=$guid, episode_title=$title, episode_description=$description, episode_link=$link, episode_pubdate=$pubdate, episode_duration=$duration, episode_subscription_id=$subscription_id, episode_progress=$progress, episode_completed=$completed, episode_downloaded=$downloaded, episode_file=$file WHERE id=$id";
				this.db.db.prepare_v2(query3, query3.length, out stmt1, null);
				const string query4 = "INSERT INTO episodes (episode_guid, episode_title, episode_description, episode_link, episode_pubdate, episode_duration, episode_subscription_id, episode_progress, episode_completed, episode_downloaded, episode_file) SELECT $guid, $title, $description, $link, $pubdate, $duration, $subscription_id, $progress, $completed, $downloaded, $file WHERE (Select Changes() = 0)";
				this.db.db.prepare_v2(query4, query4.length, out stmt2, null);

				foreach (var episode in episodes) {
					// episode.save();

					stmt1.bind_text(stmt1.bind_parameter_index("$guid"), episode.guid);
					stmt1.bind_text(stmt1.bind_parameter_index("$title"), episode.title);
					stmt1.bind_text(stmt1.bind_parameter_index("$description"), episode.description);
					stmt1.bind_text(stmt1.bind_parameter_index("$link"), episode.link);
					stmt1.bind_text(stmt1.bind_parameter_index("$pubdate"), episode.pubdate != null ? episode.pubdate.format("%Y-%m-%d %H:%M:%S") : "");
					stmt1.bind_int(stmt1.bind_parameter_index("$duration"), episode.duration);
					stmt1.bind_int(stmt1.bind_parameter_index("$subscription_id"), episode.subscription_id);
					stmt1.bind_int(stmt1.bind_parameter_index("$progress"), episode.progress);
					stmt1.bind_int(stmt1.bind_parameter_index("$completed"), (int)episode.completed);
					stmt1.bind_int(stmt1.bind_parameter_index("$downloaded"), (int)episode.downloaded);
					stmt1.bind_text(stmt1.bind_parameter_index("$file"), episode.file != null ? episode.file.get_uri() : "");
					stmt1.bind_int(stmt1.bind_parameter_index("$id"), episode.id);
					if (stmt1.step() != Sqlite.DONE) {
						stderr.printf("Error: %s\n", this.db.db.errmsg());
					}

					stmt2.bind_text(stmt2.bind_parameter_index("$guid"), episode.guid);
					stmt2.bind_text(stmt2.bind_parameter_index("$title"), episode.title);
					stmt2.bind_text(stmt2.bind_parameter_index("$description"), episode.description);
					stmt2.bind_text(stmt2.bind_parameter_index("$link"), episode.link);
					stmt2.bind_text(stmt2.bind_parameter_index("$pubdate"), episode.pubdate != null ? episode.pubdate.format("%Y-%m-%d %H:%M:%S") : "");
					stmt2.bind_int(stmt2.bind_parameter_index("$duration"), episode.duration);
					stmt2.bind_int(stmt2.bind_parameter_index("$subscription_id"), episode.subscription_id);
					stmt2.bind_int(stmt2.bind_parameter_index("$progress"), episode.progress);
					stmt2.bind_int(stmt2.bind_parameter_index("$completed"), (int)episode.completed);
					stmt2.bind_int(stmt2.bind_parameter_index("$downloaded"), (int)episode.downloaded);
					stmt2.bind_text(stmt2.bind_parameter_index("$file"), episode.file != null ? episode.file.get_uri() : "");
					if (stmt2.step() != Sqlite.DONE) {
						stderr.printf("Error: %s\n", this.db.db.errmsg());
					}

					stmt1.reset();
					stmt2.reset();
				}

				ec = this.db.db.exec("COMMIT TRANSACTION");
				if (ec != Sqlite.OK) {
					error(errmssg);
				}
			}
			catch (Error e) {
				print("Error: %s\n", e.message);
			}
		}



		public void dump() {

			print("\n");
			print("--- Subscription Dump ---\n");
			print("ID:          %u\n", id);
			print("Title:       %s\n", title);
			print("URL:         %s\n", url);
			print("Description: %s\n\n", description);

			foreach (var episode in episodes) {
				episode.dump();
			}
		}
	}
}
