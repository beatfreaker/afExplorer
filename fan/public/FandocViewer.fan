using afIoc
using afReflux
using gfx
using fwt
using afBeanUtils
using fandoc::FandocParser
using web::WebOutStream
using compilerDoc

** (View) - A viewer for '.fandoc' files. 
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
		
		if (resource is FandocResource) {
			return toHtml(resource)
		}

		throw Err("Unknown resource: $resource")
	}
	
	override Void refresh() {
		// the browser doesn't like refreshing a string, so we regenerate the HTML 
		if (resource is FileResource || resource is FandocResource) {
			super.load(resource)
		} else
			super.refresh
	}
	
	private static Str fandocToHtml(Str fandoc, Uri? base := null) {
		writer	:= FandocWriter(base)
		doc 	:= FandocParser().parseStr(fandoc)
		doc.write(writer)
		return writer.toHtml
	}
	
	
	private static const FandocEnv	docEnv	:= FandocEnv()

	private Str toHtml(FandocResource resource) {
		isTopIndex := (resource.uri.host == null || resource.uri.host.isEmpty) 
		doc := isTopIndex ? topIndex : loadFrom(resource.uri)
	
		// Renders the `compilerDoc::Doc` to a HTML Str.
		buff	:= StrBuf()
		webOut	:= WebOutStream(buff.out)
		render	:= (DocRenderer) doc.renderer.make([docEnv, webOut, doc])
		render.writeDoc
		return buff.toStr
	}
	
	private Doc topIndex() {
		DocTopIndex() {
			it.spaces = Pod.list.map { 
				docEnv.space(it.name)
			}
		}
	}
	
	private Doc loadFrom(Uri uri) {
		podFile := Env.cur.findPodFile(uri.auth)
		// we get a nice 'Pod file not found err' is auth / pod doesn't exist
		docPod 	:= DocPod.load(podFile)
		doc 	:= docPod.doc(uri.name, false)
		
		if (doc == null) {
			docNames := [,]
			docPod.eachDoc { docNames.add(it.docName) }
			throw ArgNotFoundErr("${docPod.name}::${uri.name}", docNames)
		}
		
		return doc
	}
}
