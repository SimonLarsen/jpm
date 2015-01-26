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
	println@Console("Running server on " + ServerLocation)()
}

main {
	[ getFile(request)(response) {
		scope(s) {
			install(FileNotFound =>
				println@Console("File not found: " + request.path)()
			);

			file.filename = ContentDirectory + request.path;
			getMimeType@File(file.filename)(mime);
			mime.regex = "/";
			split@StringUtils(mime)(s);
			if(s.result[0] == "text") {
				file.format = "text"
			} else {
				file.format = "binary"
			};

			readFile@File(file)(response)
		}
	} ] { nullProcess }
}
