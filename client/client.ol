include "console.iol"
include "client.iol"
include "string_utils.iol"
include "server.iol"
include "zip_utils.iol"
include "file.iol"
include "file_utils.iol"
include "connect_database.iol"
include "runtime.iol"

inputPort Input {
	Location: "local"
	Interfaces: ClientInterface
}

outputPort Client {
	Interfaces: ClientInterface
}

execution { concurrent }

define setupDatabase {
	connectDatabase;

	// Note: Derby does not support IF EXITS.
	// Must catch SQLExceptions instead.
	scope(CreateInstalled) {
		install(SQLException => nullProcess);
		update@Database("CREATE TABLE sync_packages (
			name VARCHAR(128) NOT NULL UNIQUE,
			server VARCHAR(128) NOT NULL,
			version VARCHAR(64) NOT NULL
		)")()
	};

	scope(CreateDepends) {
		install(SQLException => nullProcess);
		update@Database("CREATE TABLE sync_depends (
			name VARCHAR(128) NOT NULL,
			version VARCHAR(64) NOT NULL,
			depends VARCHAR(128) NOT NULL,
			depversion VARCHAR(64) NOT NULL
		)")()
	};

	scope(CreateAvailable) {
		install(SQLException => nullProcess);
		update@Database("CREATE TABLE local_packages (
			name VARCHAR(128) NOT NULL,
			server VARCHAR(128) NOT NULL,
			version VARCHAR(64) NOT NULL
		)")()
	};

	scope(CreateDepends) {
		install(SQLException => nullProcess);
		update@Database("CREATE TABLE local_depends (
			name VARCHAR(128) NOT NULL,
			version VARCHAR(64) NOT NULL,
			depends VARCHAR(128) NOT NULL,
			depversion VARCHAR(64) NOT NULL
		)")()
	}
}

init {
	getLocalLocation@Runtime()(Client.location);
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
		connectDatabase;
		update@Database("DELETE FROM sync_packages")();
		update@Database("DELETE FROM sync_depends")();

		getPackageList@Server()(packages);

		foreach(name : packages) {
			query << packages.(name);
			query = "INSERT INTO sync_packages VALUES (:name, :server, :version)";
			update@Database(query)();

			getSpec@Server(packages.(name))(spec);
			for(i = 0, i < #spec.depends.list, i++) {
				query.depends = spec.depends.list[i].list[0];
				query.depversion = spec.depends.list[i].list[1];

				query = "INSERT INTO sync_depends VALUES (:name, :version, :depends, :depversion)";
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
		connectDatabase;

		// Add requested packages
		for(i = 0, i < #request.packages, i++) {
			name = request.packages[i];
			query = "SELECT * FROM sync_packages WHERE name = :name";
			query.name = name;
			query@Database(query)(packages);
			if(#packages.row == 0) {
				println@Console("Package " + name + " not found")();
				throw(PackageNotFound)
			};

			download.(name).name = name;
			download.(name).server = packages.row[0].SERVER;
			download.(name).version = packages.row[0].VERSION
		};

		// Resolve dependencies

		// Download needed packages
		foreach(name : download) {
			// Download package
			println@Console("Installing: " + name + " " + download.(name).version)();
			downloadPackage@Client(download.(name))();

			// Update database
			query << download.(name);
			query = "SELECT * FROM local_packages WHERE name = :name";
			query@Database(query)(packages);
			if(#packages.row > 0) {
				query = "DELETE FROM local_packages WHERE name = :name";
				update@Database(query)()
			};

			query = "INSERT INTO local_packages VALUES (:name, :server, :version)";
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

		connectDatabase;
		query = "SELECT * FROM sync_packages
			WHERE name LIKE :searchstr ORDER BY server";
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

		connectDatabase;
		query = "SELECT * FROM local_packages
			WHERE name LIKE :searchstr ORDER BY server";
		query.searchstr = "%" + searchstr + "%";
		query@Database(query)(packages);
		for(i = 0, i < #packages.row, i++) {
			response.package[i].name = packages.row[i].NAME;
			response.package[i].server = packages.row[i].SERVER;
			response.package[i].version = packages.row[i].VERSION
		}
	} ] { nullProcess }

	[ downloadPackage(request)() {
		// Install needed packages
		tempreq.prefix = request.name;
		tempreq.suffix = ".zip";
		createTempFile@FileUtils(tempreq)(tempfile);

		getPackage@Server(request)(pkgdata);

		writereq.content = pkgdata;
		writereq.filename = tempfile;
		writereq.format = "binary";
		writeFile@File(writereq)();

		// Unzip archive to data directory
		unzipreq.filename = tempfile;
		unzipreq.targetPath = Config.datadir;
		unzip@ZipUtils(unzipreq)()
	} ] { nullProcess }
}
