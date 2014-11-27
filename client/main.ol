include "console.iol"
include "runtime.iol"
include "constants.iol"

define cmd_help {
	if(#args < 2) {
		println@Console(Help_Text)()
	}
}

define cmd_install {
	if(#args < 2) {
		println@Console("error: Specify at least one package name (e.g. jpm install PACKAGE)")()
	}
	else {
		println@Console("Installing " + args[1])()
	}
}

main {
	if(args[0] == "-h" || args[0] == "--help") {
		cmd_help
	}
	else if(args[0] == "-v" || args[0] == "--version") {
		println@Console(Version)()
	}
	else if(args[0] == "install") {
		cmd_install
	}
}
