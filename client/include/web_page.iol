type WebPagePresentRequest : void {
	.layout? : string
	.template : string
	.data? : void { ? }
}

interface WebPageInterface {
	RequestResponse:
		present(WebPagePresentRequest)(string)
}
