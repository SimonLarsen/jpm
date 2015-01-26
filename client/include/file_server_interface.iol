type FileServerGetFileRequest : void {
	.path : string
}

interface FileServerInterface {
	RequestResponse:
		getFile(FileServerGetFileRequest)(undefined)
}
