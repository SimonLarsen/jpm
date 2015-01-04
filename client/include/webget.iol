type WebSpecRequest : void {
	.name : string
}

type WebPackageRequest : void {
	.name : string
	.version : string
}

interface WebGetInterface {
	RequestResponse:
		getSpec(WebSpecRequest)(raw),
		getPackage(WebPackageRequest)(raw),
		getRootManifest(void)(raw)
}

outputPort WebGet {
	Protocol: http {
		.osc.getSpec.alias = "%{name}.jpmspec";
		.osc.getPackage.alias = "%{name}-%{version}.zip";
		.osc.getRootManifest.alias = "root.yaml";
		.format = "binary"
	}
	Interfaces: WebGetInterface
}
