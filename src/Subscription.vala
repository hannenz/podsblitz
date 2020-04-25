namespace Podsblitz {

	public class Subscription {

		public int id { get; set; }
		public string title { get; set; }
		public string description { get; set; }
		public string url { get; set; }

		public int pos;

		protected uint8[] xml;

		protected List<Episode> episodes;

		public Gdk.Pixbuf cover; 				// Original size
		public Gdk.Pixbuf cover_large; 			// 300px
		public Gdk.Pixbuf cover_medium; 		// 150px
		public Gdk.Pixbuf cover_small; 			// 90px

		public Gtk.TreeIter iter; 				// Iter referencing this subscription inside the Model (IconView)

		protected Database db;

		private bool isItem;


		public signal void changed(Subscription subscription);


		public Subscription() {

			this.episodes = new List<Episode>();

			try {
				this.db = new Database();
			}
			catch (DatabaseError.OPEN_FAILED e) {
				stderr.printf("%s\n", e.message);
				return;
			}
		}

		public Subscription.from_hash_map(Gee.HashMap<string, string> map) {
			title = map["title"];
			description = map["description"];
			url = map["url"];
			uint8[] buffer;

			try {
				buffer = Base64.decode(map["cover"]);
				var istream = new MemoryInputStream.from_data(buffer, GLib.free);
				cover = new Gdk.Pixbuf.from_stream(istream, null);
				cover_large = new Gdk.Pixbuf.from_stream_at_scale(istream, Podsblitz.CoverSize.LARGE, -1, true, null);
				cover_medium = new Gdk.Pixbuf.from_stream_at_scale(istream, Podsblitz.CoverSize.MEDIUM, -1, true, null);
				cover_small = new Gdk.Pixbuf.from_stream_at_scale(istream, Podsblitz.CoverSize.SMALL, -1, true, null);
			}
			catch (Error e) {
				stderr.printf("Error: %s\n", e.message);
			}
		}


		/**
		 * Subscribe to a new podcast
		 *
		 * @param string
		 * @return bool
		 */
		public bool subscribe(string url) {
			return this.create(url);
		}


		public bool create(string url) {
			this.url = url;
			this.fetch();
			this.db.saveSubscription(this);
			return true;
		}


		/**
		 * Update a subscription from online
		 */
		public void fetch() {
			print("Fetching subscription data from XML at %s\n", this.url);

			print("Loading XML from %s\n", this.url);

			var file = GLib.File.new_for_uri(this.url); 

			file.load_contents_async.begin(null, (obj, res) => {
				try {
					uint8[] contents;
					string etag_out;

					file.load_contents_async.end(res, out contents, out etag_out);
					this.readXml((string)contents);
					// this.db.saveSubscription(this);
					this.changed(this);
				}
				catch (Error e) {
					stdout.printf("Failed to load %s: %s\n", this.url, e.message);
				}
			});
		}



		public void setCover(string coverfile) throws Error {
			this.cover_large = new Gdk.Pixbuf.from_file_at_size(coverfile, 200, 200);
			this.cover_small = new Gdk.Pixbuf.from_file_at_size(coverfile, 96, 96) ;
		}


		protected void readRss() {
		}


		protected void readXml(string xml) {
			Xml.Parser.init();
			Xml.Doc* doc = Xml.Parser.parse_memory((string)xml, xml.length);
			if (doc == null) {
				stdout.printf("[DOC] Failed to parse RSS Feed at %s\n", this.url);
			}

			var ctx = new Xml.XPath.Context(doc);
			if (ctx == null) {
				stdout.printf("[CTX] Failed to parse RSS Feed at %s\n", this.url);
			}

			this.title = this.getXPath(ctx, "/rss/channel/title");
			this.description = this.getXPath(ctx, "/rss/channel/description");
			var imageurl = this.getXPath(ctx, "/rss/channel/image/url");

			print("Found image at %s\n", imageurl);


			File imagefile = File.new_for_uri(imageurl);
			print("Loading file\n");

			imagefile.load_contents_async.begin(null, (obj, res) => {
				try {
					uint8[] contents;
					string etag_out;
					imagefile.load_contents_async.end(res, out contents, out etag_out);
					InputStream istream= new MemoryInputStream.from_data(contents, GLib.free);
					this.cover = new Gdk.Pixbuf.from_stream_at_scale(istream, 300, -1, true, null);
					this.changed(this);
				}
				catch (Error e) {
					print("Error: %s\n", e.message);
				}
			});

			// this.changed(this);


			// Fetch episodes

			getXPath(ctx, "/item");

			var root_element = doc->get_root_element();
			parse_node(root_element);
		}



		private void parse_node(Xml.Node *node) {

			this.isItem = false;

			for (Xml.Node *iter = node->children; iter != null; iter = iter->next) {

				if (iter->type != Xml.ElementType.ELEMENT_NODE) {
					continue;
				}

				if (iter->name == "item") {

					print("Found episode:\n");

					var episode = new Episode.from_xml_node(iter);
					this.episodes.append(episode);
					episode.dump();
				}

				parse_node(iter);
			}
		}



		protected string? getXPath(Xml.XPath.Context ctx, string xpath) {
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
			uint8[] buffer;

			try {

				this.cover.save_to_buffer(out buffer, "png");

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

			print("--- Subscription Dump ---\n");
			print("Title: %s\n", this.title);
			print("URL: %s\n", this.url);
			print("Description: %s\n", this.description);
			print("-------------------------\n");

			foreach (var episode in this.episodes) {
				episode.dump();
			}
		}
	}
}
