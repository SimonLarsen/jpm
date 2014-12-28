include "console.iol"
include "client.iol"
include "database.iol"
include "environment.iol"
include "ini_utils.iol"
include "webget.iol"
include "zip_utils.iol"
include "file.iol"
include "file_utils.iol"

include "client_install.ol"

inputPort Input {
	Location: "local"
	Interfaces: ClientInterface
}

execution { single }

define parseConfig {
	getVariable@Environment("HOME")(ENV_HOME);
	parseIniFile@IniUtils(ENV_HOME + "/.jpm/rc.ini")(inifile);

	// Setup defaults
	Config.DatabaseDir = ENV_HOME + "/.jpm/db";
	Config.DataDir = ENV_HOME + "/.jpm/data";
	Config.SpecDir = ENV_HOME + "/.jpm/specs";

	foreach(section : inifile) {
		// Parse options
		if(section == "options") {
			// DataDir = [path]
			if(inifile.options.DataDir != null) {
				Config.DataDir = inifile.options.DataDir
			}
		}
		// Add server definitions
		else {
			Servers.(section).Location = inifile.(section).Location
		}
	}
}

define connectDatabase {
	with(connectRequest) {
		.host = "";
		.driver = "derby_embedded";
		.port = 0;
		.database = Config.DatabaseDir;
		.username = "";
		.password = "";
		.attributes = "create=true"
	};
	connect@Database(connectRequest)();

	// IF EXISTS is not implemented in Derby. Catch exeception instead
	scope(CreateInstall) {
		install(SQLException => nullProcess);

		update@Database("CREATE TABLE installed (
			name VARCHAR(128) NOT NULL UNIQUE,
			version VARCHAR(64) NOT NULL
		)")()
	}
}

init {
	parseConfig;

	// Create missing directories
	mkdir@File(Config.DataDir)();
	mkdir@File(Config.SpecDir)();
	connectDatabase
}

main {
	[ installPackages(request)() {
		clientInstallPackages
	} ] { nullProcess }

	[ list()(response) {
		query@Database("SELECT * FROM installed")(packages);
		for(i = 0, i < #packages.row, i++) {
			response.package[i].name = packages.row[i].NAME;
			response.package[i].version = packages.row[i].VERSION
		}
	} ] { nullProcess }

	[ search(pattern)(response) {
		q = "SELECT * FROM installed WHERE name LIKE '%" + pattern + "%'";
		q.pattern = request;
		query@Database(q)(packages);
		for(i = 0, i < #packages.row, i++) {
			response.package[i].name = packages.row[i].NAME;
			response.package[i].version = packages.row[i].VERSION
		}
	} ] { nullProcess }
}
