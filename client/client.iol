type InstallPackagesRequest : void {
	.packages[0,*] : string
}

type ListResponse : void {
	.name[0,*] : string
	.version[0,*] : string
}

type SearchResponse : void {
	.name[0,*] : string
	.version[0,*] : string
}

interface ClientInterface {
	RequestResponse:
		installPackages(InstallPackagesRequest)(void),
		list(void)(ListResponse),
		search(string)(SearchResponse)
}
