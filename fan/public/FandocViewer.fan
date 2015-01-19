using afIoc
using afReflux
using gfx
using fwt
using fandoc

** (View) - A simple Fandoc viewer. 
class FandocViewer : HtmlViewer {

	protected new make(|This| in) : super(in) {
		reuseView = false
	}
	
	** Hook for subclasses to convert the resource into either a URI or a Str.
	** Returns 'resource.uri' by default.
	override Obj resolveResource(Resource resource) {
		if (resource is FileResource) {
			file	:= (resource as FileResource).file
			fandoc 	:= file.readAllStr
			html	:= fandocToHtml(fandoc, resource.uri)
			return html
		}
		
		throw Err("Unknown resource: $resource")
	}
	
	private static Str fandocToHtml(Str fandoc, Uri? base := null) {
		writer	:= FandocWriter(base)
		doc 	:= FandocParser().parseStr(fandoc)
		doc.write(writer)
		return writer.toHtml
	}
}
