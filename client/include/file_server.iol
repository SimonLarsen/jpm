type FileServerGetFileRequest : void {
	.path : string
}

interface FileServerInterface {
	RequestResponse:
		getFile(FileServerGetFileRequest)(undefined)
}

outputPort FileServer {
	Protocol: http {
		.osc.getFile.alias = "%{path}"
	}
	Interfaces: FileServerInterface
}
