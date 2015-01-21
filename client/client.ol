include "console.iol"
include "client.iol"
include "string_utils.iol"
include "server.iol"
include "zip_utils.iol"
include "file.iol"
include "file_utils.iol"
include "connect_database.iol"

inputPort Input {
	Location: "local"
	Interfaces: ClientInterface
}

execution { sequential }

define setupDatabase {
	// Note: Derby does not support IF EXITS.
	// Must catch SQLExceptions instead.

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
		update@Database("CREATE TABLE depends (
			name VARCHAR(128) NOT NULL,
			version VARCHAR(64) NOT NULL,
			depends VARCHAR(128) NOT NULL,
			depversion VARCHAR(64) NOT NULL
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
		update@Database("CREATE TABLE depends (
			name VARCHAR(128) NOT NULL,
			version VARCHAR(64) NOT NULL,
			depends VARCHAR(128) NOT NULL,
			depversion VARCHAR(64) NOT NULL
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
		update@Database("DELETE FROM depends")();

		getPackageList@Server()(packages);

		foreach(name : packages) {
			query << packages.(name);
			query = "INSERT INTO packages VALUES (:name, :server, :version)";
			update@Database(query)();

			getSpec@Server(packages.(name))(spec);
			for(i = 0, i < #spec.depends.list, i++) {
				query.depends = spec.depends.list[i].list[0];
				query.depversion = spec.depends.list[i].list[1];

				query = "INSERT INTO depends VALUES (:name, :version, :depends, :depversion)";
				update@Database(query)()
			}

		}
	} ] { nullProcess }

	/**
	 * Upgrades all installed packages to newest
	 */
	[ upgrade(void)(void) {
		println@Console("Upgrading packages")()
	} ] { nullProcess }

	/**
	 * Installs one or more packages.
	 */
	[ installPackages(request)() {
		// Add requested packages
		connectDatabaseSync;
		for(i = 0, i < #request.packages, i++) {
			// Find most recent package
			query = "SELECT * FROM packages WHERE name = :name";
			query.name = request.packages[i];
			query@Database(query)(packages);
			if(#packages.row == 0) {
				throw(PackageNotFound)
			};

			download[i].name = packages.row[mostRecent].NAME;
			download[i].server = packages.row[mostRecent].SERVER;
			download[i].version = packages.row[mostRecent].VERSION
		};

		// Resolve dependencies

		// Install needed packages
		tempreq.prefix = "jpm";
		tempreq.suffix = ".zip";
		createTempFile@FileUtils(tempreq)(tempfile);

		connectDatabaseLocal;
		for(i = 0, i < #download, i++) {
			println@Console("Installing: " + download[i].name)();

			// Download package
			getPackage@Server(download)(pkgdata);
			if(pkgdata == null) {
				println@Console("Could not download \"" + pkgreq.name + ".zip\"")();
				throw(PackageNotFound)
			};

			writereq.content = pkgdata;
			writereq.filename = tempfile;
			writereq.format = "binary";
			writeFile@File(writereq)();

			// Unzip archive to data directory
			unzipreq.filename = tempfile;
			unzipreq.targetPath = Config.datadir;
			unzip@ZipUtils(unzipreq)();

			// Update database
			query = "SELECT * FROM packages WHERE name = :name";
			query.name = download[i].name;
			query@Database(query)(packages);
			if(#packages.row > 0) {
				query = "DELETE FROM packages WHERE name = :name";
				query.name = download[i].name;
				update@Database(query)()
			};

			query = "INSERT INTO packages VALUES (:name, :server, :version)";
			query.name = download[i].name;
			query.server = download[i].server;
			query.version = download[i].version;
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
		replaceAll@StringUtils(replacereq)(searchstr);

		connectDatabaseSync;
		query = "SELECT * FROM packages WHERE name LIKE :searchstr";
		query.searchstr = "%" + searchstr + "%";
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
		replaceAll@StringUtils(replacereq)(searchstr);

		connectDatabaseLocal;
		query = "SELECT * FROM packages WHERE name LIKE :searchstr";
		query.searchstr = "%" + searchstr + "%";
		query@Database(query)(packages);
		for(i = 0, i < #packages.row, i++) {
			response.package[i].name = packages.row[i].NAME;
			response.package[i].server = packages.row[i].SERVER;
			response.package[i].version = packages.row[i].VERSION
		}
	} ] { nullProcess }
}
