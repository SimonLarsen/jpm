type FileServerGetSpecRequest: void {
	.name : string
	.version : string
}

type FileServerGetPackageRequest : void {
	.name : string
	.version : string
}

interface FileServerInterface {
	RequestResponse:
		getSpec(FileServerGetSpecRequest)(string),
		getPackage(FileServerGetPackageRequest)(raw),
		getRootManifest(void)(string)
}
