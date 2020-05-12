namespace Podsblitz {

	public class HeaderBar : Gtk.HeaderBar{

		public Podsblitz.MainWindow main_window { get; construct; }

		public Gtk.Button back_button;

		public signal void back_button_clicked();


		public HeaderBar(Podsblitz.MainWindow window) {
			Object(
				main_window: window
			);

			set_title("Podsblitz");
			set_subtitle("Listen to your podcasts");
			set_show_close_button(true);


			var stack_switcher = new Gtk.StackSwitcher();
			stack_switcher.set_stack(main_window.stack);
			stack_switcher.set_halign(Gtk.Align.CENTER);
			stack_switcher.set_valign(Gtk.Align.CENTER);

			set_custom_title(stack_switcher);

			back_button = new Gtk.Button.from_icon_name("go-previous-symbolic");
			back_button.clicked.connect( () => {
				back_button_clicked();
			});
			pack_start(back_button);
			back_button.set_sensitive(false);


			// var menu_button = new Gtk.Button.from_icon_name("open-menu", Gtk.IconSize.LARGE_TOOLBAR);
			// menu_button.valign = Gtk.Align.CENTER;
			// pack_end(menu_button);

		}
	}
}
