namespace Podsblitz {
	
	/**
	 * Custom cell renderer to display a formated date
	 * as seen here: https://stackoverflow.com/q/26827434
	 */
	public class CellRendererDate : Gtk.CellRendererText {

		string date_str = "- ? -";

		private DateTime _date;
		public DateTime date {
			get { return _date; }
			set {
				_date = value;
				if (value != null) {
					date_str = _date.format("%d.%m.%Y %H%:M");
					text = date_str;
				}
			}
		}

		public CellRendererDate() {
			GLib.Object();
		}

	}
}
