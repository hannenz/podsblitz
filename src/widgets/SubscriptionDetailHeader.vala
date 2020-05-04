using Gtk;

public class Podsblitz.SubscriptionDetailHeader : Grid {

	public Gtk.Image image;
	public Gtk.Label title;
	public Gtk.Label description;


	public SubscriptionDetailHeader() {

		image = new Gtk.Image();
		title = new Gtk.Label("Platzhaler Titel");
		description = new Gtk.Label("Platzhalter Beschreibung");

		titl.set_line_wrap(true);
		description.set_line_wrap(true);

		attach(image, 0, 0, 4, 4);
		attach(title, 4, 0, 8, 1);
		attach(description, 4, 1, 8, 3);

		show_all();

	}

	public void set_image(Gdk.Pixbuf pixbuf) {
		image.set_from_pixbuf(pixbuf);
	}

	public void set_title(string title) {
		this.title.set_label(title);
		this.title.set_text(title);
	}

	public void set_description(string description) {
		this.description.set_label(description);
		this.description.set_text(description);
	}
}
