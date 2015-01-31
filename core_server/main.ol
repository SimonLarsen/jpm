include "console.iol"
include "file.iol"
include "string_utils.iol"
include "protocols/http.iol"

constants {
	ContentDirectory = "www/",
	ServerLocation = "socket://localhost:8000"
}

execution { concurrent }

interface HTTPInterface {
	RequestResponse:
		default(DefaultOperationHttpRequest)(undefined)
}

inputPort HTTPInput {
	Protocol: http {
		.keepAlive = true;
		.format -> format;
		.contentType -> mime;
		.default = "default"
	}
	Location: ServerLocation
	Interfaces: HTTPInterface
}

init {
	println@Console("Running HTTP server on " + ServerLocation)()
}

main
{
	[ default(request)(response) {
		scope(s) {
			install(FileNotFound =>
				println@Console("File not found: " + file.filename)()
			);

			s = request.operation;
			s.regex = "\\?";
			split@StringUtils(s)(s);
			
			file.filename = ContentDirectory + s.result[0];

			getMimeType@File(file.filename)(mime);
			mime.regex = "/";
			split@StringUtils(mime)(s);
			if (s.result[0] == "text") {
				file.format = "text";
				format = "html"
			} else {
				file.format = format = "binary"
			};

			readFile@File(file)(response)
		}
	} ] { nullProcess }
}
