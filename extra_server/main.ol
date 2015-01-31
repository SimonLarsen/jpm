include "console.iol"
include "string_utils.iol"
include "file.iol"
include "file_server_interface.iol"

constants {
	ContentDirectory = "www/",
	ServerLocation = "socket://localhost:8001"
}

execution { concurrent }

inputPort Input {
	Location: ServerLocation
	Protocol: sodep
	Interfaces: FileServerInterface
}

init {
	println@Console("Running SODEP server on " + ServerLocation)()
}

main {
	[ getSpec(request)(response) {
		file.filename = ContentDirectory+request.name+"-"+request.version+".jpmspec";
		file.format = "text";
		readFile@File(file)(response)
	} ] { nullProcess }

	[ getPackage(request)(response) {
		file.filename = ContentDirectory+request.name+"-"+request.version+".zip";
		file.format = "binary";
		readFile@File(file)(response)
	} ] { nullProcess }

	[ getRootManifest()(response) {
		file.filename = ContentDirectory + "root.yaml";
		file.format = "text";
		readFile@File(file)(response)
	} ] { nullProcess }
}
