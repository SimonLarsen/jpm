type FileUtilsTempFileRequest : void {
	.prefix : string
	.suffix : string
}

interface FileUtilsInterface {
	RequestResponse:
		getLastModified(string)(long),
		createTempFile(FileUtilsTempFileRequest)(string) throws CouldNotCreateFile
}

outputPort FileUtils {
	Interfaces: FileUtilsInterface
}

embedded {
	Java: "io.github.simonlarsen.io.FileUtils" in FileUtils
}
