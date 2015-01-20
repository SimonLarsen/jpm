include "server_interface.iol"
include "console.iol"
include "file_server.iol"
include "yaml_utils.iol"
include "connect_database.iol"
include "file.iol"
include "file_utils.iol"
include "runtime.iol"

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
		npkgs = 0;
		foreach(server : Servers) {
			scope(UpdateServer) {
				install(FileNotFound =>
					println@Console("Error synchronizing server ["+server+"]")()
				);

				getrootreq.server = server;
				getRootManifest@Server(getrootreq)(root);

				for(i = 0, i < #root.packages.list, i++) {
					nversions = #root.packages.list[i].versions.list;
					response.package[npkgs].name = root.packages.list[i].name;
					response.package[npkgs].server = server;
					response.package[npkgs].version = root.packages.list[i].versions.list[nversions-1];
					npkgs++
				};
				println@Console("Synchronized ["+server+"]")()
			}
		}
	} ] { nullProcess }

	[ getSpec(request)(response) {
		scope(GetSpec) {
			install(TypeMismatch =>
				throw(FileNotFound)
			);

			tempreq.prefix = "jpm";
			tempreq.suffix = ".yaml";
			createTempFile@FileUtils(tempreq)(tempfile);

			FileServer.location = Servers.(request.server).location;
			getfilereq.path = request.name + "-" + request.version + ".jpmspec";
			getFile@FileServer(getfilereq)(data);

			writereq.content = data;
			writereq.filename = tempfile;
			writeFile@File(writereq)();

			parse@YamlUtils(tempfile)(response)
		}
	} ] { nullProcess }

	[ getPackage(request)(response) {
		scope(GetPackage) {
			install(TypeMismatch =>
				throw(FileNotFound)
			);

			FileServer.location = Servers.(request.server).location;
			getfilereq.path = request.name + "-" + request.version + ".zip";
			getFile@FileServer(getfilereq)(response)
		}
	} ] { nullProcess }

	[ getRootManifest(request)(response) {
		scope(GetRootManifest) {
			install(TypeMismatch =>
				throw(FileNotFound)
			);

			tempreq.prefix = "jpm";
			tempreq.suffix = ".yaml";
			createTempFile@FileUtils(tempreq)(tempfile);

			FileServer.location = Servers.(request.server).location;
			getfilereq.path = "root.yaml";
			getFile@FileServer(getfilereq)(data);

			writereq.content = data;
			writereq.filename = tempfile;
			writeFile@File(writereq)();

			parse@YamlUtils(tempfile)(response)
		}
	} ] { nullProcess }
}
