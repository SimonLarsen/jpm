define clientInstallPackages {
	for(i = 0, i < #request.packages, i++) {
		install(IOException =>
			println@Console("error: Could not get package " + request.packages[i])()
		);

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

		unzipreq.filename = tempfile;
		unzipreq.targetPath = Config.DataDir;
		unzip@ZipUtils(unzipreq)()
	}
}
