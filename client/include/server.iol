type ServerSpecRequest : void {
	.name : string
	.version : string
}

type ServerPackageRequest : void {
	.name : string
	.version : string
}

interface ServerInterface {
	RequestResponse:
		getSpec(ServerSpecRequest)(raw),
		getPackage(ServerPackageRequest)(raw),
		getRootManifest(void)(raw)
}

outputPort Server {
	Protocol: http {
		.osc.getSpec.alias = "%{name}-%{version}.jpmspec";
		.osc.getPackage.alias = "%{name}-%{version}.zip";
		.osc.getRootManifest.alias = "root.yaml";
		.format = "binary"
	}
	Interfaces: ServerInterface
}
