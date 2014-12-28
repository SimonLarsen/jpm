include "console.iol"
include "file.iol"
include "protocols/http.iol"
include "string_utils.iol"
include "format.iol"
include "web_interface.iol"
include "client.iol"

constants {
	WebLocation = "socket://localhost:8001/",
	ContentDirectory = "www/",
}

execution { concurrent }

inputPort Input {
	Protocol: http {
		.keepAlive = true;
		.format -> format;
		.contentType -> mime;
		.default = "default";
		.charset = "UTF-8"
	}
	Location: WebLocation
	Interfaces: WebInterface
}

outputPort Client {
	Interfaces: ClientInterface
}

embedded {
	Jolie: "client.ol" in Client
}

main {
	[ default(request)(response) {
		scope(s) {
			install(FileNotFound =>
				println@Console("File not found: " + file.filename)()
			);

			s = request.operation;
			s.regex = "\\?";
			split@StringUtils(s)(s);
			
			// Default page
			if (s.result[0] == "") {
				s.result[0] = "index.html"
			};
			file.filename = ContentDirectory + s.result[0];

			getMimeType@File(file.filename)(mime);
			mime.regex = "/";
			split@StringUtils(mime)(s);
			if (s.result[0] == "text") {
				file.format = "text";
				format = "html"
			} else {
				file.format = format = "binary"
			};

			readFile@File(file)(response)
		}
	} ] { nullProcess }

	[ listPackages()(response) {
		list@Client()(packages);
		file.filename = "templates/listPackages.html";
		file.format = "text";
		readFile@File(file)(template);

		template.packages = "";
		for(i = 0, i < #packages.package, i++) {
			template.packages += "<tr><td>" + packages.package[i].name
				+ "</td><td>" + packages.package[i].version + "</td></tr>"
		};
		template@Format(template)(response);
		format = "html"
	} ] { nullProcess }

	[ installPackages(request)(response) {
		if(request.packages == null) {
			file.filename = "www/installPackages.html";
			file.format = "text";
			readFile@File(file)(response);
			format = "html"
		}
		else {
			splitreq = request.packages;
			splitreq.regex = ",";
			split@StringUtils(splitreq)(split);

			for(i = 0, i < #split.result, i++) {
				trim@StringUtils(split.result[i])(package);
				println@Console("Requested package: " + package)();
				installreq.packages[i] = package
			};
			installPackages@Client(installreq)()
		}
	} ] { nullProcess }
}
