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
	};
	undef(inifile)
}
