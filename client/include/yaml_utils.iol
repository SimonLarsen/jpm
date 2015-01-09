interface YamlUtilsInterface {
	RequestResponse:
		parse(string)(undefined) throws FileNotFound MultipleDocuments,
		parseAll(string)(undefined) throws FileNotFound
}

outputPort YamlUtils {
	Interfaces: YamlUtilsInterface
}

embedded {
	Java: "io.github.simonlarsen.yaml.YamlUtils" in YamlUtils
}
