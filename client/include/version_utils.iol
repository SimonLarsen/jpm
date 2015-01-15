type VersionCompareRequest : void {
	.a : string
	.b : string
}

interface VersionUtilsInterface {
	RequestResponse:
		compare(VersionCompareRequest)(int)
}

outputPort VersionUtils {
	Interfaces: VersionUtilsInterface
}

embedded {
	Jolie: "version_utils.ol" in VersionUtils
}
