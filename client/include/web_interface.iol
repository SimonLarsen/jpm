interface WebInterface {
	RequestResponse:
		default(DefaultOperationHttpRequest)(undefined),
		listPackages(void)(undefined),
		installPackages(undefined)(undefined)
}

