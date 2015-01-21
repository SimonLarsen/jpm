include "runtime.iol"
include "console.iol"
include "file.iol"
include "file_utils.iol"
include "yaml_utils.iol"
include "version_utils.iol"
include "file_server.iol"
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

	foreach(section : inifile) {
		Servers.(section).location = inifile.(section).location
	}
}

init {
	getLocalLocation@Runtime()(Server.location);
	parseConfig;
	parseServers
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

			FileServer.location = Servers.(request.server).location;
			getfilereq.path = request.name + "-" + request.version + ".jpmspec";
			getFile@FileServer(getfilereq)(data);
			if(data == null) {
				throw(FileNotFound)
			};

			writereq.content = data;
			writereq.filename = tempfile;
			writeFile@File(writereq)();

			parse@YamlUtils(tempfile)(response)
		}
	} ] { nullProcess }

	[ getPackage(request)(response) {
		scope(GetPackage) {
			FileServer.location = Servers.(request.server).location;
			getfilereq.path = request.name + "-" + request.version + ".zip";
			getFile@FileServer(getfilereq)(response);
			if(response == null) {
				throw(FileNotFound)
			}
		}
	} ] { nullProcess }

	[ getRootManifest(request)(response) {
		scope(GetRootManifest) {
			tempreq.prefix = "jpm";
			tempreq.suffix = ".yaml";
			createTempFile@FileUtils(tempreq)(tempfile);

			FileServer.location = Servers.(request.server).location;
			getfilereq.path = "root.yaml";
			getFile@FileServer(getfilereq)(data);
			if(data == null) {
				throw(FileNotFound)
			};

			writereq.content = data;
			writereq.filename = tempfile;
			writeFile@File(writereq)();

			parse@YamlUtils(tempfile)(response)
		}
	} ] { nullProcess }
}
