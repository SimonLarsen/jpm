include "console.iol"
include "client.iol"
include "database.iol"
include "environment.iol"
include "ini_utils.iol"
include "yaml_utils.iol"
include "string_utils.iol"
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
	Config.databasedir = ENV_HOME + "/.jpm/db";
	Config.datadir = ENV_HOME + "/.jpm/data";

	foreach(section : inifile) {
		// Parse options
		if(section == "options") {
			// datadir = [path]
			if(inifile.options.datadir != null) {
				Config.datadir = inifile.options.datadir
			}
		}
		// Add server definitions
		else {
			Servers.(section).location = inifile.(section).location
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
	connect@Database(connectRequest)();

	// IF EXISTS is not implemented in Derby. Catch exeception instead
	scope(CreateInstalled) {
		install(SQLException => nullProcess);

		update@Database("CREATE TABLE installed (
			name VARCHAR(128) NOT NULL UNIQUE,
			version VARCHAR(64) NOT NULL
		)")()
	};

	scope(CreateAvailable) {
		install(SQLException => nullProcess);

		update@Database("CREATE TABLE available (
			server VARCHAR(128) NOT NULL,
			name VARCHAR(128) NOT NULL,
			version VARCHAR(64) NOT NULL
		)")()
	}
}

init {
	parseConfig;

	// Create missing directories
	mkdir@File(Config.datadir)();
	connectDatabase
}

main {
	/**
	 * Updates package database.
	 */
	[ update()(response) {
		// Clear database
		update@Database("DELETE FROM available")();

		// Create temp file
		tempreq.prefix = "jpm";
		tempreq.suffix = ".tmp";
		createTempFile@FileUtils(tempreq)(tempfile);

		foreach(server : Servers) {
			response.(server).status = false;

			scope(UpdateServer) {
				install(IOException =>
					println@Console("error: Could not connect to ["+server+"]")()
				);
				install(TypeMismatch =>
					println@Console("error: Could not retrieve files from ["+server+"]")()
				);

				println@Console("Updating ["+server+"]")();

				WebGet.location = Servers.(server).location;

				getRootManifest@WebGet()(data);
				writereq.content = data;
				writereq.filename = tempfile;
				writereq.format = "text";
				writeFile@File(writereq)();

				parse@YamlUtils(tempfile)(root);

				for(i = 0, i < #root.packages.list, i++) {
					query = "INSERT INTO available VALUES (:server, :name, :version)";
					query.server = server;
					query.name = root.packages.list[i].name;
					query.version = root.packages.list[i].version;
					update@Database(query)()
				};

				response.(server).status = true;
				response.(server).count = #root.packages.list
			}
		}
	} ] { nullProcess }

	/**
	 * Upgrades all installed packages to newest
	 * version that does not violate any dependencies.
	 */
	[ upgrade(void)(void) {
		println@Console("Upgrading packages")()
	} ] { nullProcess }

	/**
	 * Installs one or more packages.
	 */
	[ installPackages(request)() {
		for(i = 0, i < #request.packages, i++) {
			package = request.packages[i];
			println@Console("Installing: " + package)();

			// Retrieve package specification
			WebGet.location = Servers.core.location;

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
			parse@YamlUtils(Config.SpecDir + "/" + package + ".jpmspec")(spec);

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
	} ] { nullProcess }

	/**
	 * Returns all available packages that match a
	 * given query string.
	 */
	[ search(request)(response) {
		replacereq = request;
		replacereq.regex = "\\*";
		replacereq.replacement = "\\%";
		replaceAll@StringUtils(replacereq)(query);

		query = "SELECT * FROM available WHERE name LIKE '%" + query + "%'";
		query@Database(query)(packages);
		for(i = 0, i < #packages.row, i++) {
			response.package[i].server = packages.row[i].SERVER;
			response.package[i].name = packages.row[i].NAME;
			response.package[i].version = packages.row[i].VERSION
		}
	} ] { nullProcess }

	/**
	 * Lists all installed packages.
	 */
	[ list(request)(response) {
		replacereq = request;
		replacereq.regex = "\\*";
		replacereq.replacement = "\\%";
		replaceAll@StringUtils(replacereq)(query);

		query@Database("SELECT * FROM installed WHERE name LIKE '%" + query + "%'")(packages);
		for(i = 0, i < #packages.row, i++) {
			response.package[i].name = packages.row[i].NAME;
			response.package[i].version = packages.row[i].VERSION
		}
	} ] { nullProcess }
}
