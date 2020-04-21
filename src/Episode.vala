namespace Podsblitz {

	public class Episode {

		public string title { get; set; }
		public string description { get; set; }
		public string url { get; set; }
		public int duration { get; set; }
		public int progress { get;  set; }
		public bool completed { get; set; }
		public DateTime pubdate { get; set; }

		public Episode() {


			
		}

		public void dump() {
			print("Episode: %s\n", this.title);
			print("URL: %s\n", this.url);
			print("Description: %s\n", this.description);
			print("Duration: %u\n", this.duration);
			print("Progress: %u\n", this.progress);
			print("Completed: %s\n", this.completed ? "yes" : "no");
			print("Date: %s\n", this.pubdate.format("%d.%m.%Y %H:%M"));
		}
	}
}
