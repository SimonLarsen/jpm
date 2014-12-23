include "console.iol"
include "client.iol"
include "database.iol"
include "environment.iol"
include "ini_utils.iol"

inputPort Input {
	Location: "local"
	Interfaces: ClientInterface
}

execution { sequential }

define createDatabase {
	scope(CreateInstalled) {
		install(SQLException => nullProcess );

		update@Database("create table INSTALLED (
			NAME varchar(128) not null unique,
			VERSION varchar(64) not null
		)")()
	};

	undef(query)
}

define connectDatabase {
	with(connectRequest) {
		.host = "";
		.driver = "derby_embedded";
		.port = 0;
		.database = ENV_HOME + "/.jpm/db";
		.username = "";
		.password = "";
		.attributes = "create=true"
	};
	connect@Database(connectRequest)();
	undef(connectRequest);

	createDatabase
}

define parseConfig {
	parseIniFile@IniUtils(ENV_HOME + "/.jpm/rc.ini")(inifile);

	foreach(section : inifile) {
		if(section != "options") {
			Servers.(section).Location = inifile.(section).Location
		}
	};

	undef(inifile)
}

init {
	getVariable@Environment("HOME")(ENV_HOME);
	parseConfig;
	connectDatabase
}

main {
	[ installPackages(request)() {
		for(i = 0, i < #request.packages, i++) {
			package = request.packages[i];
			println@Console("Installing " + package)();

			query = "insert into INSTALLED values (:package, :version)";
			query.package = package;
			query.version = "1.0";
			update@Database(query)()
		}
	} ] { nullProcess }

	[ listInstalledPackages()(response) {
		query@Database("select * from INSTALLED")(packages);
		for(i = 0, i < #packages, i++) {
			println@Console(packages[i].NAME)();
			response[i].name = packages[i].NAME
		}
	} ] { nullProcess }

	[ search(request)(response) {
		nullProcess
	} ] { nullProcess }
}
