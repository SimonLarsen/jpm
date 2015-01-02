type WebSpecRequest : void {
	.name : string
}

type WebPackageRequest : void {
	.name : string
}

interface WebGetInterface {
	RequestResponse:
		getSpec(WebSpecRequest)(undefined),
		getPackage(WebPackageRequest)(undefined)
}

outputPort WebGet {
	Protocol: http {
		.method = "GET";
		.osc.getSpec.alias = "%{name}.jpmspec";
		.osc.getPackage.alias = "%{name}.zip"
	}
	Interfaces: WebGetInterface
}
