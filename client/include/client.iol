type InstallPackagesRequest : void {
	.packages[0,*] : string
}

type PackageListResponse : void {
	.package[0,*] : void {
		.name : string
		.version : string
	}
}

type SearchResponse : void {
	.package[0,*] : void {
		.server : string
		.name : string
		.version : string
	}
}

interface ClientInterface {
	RequestResponse:
		update(void)(void),
		upgrade(void)(void),
		installPackages(InstallPackagesRequest)(void),
		search(string)(SearchResponse),
		list(void)(PackageListResponse)
}
