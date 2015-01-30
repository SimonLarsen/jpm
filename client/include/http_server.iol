include "file_server_interface.iol"

outputPort HTTPServer {
	Protocol: http {
		.osc.getFile.alias = "%{path}";
		.osc.getSpec.alias = "%{name}-%{version}.jpmspec";
		.osc.getPackage.alias = "%{name}-%{version}.zip";
		.osc.getRootManifest.alias = "root.yaml"
	}
	Interfaces: FileServerInterface
}
