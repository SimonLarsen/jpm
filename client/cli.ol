include "console.iol"
include "client_interface.iol"

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

define cmd_update {
	update@Client()()
}

define cmd_upgrade {
	upgrade@Client()()
}

define cmd_install {
	for(i = 1, i < #args, i++) {
		request.packages[i-1] = args[i]
	};
	installPackages@Client(request)()
}

define cmd_search {
	if(args[1] == null || args[1] == "") {
		args[1] = "*"
	};
	search@Client(args[1])(res);
	for(i = 0, i < #res.package, i++) {
		println@Console(res.package[i].server + "/" + res.package[i].name + "\t" + res.package[i].version)()
	}
}

define cmd_list {
	if(args[1] == null || args[1] == "") {
		args[1] = "*"
	};
	list@Client(args[1])(res);
	for(i = 0, i < #res.package, i++) {
		println@Console(res.package[i].server + "/" + res.package[i].name + "\t" + res.package[i].version)()
	}
}

main {
	if(args[0] == "-h" || args[0] == "--help") {
		cmd_help
	}
	else if(args[0] == "update") {
		cmd_update
	}
	else if(args[0] == "upgrade") {
		cmd_upgrade
	}
	else if(args[0] == "install") {
		cmd_install
	}
	else if(args[0] == "search") {
		cmd_search
	}
	else if(args[0] == "list") {
		cmd_list
	}
	else {
		println@Console("error: Unknown command \"" + args[0] + "\"")()
	}
}
