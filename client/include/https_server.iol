include "file_server_interface.iol"

outputPort HTTPSServer {
	Protocol: https {
		.osc.getFile.alias = "%{path}"
	}
	Interfaces: FileServerInterface
}
