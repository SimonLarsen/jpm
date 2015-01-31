include "console.iol"
include "file.iol"
include "string_utils.iol"
include "format.iol"
include "web_interface.iol"
include "client_interface.iol"
include "web_page_interface.iol"
include "yaml_utils.iol"
include "environment.iol"
include "parse_config.iol"

constants {
	WebLocation = "socket://localhost:4000/",
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
	parseConfig;
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
		if(request.username != null || request.password != null) {
			loginCorrect = false;
			for(i = 0, i < #Config.users, i++) {
				if(request.username == Config.users[i].username
				&& request.password == Config.users[i].password) {
					page.template = "redirect";
					page.data.url = "installPackages";
					present@WebPage(page)(response);
					undef(page);

					response.sid = csets.sid = new;
					loginCorrect = true
				}
			};
			if(loginCorrect == false) {
				page.template = "login_error";
				present@WebPage(page)(response);
				undef(page)
			}
		}
		else {
			page.template = "login";
			present@WebPage(page)(response);
			undef(page)
		};
		format = "html"
	} ] { 
		keepSession = true;
		while(keepSession) {
			[ update()(response) {
				update@Client()(output);

				page.layout = "default";
				page.template = "update";
				page.data.title = "Update - jpm";

				foreach(server : output) {
					if(output.(server).count > 0) {
						page.data.rows += "<tr>
						<td>" + server + "</td>
						<td>" + output.(server).count + "</td></tr>"
					} else {
						page.data.rows += "<tr class=\"danger\">
						<td>" + server + "</td>
						<td>" + output.(server).count + "</td></tr>"
					}
				};
				page.data.rows += "</tr>";

				present@WebPage(page)(response);
				undef(page);
				format = "html"
			} ] { nullProcess }

			[ installPackages(request)(response) {
				if (request.packages != null) {
					splitreq = request.packages;
					splitreq.regex = ",";
					split@StringUtils(splitreq)(split);

					for(i = 0, i < #split.result, i++) {
						trim@StringUtils(split.result[i])(package);
						println@Console("Requested package: " + package)();
						installreq.packages[i] = package
					};

					page.template = "installPackagesMessage";
					scope(InstallPackages) {
						install(default =>
							page.data.messagetype = "danger";
							page.data.message = "<b>Error.</b> Could not install packages."
						);

						installPackages@Client(installreq)();

						page.data.messagetype = "info";
						page.data.message = "Packages installed successfully."
					}
				} else {
					page.template = "installPackages"
				};

				page.layout = "default";
				page.data.title = "Install packages - jpm";
				present@WebPage(page)(response);
				undef(page);
				format = "html"
			} ] { nullProcess }

			[ search(request)(response) {
				if(request.query == null || request.query == "") {
					request.query = "*"
				};

				page.layout = "default";
				page.template = "search";
				page.data.title = "Search - jpm";
				page.data.query = request.query;

				search@Client(request.query)(pkgs);
				for(i = 0, i < #pkgs.package, i++) {
					page.data.rows +=
					"<tr><td>"	+ pkgs.package[i].name + "</td>
					<td>"		+ pkgs.package[i].server + "</td>
					<td>"		+ pkgs.package[i].version + "</td>
					<td>"		+ pkgs.package[i].description + "</td></tr>"
				};

				present@WebPage(page)(response);
				undef(page);
				format = "html"
			} ] { nullProcess }

			[ list(request)(response) {
				if(request.query == null || request.query == "") {
					request.query = "*"
				};

				page.layout = "default";
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
