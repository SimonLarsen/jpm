include "console.iol"
include "file.iol"
include "string_utils.iol"
include "protocols/http.iol"

constants {
	WebLocation = "socket://localhost:8000/",
	RootContentDirectory = "www/",
}

execution { concurrent }

interface WebInterface {
	RequestResponse:
		default(DefaultOperationHttpRequest)(undefined)
}

inputPort Input {
	Protocol: http {
		.keepAlive = true;
		.format -> format;
		.contentType -> mime;

		.default = "default"
	}
	Location: WebLocation
	Interfaces: WebInterface
}

init
{
	if ( is_defined( args[0] ) ) {
		documentRootDirectory = args[0]
	} else {
		documentRootDirectory = RootContentDirectory
	}
}

main
{
	[ default( request )( response ) {
		scope( s ) {
			install( FileNotFound => println@Console( "File not found: " + file.filename )() );

			s = request.operation;
			s.regex = "\\?";
			split@StringUtils( s )( s );
			
			// Default page
			if ( s.result[0] == "" ) {
				s.result[0] = DefaultPage
			};
			file.filename = documentRootDirectory + s.result[0];

			getMimeType@File( file.filename )( mime );
			mime.regex = "/";
			split@StringUtils( mime )( s );
			if ( s.result[0] == "text" ) {
				file.format = "text";
				format = "html"
			} else {
				file.format = format = "binary"
			};

			readFile@File( file )( response )
		}
	} ] { nullProcess }
}
