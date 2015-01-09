interface WebInterface {
	RequestResponse:
		default(DefaultOperationHttpRequest)(undefined),
		installPackages(undefined)(undefined),
		search(undefined)(undefined),
		list(void)(undefined)
}
