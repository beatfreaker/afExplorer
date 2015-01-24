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
	private Str[]		podNames

	protected new make(|This| in) : super(in) {
		// BugFix: Pod.list throws an Err if any pod is invalid (wrong dependencies etc) 
		// this way we don't even load the pod into memory!
		podNames = Env.cur().findAllPodNames
	}
	
	override Bool reuseView(Resource resource) {
		// open new tabs for different types of resources
		this.resource?.typeof == resource.typeof
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
	
	override Void refresh(Resource? resource := null) {
		if (resource == null || resource == this.resource) {
			// the browser doesn't like refreshing a string, so we regenerate the HTML 
			if (this.resource is FileResource || this.resource is FandocResource) {
				super.load(this.resource)
			} else
				super.refresh(null)
		}
	}
	
	private static Str fandocToHtml(Str fandoc, Uri? base := null) {
		writer	:= FandocWriter(base)
		doc 	:= FandocParser().parseStr(fandoc)
		doc.write(writer)
		return writer.toHtml
	}
	
	// ---- Ripped from Fandoc Viewer ----
	
	private static const FandocEnv	docEnv	:= FandocEnv()

	private Str toHtml(FandocResource resource) {
		isTopIndex := (resource.uri.path.isEmpty) 
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
			it.spaces = podNames.map { 
				docEnv.space(it)
			}
		}
	}
	
	private Doc loadFrom(Uri uri) {
		podFile := Env.cur.findPodFile(uri.path[0])
		// we get a nice 'Pod file not found err' is pod doesn't exist
		docPod 	:= DocPod.load(podFile)
		doc 	:= docPod.doc(uri.path[1], false)
		
		if (doc == null) {
			docNames := [,]
			docPod.eachDoc { docNames.add(it.docName) }
			throw ArgNotFoundErr("Doc not found - ${docPod.name}::${uri.path[1]}", docNames)
		}
		
		return doc
	}
}
