include "runtime.iol"
include "console.iol"
include "file.iol"
include "file_utils.iol"
include "yaml_utils.iol"
include "string_utils.iol"
include "version_utils.iol"
include "http_server.iol"
include "server_interface.iol"
include "connect_database.iol"

execution { concurrent }

outputPort Server {
	Interfaces: ServerInterface
}

inputPort Client {
	Location: "local"
	Interfaces: ServerInterface
}

define parseServers {
	getVariable@Environment("HOME")(ENV_HOME);
	parseIniFile@IniUtils(ENV_HOME + "/.jpm/servers.ini")(inifile);

	splitreq.regex = "://";
	foreach(server : inifile) {
		splitreq = inifile.(server).location;
		split@StringUtils(splitreq)(parts);
		if(parts.result[0] == "http") {
			Servers.(server).location = "socket://" + parts.result[1];
			Servers.(server).protocol = "http"
		} else {
			println@Console("Server ["+server+"] unusable. Unsupported protocol "+parts.result[0])()
		}
	}
}

init {
	getLocalLocation@Runtime()(Server.location);
	parseConfig;
	parseServers;

	// Make local pointer to output port locations
	HTTPServer.location -> http_location
}

main {
	[ getPackageList()(response) {
		foreach(server : Servers) {
			scope(UpdateServer) {
				install(FileNotFound =>
					println@Console("Error synchronizing server ["+server+"]")()
				);

				getrootreq.server = server;
				getRootManifest@Server(getrootreq)(root);

				for(i = 0, i < #root.packages.list, i++) {
					nversions = #root.packages.list[i].versions.list;
					name = root.packages.list[i].name;
					version = root.packages.list[i].versions.list[nversions-1];

					// Check if newer than existing version
					if(response.(name).version != null) {
						comparereq.a = version;
						comparereq.b = response.(name).version;
						compare@VersionUtils(comparereq)(compareres);
						if(compareres > 0) {
							response.(name).server = server;
							response.(name).version = version
						}
					}
					else {
						response.(name).name = name;
						response.(name).server = server;
						response.(name).version = version
					}
				};
				println@Console("Synchronized ["+server+"]")()
			}
		}
	} ] { nullProcess }

	[ getSpec(request)(response) {
		scope(GetSpec) {
			tempreq.prefix = "jpm";
			tempreq.suffix = ".yaml";
			createTempFile@FileUtils(tempreq)(tempfile);

			getfilereq.path = request.name+"-"+request.version+".jpmspec";
			getfilereq.server = request.server;
			getFile@Server(getfilereq)(data);

			writereq.content = data;
			writereq.filename = tempfile;
			writeFile@File(writereq)();

			parse@YamlUtils(tempfile)(response)
		}
	} ] { nullProcess }

	[ getPackage(request)(response) {
		getfilereq.path = request.name+"-"+request.version+".zip";
		getfilereq.server = request.server;
		getFile@Server(getfilereq)(response)
	} ] { nullProcess }

	[ getRootManifest(request)(response) {
		tempreq.prefix = "jpm";
		tempreq.suffix = ".yaml";
		createTempFile@FileUtils(tempreq)(tempfile);

		getfilereq.path = "root.yaml";
		getfilereq.server = request.server;
		getFile@Server(getfilereq)(data);

		writereq.content = data;
		writereq.filename = tempfile;
		writeFile@File(writereq)();

		parse@YamlUtils(tempfile)(response)
	} ] { nullProcess }

	[ getFile(request)(response) {
		install(TypeMismatch =>
			throw(FileNotFound)
		);

		if(Servers.(request.server).protocol == "http") {
			http_location = Servers.(request.server).location;
			getfilereq.path = request.path;
			getFile@HTTPServer(getfilereq)(response)
		}
	} ] { nullProcess }
}