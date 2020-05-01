namespace Podsblitz {

	public class Episode {

		public string guid { get; set; }
		public string title { get; set; }
		public string description { get; set; }
		public string url { get; set; }
		public int duration { get; set; }
		public int progress { get;  set; }
		public bool completed { get; set; }
		public DateTime pubdate { get; set; }

		public Episode() {

		}



		public Episode.from_xml_node(Xml.Node *node) {
			for (Xml.Node *item_iter = node->children; item_iter != null; item_iter = item_iter->next) {

				if (item_iter->type != Xml.ElementType.ELEMENT_NODE) {
					continue;
				}

				switch (item_iter->name) {
					case "guid":
						this.guid = item_iter->get_content();
						break;

					case "title":
						this.title = item_iter->get_content();
						break;

					case "link":
						this.url = item_iter->get_content();
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

			

		public void dump() {
			print("Episode GUID: %s\n", this.guid);
			print("Title: %s\n", this.title);
			print("URL: %s\n", this.url);
			print("Description: %s\n", this.description);
			print("Duration: %u\n", this.duration);
			print("Progress: %u\n", this.progress);
			print("Completed: %s\n", this.completed ? "yes" : "no");
			print("Date: %s\n", this.pubdate.format("%d.%m.%Y %H:%M"));
		}
	}
}
