define clientInstallPackages {
	for(i = 0, i < #request.packages, i++) {
		package = request.packages[i];
		println@Console("Installing: " + package)();

		// Retrieve package specification
		WebGet.location = Servers.core.Location;

		specreq.name = package;
		getSpec@WebGet(specreq)(specdata);

		// Write spec to file
		writereq.content = specdata;
		writereq.filename = Config.SpecDir + "/" + package + ".jpmspec";
		writeFile@File(writereq)();

		// Parse spec file
		parseIniFile@IniUtils(Config.SpecDir + "/" + package + ".jpmspec")(spec);

		// Download package
		pkgreq.name = spec.Package.Name + "-" + spec.Package.Version;
		getPackage@WebGet(pkgreq)(pkgdata);

		tempreq.prefix = "jpm";
		tempreq.suffix = ".zip";
		createTempFile@FileUtils(tempreq)(tempfile);

		writereq.content = pkgdata;
		writereq.filename = tempfile;
		writeFile@File(writereq)();

		// Unzip archive to data directory
		unzipreq.filename = tempfile;
		unzipreq.targetPath = Config.DataDir;
		unzip@ZipUtils(unzipreq)();

		// Update database
		query = "INSERT INTO installed VALUES (:name, :version)";
		query.name = spec.Package.Name;
		query.version = spec.Package.Version;
		update@Database(query)()
	}
}
