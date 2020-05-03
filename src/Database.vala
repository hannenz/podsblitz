using Sqlite; 
using Gee;

public errordomain DatabaseError {
	OPEN_FAILED,
	QUERY_FAILED
}

namespace Podsblitz {

	public class Database : Object {

		public Sqlite.Database db;

		protected Sqlite.Statement statement;


		public Database() throws DatabaseError.OPEN_FAILED {

			int ret;
			var dbfile = "/home/hannenz/podsblitz/data/podsblitz.db";

			ret = Sqlite.Database.open(dbfile, out this.db);
			if (ret != Sqlite.OK) {
				throw new DatabaseError.OPEN_FAILED("Failed to open sqlite database at %s\n".printf(dbfile));
			}
		}



		/**
		 * Execute a query
		 *
		 * @param string query
		 * @return void
		 * @throws Error
		 */
		public void query(string query) throws DatabaseError.QUERY_FAILED {
			int ret;

			ret = this.db.prepare_v2(query, query.length, out statement);
			if (ret != Sqlite.OK) {
				throw new DatabaseError.QUERY_FAILED("Error: %d: %s\n".printf(db.errcode(), db.errmsg()));
			}
		}



		public Gee.HashMap? getOne() {
			int cols, i;
			var result = new HashMap<string, string>();

			cols = statement.column_count();
			if (statement.step() == Sqlite.ROW) {

				for (i = 0; i < cols; i++) {

					string column_name = statement.column_name(i) ?? "<none>";
					int type = statement.column_type(i);


					switch (type) {
						case Sqlite.INTEGER:
							result.set(column_name, statement.column_int(i).to_string());
							break;

						case Sqlite.TEXT:
						default:
							result.set(column_name, statement.column_text(i));
							break;
					}
				}
			}
			else {
				return null;
			}

			return result;
		}
		

		public GLib.List<Gee.HashMap> getAll() {

			var results = new GLib.List<HashMap>();

			Gee.HashMap<string, string> result;
			while ((result = getOne()) != null) {
				results.append(result);
			}

			return results;
		}


		public void saveSubscription(Subscription subscription) {

		}
	}
}
