include "console.iol"
include "client.iol"

constants {
	HELP_TEXT = "jpm is a packages manager for Jolie.

	Usage:
	  jpm -h/--help
	  jpm -v/--version
	  jpm command [arguments..] [options...]"
}

outputPort Client {
	Interfaces: ClientInterface
}

embedded {
	Jolie: "client.ol" in Client
}

define cmd_install {
	for(i = 1, i < #args, i++) {
		request.packages[i-1] = args[i]
	};
	installPackages@Client(request)()
}

define cmd_help {
	println@Console(HELP_TEXT)()
}

main {
	if(args[0] == "-h" || args[0] == "--help") {
		cmd_help
	}
	else if(args[0] == "install") {
		cmd_install
	}
	else if(args[0] == "list") {
		list@Client()()
	}
	else if(args[0] == "search") {
		search@Client(args[1])()
	}
}
