include "version_utils/version_utils_interface.iol"

outputPort VersionUtils {
	Interfaces: VersionUtilsInterface
}

embedded {
	Jolie: "version_utils.ol" in VersionUtils
}
