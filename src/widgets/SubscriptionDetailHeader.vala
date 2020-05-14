using Gtk;

public class Podsblitz.SubscriptionDetailHeader : Grid {

	public Gtk.Image image;
	public Gtk.TextView text_view;
	public Gtk.TextBuffer text_buffer;
	public Gtk.Spinner spinner;
	public Gtk.Button update_btn;

	public signal void update_request();
	public signal void unsubscribe_request();

	public SubscriptionDetailHeader() {

		column_homogeneous = false;
		row_homogeneous = false;
		column_spacing = 10;
		row_spacing = 0;
		var white = Gdk.RGBA();
		white.red = white.green = white.blue = white.alpha = 1.0;

		image = new Gtk.Image();
		image.set_size_request(CoverSize.MEDIUM, CoverSize.MEDIUM);
		text_buffer = new Gtk.TextBuffer(null);
		text_buffer.set_text("Platzhalter");
		text_view = new Gtk.TextView.with_buffer(text_buffer);
		text_view.set_wrap_mode(WrapMode.WORD_CHAR);
		text_view.set_cursor_visible(false);
		text_view.set_editable(false);

		var swin = new ScrolledWindow(null, null);
		swin.hexpand = true;
		swin.add(text_view);

		attach(image, 0, 0, 1, 1);
		attach(swin, 1, 0, 3, 1);

		var action_bar = new Gtk.ActionBar();
		update_btn = new Gtk.Button.from_icon_name("view-refresh-symbolic", IconSize.BUTTON);
		update_btn.clicked.connect( () => {
			this.update_request();
		});
		action_bar.pack_start(update_btn);
		var unsubscribe_btn = new Gtk.Button.from_icon_name("user-trash-symbolic", IconSize.BUTTON);
		unsubscribe_btn.clicked.connect( () => {
			this.unsubscribe_request();
		});
		action_bar.pack_start(unsubscribe_btn);

		spinner = new Spinner();
		spinner.visible = false;
		action_bar.pack_start(spinner);


		attach(action_bar, 0, 1, 4, 1);

		show_all();
	}



	public void set_image(Gdk.Pixbuf pixbuf) {
		image.set_from_pixbuf(pixbuf);
	}



	public void set_text(string title, string description) {
		TextIter iter1, iter2;
		string text = "<big><b>%s</b></big>\n\n%s".printf(title, description);


		text_buffer.get_bounds(out iter1, out iter2);
		text_buffer.select_range(iter1, iter2);
		text_buffer.delete_selection(true, true);



		text_buffer.get_start_iter(out iter1);
		text_buffer.insert_markup(ref iter1, text, text.length );
	}
}
