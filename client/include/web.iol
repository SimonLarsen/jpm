type WebDefaultRequest : void {
	.sid? : string
	.operation : string
	.userAgent? : string
	.data : undefined
	.cookies : undefined
}

type WebLoginRequest : void {
	.sid? : string
	.invalid? : bool
	.username? : string
	.password? : string
}

type WebLoginResponse : string {
	.sid? : string
}

type WebEmptyRequest : void {
	.sid : string
}

type WebInstallPackagesRequest : void {
	.sid : string
	.query? : string
}

type WebSearchRequest : void {
	.sid : string
	.query? : string
}

type WebListRequest : void {
	.sid : string
	.query? : string
}

interface WebInterface {
	RequestResponse:
		default(WebDefaultRequest)(undefined),
		login(WebLoginRequest)(WebLoginResponse),
		update(WebEmptyRequest)(string),
		installPackages(WebInstallPackagesRequest)(string),
		search(WebSearchRequest)(string),
		list(WebListRequest)(string),
		logout(WebEmptyRequest)(string)
}
