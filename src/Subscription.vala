namespace Podsblitz {

	public class Subscription : Object {

		public int id { get; set; }
		public string title { get; set; }
		public string description { get; set; }
		public string url { get; set; }

		public int pos;

		protected uint8[] xml;
		protected Xml.Doc *xml_doc { get; set; default = null; }

		protected List<Episode> episodes;

		public Gdk.Pixbuf cover; 				// Original size
		public Gdk.Pixbuf cover_large; 			// 300px
		public Gdk.Pixbuf cover_medium; 		// 150px
		public Gdk.Pixbuf cover_small; 			// 90px

		public Gtk.TreeIter iter; 				// Iter referencing this subscription inside the Model (IconView)

		protected Database db;

		private bool isItem;


		public signal void changed();


		public Subscription() {

			this.episodes = new List<Episode>();

			try {
				this.db = new Database();
			}
			catch (DatabaseError.OPEN_FAILED e) {
				stderr.printf("%s\n", e.message);
				return;
			}

			// When cover changes, automatically update / create diff. sizes
			this.notify["cover"].connect( (source, property) => {
				print("Updating cover size\n");
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

			id = int.parse(map["id"]);
			title = map["title"];
			description = map["description"];
			url = map["url"];
			uint8[] buffer;

			try {
				if (map["cover"] == "") {
					cover = new Gdk.Pixbuf.from_file_at_size("/home/hannenz/podsblitz/data/img/noimage.png", CoverSize.MEDIUM, CoverSize.MEDIUM);
				}
				else {
					buffer = Base64.decode(map["cover"]);
					var istream = new MemoryInputStream.from_data(buffer, GLib.free);
					cover = new Gdk.Pixbuf.from_stream_at_scale(istream, CoverSize.MEDIUM, CoverSize.MEDIUM, true, null);
				}


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


			// fetch_cover();
		}



		public async void fetch_cover_async() {

			yield load_xml_async(); // .begin((obj, res) => {
				// load_xml_async.end(res);

			var imageurl = get_xpath("/rss/channel/image/url");
			if (imageurl == null) {
				stderr.printf("No image url\n");
				return;
			}

			print("Loading image from %s\n", imageurl);

			File imagefile = File.new_for_uri(imageurl);

			uint8[] contents;
			string etag_out;
			try {
				yield imagefile.load_contents_async(null, out contents, out etag_out); //.begin(null, (obj, res) => {
			// imagefile.load_contents_async.callback(res, out contents, out etag_out);
				InputStream istream= new MemoryInputStream.from_data(contents, GLib.free);
				cover = new Gdk.Pixbuf.from_stream_at_scale(istream, CoverSize.MEDIUM, -1, true, null);
				print("Loaded image successfully from %s\n", imageurl);

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

					print("Found episode:\n");

					var episode = new Episode.from_xml_node(iter);
					this.episodes.append(episode);
					episode.dump();
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
			// print("Description: %s\n\n", description);

			foreach (var episode in episodes) {
				episode.dump();
			}
		}
	}
}
