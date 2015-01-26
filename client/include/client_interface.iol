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
	}
}

interface ClientInterface {
	RequestResponse:
		update(void)(undefined),
		upgrade(void)(void),
		installPackages(ClientInstallPackagesRequest)(void),
		search(string)(ClientSearchResponse),
		list(string)(ClientPackageListResponse)
}
