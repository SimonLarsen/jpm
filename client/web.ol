include "console.iol"
include "file.iol"
include "string_utils.iol"
include "format.iol"
include "web.iol"
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
		.charset = "UTF-8";
		.cookies.sidCookie = "sid"
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

init {
	println@Console("Web client running at adress: " + WebLocation)()
}

cset {
	sid:
		WebEmptyRequest.sid
		WebInstallPackagesRequest.sid
		WebSearchRequest.sid
		WebListRequest.sid

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

	[ login(request)(response) {
		if(request.username != null && request.password != null) {
			if(request.username == "admin" && request.password == "hunter2") {
				file.filename = "templates/redirect.html";
				file.format = "text";
				readFile@File(file)(template);

				template.url = "installPackages";
				template@Format(template)(response);

				response.sid = csets.sid = new
			}
			else {
				file.filename = "templates/login_error.html";
				file.format = "text";
				readFile@File(file)(response)
			}
		}
		else {
			file.filename = "templates/login.html";
			file.format = "text";
			readFile@File(file)(response)
		};
		format = "html"
	} ] { 
		keepSession = true;
		while(keepSession) {
			[ update()(response) {
				update@Client()(output);

				file.filename = "templates/update.html";
				file.format = "text";
				readFile@File(file)(template);

				foreach(server : output) {
					if(output.(server).status == true) {
						template.rows += "<tr>
						<td>" + server + "</td>
						<td>Success</td>
						<td>" + output.(server).count + "</td></tr>"
					} else {
						template.rows += "<tr class=\"danger\">
						<td>" + server + "</td>
						<td>Failed</td>
						<td>" + output.(server).count + "</td></tr>"
					}
				};
				template.rows += "</tr>";

				template@Format(template)(response);
				format = "html"
			} ] { nullProcess }

			[ installPackages(request)(response) {
				if(request.packages == null) {
					file.filename = "templates/installPackages.html";
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

			[ search(request)(response) {
				if(request.query == null || request.query == "") {
					request.query = "*"
				};

				file.filename = "templates/search.html";
				file.format = "text";
				readFile@File(file)(template);

				template.query = request.query;

				search@Client(request.query)(packages);
				for(i = 0, i < #packages.package, i++) {
					template.rows +=
					"<tr><td>"	+ packages.package[i].name + "</td>
					<td>"		+ packages.package[i].server + "</td>
					<td>"		+ packages.package[i].version + "</td></tr>"
				};

				template@Format(template)(response);
				format = "html"
			} ] { nullProcess }

			[ list(request)(response) {
				if(request.query == null || request.query == "") {
					request.query = "*"
				};

				file.filename = "templates/list.html";
				file.format = "text";
				readFile@File(file)(template);

				template.query = request.query;

				list@Client(request.query)(packages);
				for(i = 0, i < #packages.package, i++) {
					template.packages += "<tr>
						<td>" + packages.package[i].name + "</td>
						<td>" + packages.package[i].server + "</td>
						<td>" + packages.package[i].version + "</td></tr>"
				};

				template@Format(template)(response);
				format = "html"
			} ] { nullProcess }

			[ logout(request)(response) {
				keepSession = false;

				file.filename = "index.html";
				file.format = "text";
				readFile@File(file)(response);
				format = "html"
			} ] { nullProcess }
		}
	}
}
