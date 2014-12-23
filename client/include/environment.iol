interface EnvironmentInterface {
RequestResponse: 
	getVariable(string)(string) throws EnvironmentVariableNotFound,
	getVariables(void)(undefined)
}

outputPort Environment {
	Interfaces: EnvironmentInterface
}

embedded {
	Java: "io.github.simonlarsen.environment.Environment" in Environment
}
