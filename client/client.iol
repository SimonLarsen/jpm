type InstallPackagesRequest : void {
	.packages[0,*] : string
}

type InstalledPackagesResponse : void {
	.name[0,*] : string
}

type SearchResponse : void {
	.name[0,*] : string
}

interface ClientInterface {
	RequestResponse:
		installPackages(InstallPackagesRequest)(void),
		listInstalledPackages(void)(InstalledPackagesResponse),
		search(string)(SearchResponse)
}
