include "database.iol"

define connectDatabase {
	with(connectRequest) {
		.host = "";
		.driver = "derby_embedded";
		.port = 0;
		.database = Config.databasedir;
		.username = "";
		.password = "";
		.attributes = "create=true"
	};
	connect@Database(connectRequest)();
	undef(connectRequest)
}
