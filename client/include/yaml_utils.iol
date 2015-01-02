interface YamlUtilsInterface {
	RequestResponse:
		parseYamlFile(string)(undefined)
}

outputPort YamlUtils {
	Interfaces: YamlUtilsInterface
}

embedded {
	Java: "io.github.simonlarsen.yaml.YamlUtils" in YamlUtils
}
