type HTTPServerGetFileRequest : void {
	.path : string
}

interface HTTPServerInterface {
	RequestResponse:
		getFile(HTTPServerGetFileRequest)(undefined)
}

outputPort HTTPServer {
	Protocol: http {
		.osc.getFile.alias = "%{path}"
	}
	Interfaces: HTTPServerInterface
}
