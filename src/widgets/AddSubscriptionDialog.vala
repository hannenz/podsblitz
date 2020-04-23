namespace Podsblitz {
	
	public class AddSubscriptionDialog : Gtk.Dialog {

		private Gtk.Entry url_entry;
		private Gtk.Widget primary_button;


		public AddSubscriptionDialog() {
			title = "Add Subscription";
			create_widgets();
			connect_signals();

			default_width = 400;
			default_height = 240;
		}


		private void create_widgets() {
			var content = this.get_content_area();
			var vbox = new Gtk.Box(Gtk.Orientation.VERTICAL,  20);

			var image = new Gtk.Image.from_file("/home/hannenz/podsblitz/data/icons/48.svg");
			image.halign = Gtk.Align.CENTER;

			var label = new Gtk.Label("URL");
			url_entry = new Gtk.Entry();
			url_entry.valign = Gtk.Align.CENTER;
			url_entry.halign = Gtk.Align.CENTER;

			vbox.pack_start(image, false, false);
			vbox.pack_start(label, false, true, 0);
			vbox.pack_start(url_entry, true, true, 0);

			content.pack_start(vbox);

			add_button(_("Cancel"), Gtk.ResponseType.CLOSE);
			this.primary_button = add_button(_("Add"), Gtk.ResponseType.APPLY);
			this.primary_button.sensitive = false;

			show_all();
		}


		private void connect_signals() {
			GLib.Regex exp = /(http[s]?:\/\/)?[^\s([\"<,>]*\.[^\s[",><]*/;

			this.url_entry.changed.connect( () => {
				this.primary_button.sensitive = (exp.match(this.url_entry.text));
			});
		}


		public string get_url() {
			return this.url_entry.text;
		}
	}
}
