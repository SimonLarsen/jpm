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

define cmd_help {
	println@Console(HELP_TEXT)()
}

define cmd_install {
	for(i = 1, i < #args, i++) {
		request.packages[i-1] = args[i]
	};
	installPackages@Client(request)()
}

define cmd_list {
	list@Client()(res);
	for(i = 0, i < #res.package, i++) {
		println@Console(res.package[i].name + "\t" + res.package[i].version)()
	};

	undef(res)
}

define cmd_search {
	search@Client(args[1])(res);
	for(i = 0, i < #res.package, i++) {
		println@Console(res.package[i].name + "\t" + res.package[i].version)()
	};

	undef(res)
}

main {
	if(args[0] == "-h" || args[0] == "--help") {
		cmd_help
	}
	else if(args[0] == "install") {
		cmd_install
	}
	else if(args[0] == "list") {
		cmd_list
	}
	else if(args[0] == "search") {
		cmd_search
	}
	else {
		println@Console("error: Unknown command \"" + args[0] + "\"")()
	}
}
