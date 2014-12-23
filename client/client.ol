include "console.iol"
include "client.iol"

inputPort Input {
	Location: "local"
	Interfaces: ClientInterface
}

execution { sequential }

main {
	[ installPackages(request)() {
		for(i = 0, i < #request.packages, i++) {
			println@Console("Installing packages: " + request.packages[i])()
		}
	} ] { nullProcess }

	[ listInstalledPackages()(response) {
		nullProcess
	} ] { nullProcess }

	[ search(request)(response) {
		nullProcess
	} ] { nullProcess }
}
