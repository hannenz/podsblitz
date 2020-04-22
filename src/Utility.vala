namespace Podsblitz {

	// class Utility {
		

		/**
		 * Truncate a string to at most `len` characters. If the string is
		 * longer it will be truncated and `appendix` added to the end. The
		 * returned string is guaranteed to be max. `len` characters long
		 *
		 * @param string 	text
		 * @param int 		length
		 * @param string 	appendix, default: " …"
		 */
		public string truncate(string text, int len, string appendix = " …") {
			if (text.length < len) {
				return text;
			}

			var builder = new StringBuilder(text);
			builder.truncate(len - appendix.length);
			builder.append(appendix);
			return builder.str;
		}
	// }
}
