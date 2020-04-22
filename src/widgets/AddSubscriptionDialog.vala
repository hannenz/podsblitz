namespace Podsblitz {
	
	public class AddSubscriptionDialog : Gtk.Dialog {

		private Gtk.Entry url_entry;
		private Gtk.Widget add_subscription_button;

		public AddSubscriptionDialog() {
			title = "Add Subscription";
			create_widgets();
			connect_signals();
		}


		private void create_widgets() {
			var content = this.get_content_area();

			var label = new Gtk.Label("URL");
			url_entry = new Gtk.Entry();
			var hbox = new Gtk.Box(Gtk.Orientation.HORIZONTAL,  20);
			hbox.pack_start(label, false, true, 0);
			hbox.pack_start(url_entry, true, true, 0);

			content.pack_start(hbox);


			add_button(Gtk.Stock.CLOSE, Gtk.ResponseType.CLOSE);
			this.add_subscription_button = add_button(Gtk.Stock.ADD, Gtk.ResponseType.APPLY);
			this.add_subscription_button.sensitive = false;

			show_all();
		}

		private void connect_signals() {
			this.url_entry.changed.connect( () => {
				this.add_subscription_button.sensitive = (this.url_entry.text != "");
			});
			// this.response.connect(on_response);
		}

		public string get_url() {
			return this.url_entry.text;
		}

	}
}
