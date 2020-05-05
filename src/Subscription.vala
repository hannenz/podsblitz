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

			noimage = new Gdk.Pixbuf.from_resource("/de/hannenz/podsblitz/img/noimage.png");
			this.episodes = new List<Episode>();

			try {
				this.db = new Database();
			}
			catch (DatabaseError e) {
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
			title = map["title"];
			description = map["description"];
			url = map["url"];
			uint8[] buffer;

			// debug("[%s]".printf(map["cover"].substring(0, 100)));

			
			cover = noimage;

			try {
				buffer = Base64.decode(map["cover"]);
				var istream = new MemoryInputStream.from_data(buffer, GLib.free);
				cover = new Gdk.Pixbuf.from_stream(istream, null);
			}
			catch (Error e) {
				stderr.printf("Failed to create pixbuf for cover: %s\n", e.message);
			}

			cover_large = cover.scale_simple(CoverSize.LARGE, CoverSize.LARGE, Gdk.InterpType.BILINEAR);
			cover_medium = cover.scale_simple(CoverSize.MEDIUM, CoverSize.MEDIUM, Gdk.InterpType.BILINEAR);
			cover_small = cover.scale_simple(CoverSize.SMALL, CoverSize.SMALL, Gdk.InterpType.BILINEAR);

			// Load episodes
			Sqlite.Statement stmt;

			const string query = "SELECT * FROM episodes WHERE subscription_id=$subscription_id";
			int ec = this.db.db.prepare_v2(query, query.length, out stmt);
			if (ec == Sqlite.OK) {
				stmt.bind_int(stmt.bind_parameter_index("$subscription_id"), id);

				while (stmt.step() == Sqlite.ROW) {
					var episode = new Episode.from_sql_row(stmt);
					episodes.append(episode);
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

			if (xml_doc != null) {
				return;
			}

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

			yield load_xml_async(); //.begin((obj, res) => {
				// load_xml_async.end(res);

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

			for (Xml.Node *iter = node->children; iter != null; iter = iter->next) {

				if (iter->type != Xml.ElementType.ELEMENT_NODE) {
					continue;
				}

				if (iter->name == "item") {

					// debug("Found episode:\n");

					var episode = new Episode.from_xml_node(iter);
					this.episodes.append(episode);
					// episode.dump();
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

			string query;
			uint8[] buffer = { 0 };

			try {

				if (this.cover != null) {
					this.cover.save_to_buffer(out buffer, "png");
				}

				// UPSERT: https://stackoverflow.com/a/38463024
				query = "UPDATE subscriptions  SET title='%s', description='%s', url='%s', pos=%u, cover='%s' WHERE url='%s'".printf(
					this.title,
					this.description,
					this.url,
					this.pos,
					Base64.encode(buffer),
					this.url
					);

				this.db.query(query);

				query = "INSERT INTO subscriptions (title, description, url, pos, cover) SELECT '%s', '%s', '%s', %u, '%s' WHERE (Select Changes() = 0)".printf(
					this.title,
					this.description,
					this.url,
					this.pos,
					Base64.encode(buffer)
					);

				this.db.query(query);
			}
			catch (DatabaseError.QUERY_FAILED e) {
				print("Database Error: %s\n", e.message);
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
