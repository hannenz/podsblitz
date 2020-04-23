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

	// var db = new Podsblitz.Database();
	// db.open();
    //
	// var subscription = new Podsblitz.Subscription();
    //
	// db.query("SELECT * FROM Subscriptions WHERE id=1");
	// Gee.HashMap<string,string> result = db.getOne();
    //
	// subscription.title = result["title"];
	// subscription.url = result["url"];
	// subscription.description = result["description"];
	// subscription.dump();
	// return 0;


	var app = new Podsblitz.PodsblitzApplication();
	return app.run(args);
}
