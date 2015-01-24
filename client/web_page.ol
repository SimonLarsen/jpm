include "console.iol"
include "web_page.iol"
include "file.iol"
include "format.iol"

execution { concurrent }

inputPort Input {
	Location: "local"
	Interfaces: WebPageInterface
}

main {
	[ present(request)(response) {
		if(request.layout == null) {
			request.layout = "default"
		};

		file.format = "text";
		file.filename = "templates/" + request.template + ".html";
		readFile@File(file)(template);

		templatereq << request.data;
		templatereq = template;
		template@Format(templatereq)(content);

		file.filename = "layouts/" + request.layout + ".html";
		readFile@File(file)(layout);

		templatereq = layout;
		templatereq._content_ = content;
		template@Format(templatereq)(response)
	} ] { nullProcess }
}
