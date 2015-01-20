type VersionCompareRequest : void {
	.a : string
	.b : string
}

interface VersionUtilsInterface {
	RequestResponse:
		compare(VersionCompareRequest)(int)
}
