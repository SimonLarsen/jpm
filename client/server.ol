include "runtime.iol"
include "console.iol"
include "file.iol"
include "file_utils.iol"
include "string_utils.iol"
include "version_utils.iol"
include "server_interface.iol"
include "environment.iol"
include "ini_utils.iol"
include "yaml_utils.iol"

include "http_server.iol"
include "https_server.iol"
include "sodep_server.iol"

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
		}
		else if(parts.result[0] == "https") {
			Servers.(server).location = "socket://" + parts.result[1];
			Servers.(server).protocol = "https"
		}
		else if(parts.result[0] == "sodep") {
			Servers.(server).location = "socket://" + parts.result[1];
			Servers.(server).protocol = "sodep"
		}
		else {
			println@Console("Server ["+server+"] unusable. Unsupported protocol "+parts.result[0])()
		}
	}
}

init {
	getLocalLocation@Runtime()(Server.location);
	parseServers;

	// Make local pointer to output port locations
	HTTPServer.location -> http_location;
	HTTPSServer.location -> https_location;
	SodepServer.location -> sodep_location
}

main {
	[ getPackageList()(response) {
		foreach(server : Servers) {
			scope(UpdateServer) {
				install(ServerFault =>
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
			install(default => throw(ServerFault));

			server = request.server;
			protocol = Servers.(server).protocol;
			location = Servers.(server).location;
			undef(request.server);

			if(protocol == "http") {
				http_location = location;
				getSpec@HTTPServer(request)(spec)
			}
			else if(protocol == "sodep") {
				sodep_location = location;
				getSpec@SodepServer(request)(spec)
			};

			tempreq.prefix = "jpm";
			tempreq.suffix = ".yaml";
			createTempFile@FileUtils(tempreq)(tempfile);

			writefilereq.content = spec;
			writefilereq.filename = tempfile;
			writeFile@File(writefilereq)();

			parse@YamlUtils(tempfile)(response)
		}
	} ] { nullProcess }

	[ getPackage(request)(response) {
		scope(GetPackage) {
			install(default => throw(ServerFault));

			server = request.server;
			protocol = Servers.(server).protocol;
			location = Servers.(server).location;
			undef(request.server);

			if(protocol == "http") {
				http_location = location;
				getPackage@HTTPServer(request)(response)
			}
			else if(protocol == "sodep") {
				sodep_location = location;
				getPackage@SodepServer(request)(response)
			}
		}
	} ] { nullProcess }

	[ getRootManifest(request)(response) {
		scope(GetRootManifest) {
			install(default => throw(ServerFault));

			server = request.server;
			protocol = Servers.(server).protocol;
			location = Servers.(server).location;
			undef(request.server);

			if(protocol == "http") {
				http_location = location;
				getRootManifest@HTTPServer(request)(rootmanifest)
			}
			else if(protocol == "sodep") {
				sodep_location = location;
				getRootManifest@SodepServer(request)(rootmanifest)
			};

			tempreq.prefix = "jpm";
			tempreq.suffix = ".yaml";
			createTempFile@FileUtils(tempreq)(tempfile);

			writefilereq.content = rootmanifest;
			writefilereq.filename = tempfile;
			writeFile@File(writefilereq)();

			parse@YamlUtils(tempfile)(response)
		}
	} ] { nullProcess }
}
