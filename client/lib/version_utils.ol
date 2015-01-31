include "version_utils/version_utils_interface.iol"
include "string_utils.iol"

execution { concurrent }

inputPort Input {
	Location: "local"
	Interfaces: VersionUtilsInterface
}

define compareVersions {
	asplit = request.a;
	asplit.regex = "\\.";
	split@StringUtils(asplit)(aparts);

	bsplit = request.b;
	bsplit.regex = "\\.";
	split@StringUtils(bsplit)(bparts);

	if(#aparts.result > #bparts.result) {
		parts = #aparts.result
	} else {
		parts = #bparts.result
	};

	done = false;
	for(i = 0, i < parts && !done, i++) {
		done = true;
		if(aparts.result[i] == null || aparts.result[i] == "*") {
			comparison = -1
		}
		else if(bparts.result[i] == null || bparts.result[i] == "*") {
			comparison = 1
		}
		else {
			anum = int(aparts.result[i]);
			bnum = int(bparts.result[i]);
			if(anum < bnum) {
				comparison = -1
			}
			else if(anum > bnum) {
				comparison = 1
			}
			else {
				comparison = 0;
				done = false
			}
		}
	}
}

main {
	[ compare(request)(response) {
		compareVersions;
		response = comparison
	} ] { nullProcess }

	[ max(request)(response) {
		compareVersions;
		if(comparison < 0) {
			response = request.b
		}
		else {
			response = request.a
		}
	} ] { nullProcess }
}
