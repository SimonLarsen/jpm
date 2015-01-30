type ServerGetSpecRequest : void {
	.server : string
	.name : string
	.version : string
}

type ServerGetSpecResponse : void {
	.name : string
	.version : string
	.description : string
	.depends? : void {
		.list[0,*] : void {
			.list[2,2] : string
		}
	}
}

type ServerGetPackageRequest : void {
	.server : string
	.name : string
	.version : string
}

type ServerGetRootManifestRequest : void {
	.server : string
}

type ServerGetRootManifestResponse : void {
	.packages : void {
		.list[0,*] : void {
			.name : string
			.versions : void {
				.list[1,*] : string
			}
		}
	}
}

interface ServerInterface {
	RequestResponse:
		// Global operation
		getPackageList(void)(undefined),
		// Server redirects
		getSpec(ServerGetSpecRequest)(undefined) throws ServerFault,
		getPackage(ServerGetPackageRequest)(raw) throws ServerFault,
		getRootManifest(ServerGetRootManifestRequest)(undefined) throws ServerFault,
}
