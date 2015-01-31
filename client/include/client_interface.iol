type ClientInstallPackagesRequest : void {
	.packages[0,*] : string
}

type ClientPackageListResponse : void {
	.package[0,*] : void {
		.name : string
		.server : string
		.version : string
	}
}

type ClientSearchResponse : void {
	.package[0,*] : void {
		.name : string
		.server : string
		.version : string
		.depends[0,*] : void {
			.name : string
			.version : string
		}
		.description : string
	}
}

type ClientFaultType : void {
	.message : string
}

interface ClientInterface {
	RequestResponse:
		update(void)(undefined),
		installPackages(ClientInstallPackagesRequest)(void) throws ClientFault(ClientFaultType),
		search(string)(ClientSearchResponse),
		list(string)(ClientPackageListResponse)
}
