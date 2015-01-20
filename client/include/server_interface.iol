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

interface ServerInterface {
	RequestResponse:
		getPackageList(void)(undefined),
		getSpec(ServerGetSpecRequest)(undefined) throws FileNotFound,
		getPackage(ServerGetPackageRequest)(raw) throws FileNotFound,
		getRootManifest(ServerGetRootManifestRequest)(undefined) throws FileNotFound
}
