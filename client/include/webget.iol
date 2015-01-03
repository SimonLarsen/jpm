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
		getPackage(WebPackageRequest)(raw)
}

outputPort WebGet {
	Protocol: http {
		.osc.getSpec.alias = "%{name}.jpmspec";
		.osc.getPackage.alias = "%{name}-%{version}.zip";
		.format = "binary"
	}
	Interfaces: WebGetInterface
}
