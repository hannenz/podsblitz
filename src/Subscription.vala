namespace Podsblitz {

	public class Subscription {

		public string guid { get; set; }
		public string title { get; set; }
		public string description { get; set; }

		protected string _url;
		public string url { 
			get { return _url; }
			set {
				this._url = value;
				// this.readRss();
			}
		}

		protected uint8[] xml;

		protected List<Episode> episodes;

		protected Gdk.Pixbuf cover_large;
		protected Gdk.Pixbuf cover_small;

		public Gtk.TreeIter iter; 		// Iter referencing this subscription inside the Model (IconView)



		public Subscription() {
			this.episodes = new List<Episode>();
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
			var db = new Database();
			db.saveSubscription(this);

			return true;
			
		}

		/**
		 * Update subscription and all episodes
		 *
		 * @return void
		 */
		public void update() {
			this.readRss();
		}


		public void setCover(string coverfile) throws Error {
			this.cover_large = new Gdk.Pixbuf.from_file_at_size(coverfile, 200, 200);
			this.cover_small = new Gdk.Pixbuf.from_file_at_size(coverfile, 96, 96) ;
		}


		protected async void readRss() {
			print("Loading XML from %s\n", this._url);

			var file = GLib.File.new_for_uri(this._url); 

			file.load_contents_async.begin(null, (obj, res) => {
				try {
					uint8[] contents;
					string etag_out;

					file.load_contents_async.end(res, out contents, out etag_out);
					this.readXml((string)contents);

				}
				catch (Error e) {
					stdout.printf("Failed to load %s: %s\n", this._url, e.message);
				}
			});
		}


		protected void readXml(string xml) {
			Xml.Parser.init();
			Xml.Doc* doc = Xml.Parser.parse_memory((string)xml, xml.length);
			if (doc == null) {
				// throw new GError("Failed to parse RSS Feed at " + this._url);
				stdout.printf("[DOC] Failed to parse RSS Feed at %s\n", this._url);
			}

			var ctx = new Xml.XPath.Context(doc);
			if (ctx == null) {
				// throw new GError("Failed to parse RSS Feed at " + this._url);
				stdout.printf("[CTX] Failed to parse RSS Feed at %s\n", this._url);
			}

			this.title = this.getXPath(ctx, "/rss/channel/title");
			this.description = this.getXPath(ctx, "/rss/channel/description");
			var imageurl = this.getXPath(ctx, "/rss/channel/image/url");



		}

		protected string getXPath(Xml.XPath.Context ctx, string xpath) {
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


		public void dump() {
			print("Subscription: %s\n", this.title);
			print("URL: %s\n", this.url);
			print("GUID: %s\n", this.guid);
			print("Description: %s\n", this.description);

			foreach (var episode in this.episodes) {
				episode.dump();
			}
		}
	}
}
