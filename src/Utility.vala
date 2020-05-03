namespace Podsblitz {


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



	/**
	 * Parse a time string, e.g. duration which can be in the format "hh:mm:ss", "mm:ss", or "ss"
	 *
	 * @param string 		The string to be parsed
	 * @return int 			Number of seconds
	 */
	public int parse_time(string str) {
		int i, seconds = 0;
		var parts = str.split(":", 3);
		for (i = 0; i < parts.length; i++) {
			seconds *= 60;
			seconds += int.parse(parts[i]);
		}
		return seconds;
	}
}
