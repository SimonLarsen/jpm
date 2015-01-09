type WebSearchRequest : void {
	.query? : string
}

type WebListRequest : void {
	.query? : string
}

interface WebInterface {
	RequestResponse:
		default(DefaultOperationHttpRequest)(undefined),
		update(void)(undefined),
		installPackages(undefined)(undefined),
		search(WebSearchRequest)(undefined),
		list(WebListRequest)(undefined)
}
