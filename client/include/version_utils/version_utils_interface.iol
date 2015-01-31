type VersionCompareRequest : void {
	.a : string
	.b : string
}

type VersionMaxRequest : void {
	.a : string
	.b : string
}

interface VersionUtilsInterface {
	RequestResponse:
		/**!
		 * Compares two version strings.
		 * Returns < 0 if a is older than b,
		 * 0 if the versions are equal and
		 * > 0 if a is newer than b.
		 */
		compare(VersionCompareRequest)(int),
		/**
		 * Returns the greater of the two versions.
		 * Defaults to first string if versions are equal.
		 */
		max(VersionMaxRequest)(string)
}
