include "server_interface.iol"

outputPort Server {
	Interfaces: ServerInterface
}

embedded {
	Jolie: "server.ol" in Server
}
