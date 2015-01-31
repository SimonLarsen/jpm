define parseConfig {
	getVariable@Environment("HOME")(ENV_HOME);
	parse@YamlUtils(ENV_HOME + "/.jpm/rc.yaml")(rc);

	// Setup defaults
	Config.databasedir = ENV_HOME + "/.jpm/db/";
	Config.datadir = ENV_HOME + "/.jpm/data/";

	if(rc.datadir != null) {
		Config.datadir = rc.datadir
	};

	for(i = 0, i < #rc.users.list, i++) {
		Config.users[i].username = rc.users.list[i].username;
		Config.users[i].password = rc.users.list[i].password
	};

	undef(rc)
}
