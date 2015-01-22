include "database.iol"
include "environment.iol"
include "ini_utils.iol"

define parseConfig {
	getVariable@Environment("HOME")(ENV_HOME);
	parseIniFile@IniUtils(ENV_HOME + "/.jpm/rc.ini")(inifile);

	// Setup defaults
	Config.databasedir = ENV_HOME + "/.jpm/db/";
	Config.datadir = ENV_HOME + "/.jpm/data/";

	foreach(section : inifile) {
		// Parse options
		if(section == "options") {
			// datadir = [path]
			if(inifile.options.datadir != null) {
				Config.datadir = inifile.options.datadir
			}
		}
	}
}

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
	connect@Database(connectRequest)()
}
