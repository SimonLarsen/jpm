include "console.iol"
include "file.iol"
include "string_utils.iol"
include "format.iol"
include "web_interface.iol"
include "client_interface.iol"
include "web_page_interface.iol"

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

outputPort WebPage {
	Interfaces: WebPageInterface
}

embedded {
	Jolie: "client.ol" in Client
	Jolie: "web_page.ol" in WebPage
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
				page.layout = "empty";
				page.template = "redirect";
				page.data.url = "installPackages";
				present@WebPage(page)(response);
				undef(page);

				response.sid = csets.sid = new
			}
			else {
				page.layout = "empty";
				page.template = "login_error";
				present@WebPage(page)(response);
				undef(page)
			}
		}
		else {
			page.layout = "empty";
			page.template = "login_error";
			present@WebPage(page)(response);
			undef(page)
		};
		format = "html"
	} ] { 
		keepSession = true;
		while(keepSession) {
			[ update()(response) {
				update@Client()(output);

				page.template = "update";
				page.data.title = "Update - jpm";

				foreach(server : output) {
					if(output.(server).status == true) {
						page.data.rows += "<tr>
						<td>" + server + "</td>
						<td>Success</td>
						<td>" + output.(server).count + "</td></tr>"
					} else {
						page.data.rows += "<tr class=\"danger\">
						<td>" + server + "</td>
						<td>Failed</td>
						<td>" + output.(server).count + "</td></tr>"
					}
				};
				page.data.rows += "</tr>";

				present@WebPage(page)(response);
				undef(page);
				format = "html"
			} ] { nullProcess }

			[ installPackages(request)(response) {
				if(request.packages == null) {
					page.template = "installPackages";
					page.data.title = "Install packages - jpm";
					present@WebPage(page)(response);
					undef(page);
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

				page.template = "search";
				page.data.title = "Search - jpm";
				page.data.query = request.query;

				search@Client(request.query)(packages);
				for(i = 0, i < #packages.package, i++) {
					page.data.rows +=
					"<tr><td>"	+ packages.package[i].name + "</td>
					<td>"		+ packages.package[i].server + "</td>
					<td>"		+ packages.package[i].version + "</td></tr>"
				};

				present@WebPage(page)(response);
				undef(page);
				format = "html"
			} ] { nullProcess }

			[ list(request)(response) {
				if(request.query == null || request.query == "") {
					request.query = "*"
				};

				page.template = "list";
				page.data.title = "Installed packages - jpm";
				page.data.query = request.query;

				list@Client(request.query)(packages);
				for(i = 0, i < #packages.package, i++) {
					page.data.packages += "<tr>
						<td>" + packages.package[i].name + "</td>
						<td>" + packages.package[i].server + "</td>
						<td>" + packages.package[i].version + "</td></tr>"
				};

				present@WebPage(page)(response);
				undef(page);
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
