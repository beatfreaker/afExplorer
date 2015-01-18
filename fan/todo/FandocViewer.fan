using afIoc
using afReflux
using gfx
using fwt
using fandoc

** (View) - A simple HTML viewer for http and file resources. 
class FandocViewer : View {
	@Inject private Reflux	 	reflux
			private WebBrowser?	browser

	protected new make(|This| in) : super(in) { 
		content = browser = WebBrowser() {
			it.onHyperlink.add |e| { this->onHyperlink(e) }	
		}
	}

	override Void load(Resource resource) {
		super.load(resource)
		
		if (resource is FileResource) {
			file	:= (resource as FileResource).file

			// TODO: have a resource -> HTML service
			fandoc 	:= file.readAllStr
			html	:= fandocToHtml(fandoc, resource.uri)
			browser.loadStr(html)
		}

		// set focus so browser responds to scroll events
		// see http://fantom.org/sidewalk/topic/2024#c13355
		Desktop.callLater(50ms) |->| {
			browser.focus
		}
	}
	
	private Void onHyperlink(Event event) {
		// don't hyperlink in place, instead we route the hyperlink through reflux to save 
		// the uri in the history and give consistent navigation
		Uri uri := event.data

		// stop an infinite loop and return early
		// see http://fantom.org/sidewalk/topic/2069
		if (uri.query.containsKey("dodgyLink"))
			return

		// ignore links to anchors on the same page (IE defines these links as "about:blank#anchor")
		if (uri.scheme == "about" && uri.name == "blank")
			return
		
		// anything beyond this point will have its uri resolved and routed through `Frame.load` 
		// so cancel the link event in the browser
		event.data = null
		
		// IE gives relative links the scheme 'about' so strip it off and return an absolute URI, 
		// using the existing resource as the base 
		if (uri.scheme == "about" && !uri.isPathAbs) 
			uri = `${resource.uri.parent}${uri.pathStr}`

		// route the URI through reflux so it gets stored in the history
		reflux.load(uri.toStr)
	}
	
	private static Str fandocToHtml(Str fandoc, Uri? base := null) {
		writer	:= FandocWriter(base)
		doc 	:= FandocParser().parseStr(fandoc)
		doc.write(writer)
		return writer.toHtml
	}
}
