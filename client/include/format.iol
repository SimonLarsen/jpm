type FormatRequest:void {
	.format: string
	.args[0,*]: any
}

interface FormatInterface {
RequestResponse:
	format(FormatRequest)(string),
	template(undefined)(string)
}

outputPort Format {
	Interfaces: FormatInterface
}

embedded {
	Java: "io.github.simonlarsen.format.Format" in Format
}
