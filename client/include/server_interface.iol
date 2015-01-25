type ServerGetSpecRequest : void {
	.server : string
	.name : string
	.version : string
}

type ServerGetPackageRequest : void {
	.server : string
	.name : string
	.version : string
}

type ServerGetRootManifestRequest : void {
	.server : string
}

type ServerGetFileRequest : void {
	.server : string
	.path : string
}

type ServerDownloadPackageRequest : void {
	.name : string
	.server : string
	.version : string
}

interface ServerInterface {
	RequestResponse:
		getPackageList(void)(undefined),
		getSpec(ServerGetSpecRequest)(undefined) throws ServerFault,
		getPackage(ServerGetPackageRequest)(raw) throws ServerFault,
		getRootManifest(ServerGetRootManifestRequest)(undefined) throws ServerFault,
		getFile(ServerGetFileRequest)(raw) throws ServerFault,
		downloadPackage(ServerDownloadPackageRequest)(void) throws ServerFault
}
