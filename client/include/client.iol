type InstallPackagesRequest : void {
	.packages[0,*] : string
}

type PackageListResponse : void {
	.package[0,*] : void {
		.name : string
		.server : string
		.version : string
	}
}

type SearchResponse : void {
	.package[0,*] : void {
		.name : string
		.server : string
		.version : string
	}
}

interface ClientInterface {
	RequestResponse:
		update(void)(undefined),
		upgrade(void)(void),
		installPackages(InstallPackagesRequest)(void),
		search(string)(SearchResponse),
		list(string)(PackageListResponse)
}
