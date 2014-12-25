type InstallPackagesRequest : void {
	.packages[0,*] : string
}

type ListResponse : void {
	.package[0,*] : void {
		.name : string
		.version : string
	}
}

type SearchResponse : void {
	.package[0,*] : void {
		.name : string
		.version : string
	}
}

interface ClientInterface {
	RequestResponse:
		installPackages(InstallPackagesRequest)(void),
		list(void)(ListResponse),
		search(string)(SearchResponse)
}
