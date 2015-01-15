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
		// Add server definitions
		else {
			Servers.(section).location = inifile.(section).location
		}
	}
}

define connectDatabaseSync {
	with(connectRequest) {
		.host = "";
		.driver = "derby_embedded";
		.port = 0;
		.database = Config.databasedir + "sync";
		.username = "";
		.password = "";
		.attributes = "create=true"
	};
	connect@Database(connectRequest)()
}

define connectDatabaseLocal {
	with(connectRequest) {
		.host = "";
		.driver = "derby_embedded";
		.port = 0;
		.database = Config.databasedir + "local";
		.username = "";
		.password = "";
		.attributes = "create=true"
	};
	connect@Database(connectRequest)()
}

define setupDatabase {
	connectDatabaseSync;

	scope(CreateInstalled) {
		install(SQLException => nullProcess);

		update@Database("CREATE TABLE packages (
			name VARCHAR(128) NOT NULL UNIQUE,
			server VARCHAR(128) NOT NULL,
			version VARCHAR(64) NOT NULL
		)")()
	};

	scope(CreateDepends) {
		install(SQLException => nullProcess);

		update@Database("CREATE TABLE depends(
			name VARCHAR(128) NOT NULL,
			depends VARCHAR(128) NOT NULL
		)")()
	};

	connectDatabaseLocal;

	scope(CreateAvailable) {
		install(SQLException => nullProcess);

		update@Database("CREATE TABLE packages (
			name VARCHAR(128) NOT NULL,
			server VARCHAR(128) NOT NULL,
			version VARCHAR(64) NOT NULL
		)")()
	};

	scope(CreateDepends) {
		install(SQLException => nullProcess);

		update@Database("CREATE TABLE depends(
			name VARCHAR(128) NOT NULL,
			depends VARCHAR(128) NOT NULL
		)")()
	}
}

init {
	parseConfig;

	// Create missing directories
	mkdir@File(Config.datadir)();
	setupDatabase
}

main {
	/**
	 * Updates package database.
	 */
	[ update()(response) {
		// Clear database
		connectDatabaseSync;
		update@Database("DELETE FROM packages")();

		// Create temp file
		tempreq.prefix = "jpm";
		tempreq.suffix = ".tmp";
		createTempFile@FileUtils(tempreq)(tempfile);

		foreach(server : Servers) {
			response.(server).status = false;

			scope(UpdateServer) {
				install(IOException =>
					println@Console("Could not connect to ["+server+"]")()
				);
				install(TypeMismatch =>
					println@Console("Could not retrieve files from ["+server+"]")()
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
					query = "INSERT INTO packages VALUES (:name, :server, :version)";
					query.name = root.packages.list[i].name;
					query.server = server;
					query.version = root.packages.list[i].versions[#root.packages.list[i].versions-1];
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
	[ installPackages(request)(response) {
		// Add requested packages
		connectDatabaseSync;
		for(i = 0, i < #request.packages, i++) {
			// Find most recent package
			query@Database("SELECT * FROM packages WHERE name = '" + request.packages[i] + "'")(packages);
			if(#packages.row == 0) {
				throw(PackageNotFound)
			};

			download[i].name = packages.row[0].NAME;
			download[i].server = packages.row[0].SERVER;
			download[i].version = packages.row[0].VERSION
		};

		// Resolve dependencies

		// Install needed packages
		connectDatabaseLocal;
		for(i = 0, i < #download, i++) {
			package = download[i].name;
			println@Console("Installing: " + package)();
			response.(package).status = false;

			// Retrieve package specification
			WebGet.location = Servers.(download[i].server).location;

			// Download package
			pkgreq.name = download[i].name;
			pkgreq.version = download[i].version;
			getPackage@WebGet(pkgreq)(pkgdata);
			if(pkgdata == null) {
				println@Console("Could not download \"" + pkgreq.name + ".zip\"")();
				throw(PackageNotFound)
			};

			tempreq.prefix = "jpm";
			tempreq.suffix = ".zip";
			createTempFile@FileUtils(tempreq)(tempfile);

			writereq.content = pkgdata;
			writereq.filename = tempfile;
			writereq.format = "binary";
			writeFile@File(writereq)();

			// Unzip archive to data directory
			unzipreq.filename = tempfile;
			unzipreq.targetPath = Config.datadir;
			unzip@ZipUtils(unzipreq)();

			// Update database
			query@Database("SELECT * FROM packages WHERE name = '" + package + "'")(packages);
			if(#packages.row > 0) {
				query = "DELETE FROM packages WHERE name = :name";
				query.name = package;
				update@Database(query)()
			};
			query.name = download[i].name;
			query.server = download[i].server;
			query.version = download[i].version;
			query = "INSERT INTO packages VALUES (:name, :server, :version)";
			update@Database(query)();

			response.(package).status = true
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

		connectDatabaseSync;
		query = "SELECT * FROM packages WHERE name LIKE '%" + query + "%'";
		query@Database(query)(packages);
		for(i = 0, i < #packages.row, i++) {
			response.package[i].name = packages.row[i].NAME;
			response.package[i].server = packages.row[i].SERVER;
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

		connectDatabaseLocal;
		query@Database("SELECT * FROM packages WHERE name LIKE '%" + query + "%'")(packages);
		for(i = 0, i < #packages.row, i++) {
			response.package[i].name = packages.row[i].NAME;
			response.package[i].server = packages.row[i].SERVER;
			response.package[i].version = packages.row[i].VERSION
		}
	} ] { nullProcess }
}
