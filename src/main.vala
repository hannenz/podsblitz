/*
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation; either version 2 of the
 * License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, see <http://www.gnu.org/licenses/>.
 */
public static int main(string[] args) {

	debug("Podsblitz! We are running!");

	print("%s\n", args[1]);
	var episode = new Podsblitz.Episode.by_guid(args[1]);
	episode.dump();
	return 0;


	// var episode = new Podsblitz.Episode();
	// episode.guid = "HANS.FRANZ";
	// episode.title = "Lorem ipsum";
	// episode.description = "Cupidatat ex Ut in occaecat cillum id Lorem Duis occaecat nulla anim consequat irure non eiusmod laborum Lorem in occaecat Excepteur, qui minim ullamco aute cillum non dolor incididunt incididunt.";
	// episode.link = "http://www.example.com";
	// episode.pubdate = new DateTime.now_local();
	// episode.duration = 1234;
	// episode.subscription_id = 3;
	// episode.progress = 0;
	// episode.completed = false;
	// episode.downloaded = false;
	// episode.file = null;
	// // episode.dump();
	// episode.save();
	// return 0;


	var app = new Podsblitz.Application();
	return app.run(args);
}
