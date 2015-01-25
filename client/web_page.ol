include "web_page_interface.iol"
include "file.iol"
include "format.iol"

execution { concurrent }

inputPort Input {
	Location: "local"
	Interfaces: WebPageInterface
}

main {
	[ present(request)(response) {
		file.format = "text";
		file.filename = "templates/" + request.template + ".html";
		readFile@File(file)(template);

		templatereq << request.data;
		templatereq = template;
		template@Format(templatereq)(content);

		if(request.layout != null) {
			file.filename = "layouts/" + request.layout + ".html";
			readFile@File(file)(layout);

			templatereq = layout;
			templatereq._content_ = content;
			template@Format(templatereq)(response)
		} else {
			response = content
		}
	} ] { nullProcess }
}
