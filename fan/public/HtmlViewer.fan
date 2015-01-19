using afIoc
using afReflux
using gfx
using fwt
using fandoc

** (View) - A simple HTML viewer for HTTP and file resources. 
class HtmlViewer : View {
	@Inject private IframeBlocker	iframeBlocker
	@Inject private AppStash		stash
	@Inject private Reflux			reflux
			private Browser			browser
			private Label			statusBar

	@NoDoc
	protected new make(|This| in) : super(in) {
		reuseView = true
		content = EdgePane() {
			it.center = browser = Browser() {
				it.onHyperlink.add	|e| { this->onHyperlink(e) }	
				it.onTitleText.add	|e| { this->onTitleText(e) }
				it.onStatusText.add	|e| { this->onStatusText(e) }
				it.onLoad.add		|e| { this->onLoad(e) }
			}
			it.bottom = statusBar = Label()
		}
	}

	@NoDoc
	override Void onDeactivate() {
		try {
			// we want to keep the scrollTop when switching between views, 
			// but clear it when closing the tab - so when re-opened, we're at the top again!
			if (stash["${resource?.uri}.htmlViewer.clear"] == true)
				stash.remove("${resource.uri}.htmlViewer.clear")
			else {
				scrollTop := browser.evaluate("return document.documentElement.scrollTop;")
				stash["${resource?.uri}.htmlViewer.scrollTop"] = scrollTop
			}
			
		} catch (Err err)
			typeof.pod.log.warn("JS Err: ${err.msg}")
	}

	override Void onHide() {
		echo("hiding")
	}

	override Bool confirmClose(Bool force) {
		stash.remove("${resource.uri}.htmlViewer.scrollTop")
		stash["${resource?.uri}.htmlViewer.clear"] = true
		return true
	}
	
	@NoDoc
	override Void load(Resource resource) {
		super.load(resource)

		res := resolveResource(resource)
		if (res is Uri)
			browser.url = res
		else if (res is Str)
			browser.html = res
		else
			throw Err("Resource should resolve to either a URI or a Str, not: $res")

		
		// set focus so browser responds to scroll events
		// see http://fantom.org/sidewalk/topic/2024#c13355
		Desktop.callLater(50ms) |->| {
			browser.focus
		}
	}

	@NoDoc
	override Void refresh() {
		browser.refresh
	}
	
	** Hook for subclasses to convert the resource into either a URI or a Str.
	** Returns 'resource.uri' by default.
	virtual Obj resolveResource(Resource resource) {
		resource.uri
	}
	
	private Void onLoad(Event event) {
		scrollTop := stash["${resource?.uri}.htmlViewer.scrollTop"]
		if (scrollTop != null)
			browser.execute("window.scrollTo(0, ${scrollTop});")
	}

	private Void onStatusText(Event event) {
		statusBar.text = event.data
	}

	private Void onTitleText(Event event) {
		name = event.data
	}
	
	private Void onHyperlink(Event event) {
		// don't hyperlink in place, instead we route the hyperlink through reflux to save 
		// the URI in the history and give consistent navigation
		url := (Uri) event.data

		// ignore links to anchors on the same page (IE defines these links as "about:blank#anchor")
		if (url.scheme == "about" && url.name == "blank")
			return

		// if a shitty url, cancel the event
		if (iframeBlocker.block(url)) {
			event.data = null
			return
		}
		
		// anything beyond this point will be routed through `Reflux.load()` and have its URI resolved 
		// so cancel the link event in the browser
		event.data = null
		
		// IE gives relative links the scheme 'about' so strip it off and return an absolute URI, 
		// using the existing resource as the base 
		if (url.scheme == "about" && !url.isPathAbs) 
			url = `${resource.uri.parent}${url.pathStr}`

		// route the URI through reflux so it gets stored in the history
		reflux.load(url.toStr)
	}
	
	private static Str fandocToHtml(Str fandoc, Uri? base := null) {
		writer	:= FandocWriter(base)
		doc 	:= FandocParser().parseStr(fandoc)
		doc.write(writer)
		return writer.toHtml
	}
}
