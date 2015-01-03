include "console.iol"
include "client.iol"
include "database.iol"
include "environment.iol"
include "ini_utils.iol"
include "yaml_utils.iol"
include "webget.iol"
include "zip_utils.iol"
include "file.iol"
include "file_utils.iol"

inputPort Input {
	Location: "local"
	Interfaces: ClientInterface
}

execution { sequential }

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

define clientInstallPackages {
	for(i = 0, i < #request.packages, i++) {
		package = request.packages[i];
		println@Console("Installing: " + package)();

		// Retrieve package specification
		WebGet.location = Servers.core.Location;

		specreq.name = package;
		getSpec@WebGet(specreq)(specdata);
		if(specdata == null) {
			println@Console("error: Package \"" + package + "\" not found")();
			throw(PackageNotFound)
		};

		// Write spec to file
		writereq.content = specdata;
		writereq.filename = Config.SpecDir + "/" + package + ".jpmspec";
		writereq.format = "text";
		writeFile@File(writereq)();

		// Parse spec file
		parseYamlFile@YamlUtils(Config.SpecDir + "/" + package + ".jpmspec")(spec);

		// Download package
		pkgreq.name = spec.name;
		pkgreq.version = spec.version;
		getPackage@WebGet(pkgreq)(pkgdata);
		if(pkgdata == null) {
			println@Console("error: Could not download \"" + pkgreq.name + ".zip\"")();
			throw(PackageNotFound)
		};

		tempreq.prefix = "jpm";
		tempreq.suffix = ".zip";
		createTempFile@FileUtils(tempreq)(tempfile);
		tempfile = "/home/simon/testfile.zip";
		println@Console("Created temp. file " + tempfile)();

		writereq.content = pkgdata;
		writereq.filename = tempfile;
		writereq.format = "binary";
		writeFile@File(writereq)();

		// Unzip archive to data directory
		unzipreq.filename = tempfile;
		unzipreq.targetPath = Config.DataDir;
		unzip@ZipUtils(unzipreq)();

		// Update database
		query = "INSERT INTO installed VALUES (:name, :version)";
		query.name = spec.name;
		query.version = spec.version;
		update@Database(query)()
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
}
