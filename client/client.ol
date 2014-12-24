include "console.iol"
include "client.iol"
include "database.iol"
include "environment.iol"
include "ini_utils.iol"

inputPort Input {
	Location: "local"
	Interfaces: ClientInterface
}

execution { single }

define connectDatabase {
	with(connectRequest) {
		.host = "";
		.driver = "derby_embedded";
		.port = 0;
		.database = "db";
		.username = "";
		.password = "";
		.attributes = "create=true"
	};
	connect@Database(connectRequest)();
	undef(connectRequest);

	// IF EXISTS is not implemented in Derby
	// Catch exception instead
	scope(CreateInstall) {
		install(SQLException => nullProcess);

		update@Database("CREATE TABLE installed (
			name VARCHAR(128) NOT NULL UNIQUE,
			version VARCHAR(64) NOT NULL
		)")()
	};
}

define parseConfig {
	parseIniFile@IniUtils(ENV_HOME + "/.jpm/rc.ini")(inifile);

	foreach(section : inifile) {
		if(section != "options") {
			Servers.(section).Location = inifile.(section).Location
		}
	}
}

init {
	println@Console("INIT")();
	getVariable@Environment("HOME")(ENV_HOME);
	parseConfig;
	connectDatabase
}

main {
	[ installPackages(request)() {
		for(i = 0, i < #request.packages, i++) {
			package = request.packages[i];
			println@Console("Installing " + package)();

			query = "INSERT INTO installed VALUES (:name, :version)";
			query.name = package;
			query.version = "NA";
			update@Database(query)()
		}
	} ] { nullProcess }

	[ list()(response) {
		query@Database("SELECT * FROM installed")(packages);
		for(i = 0, i < #packages.row, i++) {
			println@Console(packages.row[i].NAME)();
			response[i].name = packages.row[i].NAME;
			response[i].version = packages.row[i].VERSION
		}
	} ] { nullProcess }

	[ search(request)(response) {
		nullProcess
	} ] { nullProcess }
}
