type FileServerGetFileRequest : void {
	.path : string
}

interface FileServerInterface {
	RequestResponse:
		getFile(FileServerGetFileRequest)(raw)
}

outputPort FileServer {
	Protocol: http {
		.osc.getFile.alias = "%{path}"
	}
	Interfaces: FileServerInterface
}
