using Gtk;

public class Podsblitz.SubscriptionDetailHeader : Grid {

	public Gtk.Image image;
	public Gtk.TextView text_view;
	public Gtk.TextBuffer text_buffer;


	public SubscriptionDetailHeader() {

		column_homogeneous = true;
		row_homogeneous = false;
		column_spacing = 10;
		row_spacing = 0;
		var white = Gdk.RGBA();
		white.red = white.green = white.blue = white.alpha = 1.0;

		image = new Gtk.Image();
		text_buffer = new Gtk.TextBuffer(null);
		text_buffer.set_text("Platzhalter");
		text_view = new Gtk.TextView.with_buffer(text_buffer);
		text_view.set_wrap_mode(WrapMode.WORD_CHAR);
		text_view.set_cursor_visible(false);
		text_view.set_editable(false);

		attach(image, 0, 0, 4, 1);
		attach(text_view, 4, 0, 8, 1);

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
