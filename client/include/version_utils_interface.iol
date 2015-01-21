type VersionCompareRequest : void {
	.a : string
	.b : string
}

interface VersionUtilsInterface {
	RequestResponse:
		/**!
		 * Compares two version strings.
		 * Returns < 0 if a is older than b,
		 * 0 if the versions are equal and
		 * > 0 if a is newer than be.
		 */
		compare(VersionCompareRequest)(int)
}
