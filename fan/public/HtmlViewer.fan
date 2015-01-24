using afIoc
using afReflux
using gfx
using fwt
using fandoc

** (View) - A HTML viewer for HTTP and file resources. 
class HtmlViewer : View {
	@Inject private IframeBlocker	iframeBlocker
	@Inject private AppStash		stash
	@Inject private Reflux			reflux
			private Browser			browser
			private Label			statusBar

	@NoDoc
	protected new make(|This| in) : super(in) {
		content = EdgePane() {
			it.center = browser = Browser() {
				it.onHyperlink.add	|e| { this->onHyperlink(e) }	
				it.onTitleText.add	|e| { this->onTitleText(e) }
				it.onStatusText.add	|e| { this->onStatusText(e) }
				it.onLoad.add		|e| { this->onLoad(e) }
			}
			it.bottom = EdgePane() {
				it.top = BorderPane {
					it.border = Border("1,0,0 $Desktop.sysNormShadow")
				}				
				it.center = statusBar = Label()
			}
		}
	}

	override Bool reuseView(Resource resource) { true }
	
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
	override Void refresh(Resource? resource := null) {
		if (resource == null || resource == this.resource)
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
		try {
			url := event.data.toStr.toUri
			if (url.scheme == "about") 
				event.data = normaliseBrowserUrl(url).toStr
		} catch {}
		statusBar.text = event.data
	}

	private Void onTitleText(Event event) {
		// don't show useless titles!
		if (event.data != "about:blank")
			name = event.data
	}
	
	private Void onHyperlink(Event event) {
		// don't hyperlink in place, instead we route the hyperlink through reflux to save 
		// the URI in the history and give consistent navigation
		url := (Uri) event.data

		// if a shitty url, cancel the event
		if (iframeBlocker.block(url)) {
			event.data = null
			return
		}

		// doesn't work 'cos stoopid Fandoc emits `className#wot` when it should be `#wot`
		// TODO: rewrite Fandoc generator
//		url = normaliseBrowserUrl(url)
//		if (Url(resource.uri).minusFrag == Url(url).minusFrag)
//			return

		// the other work around
		if (url.scheme == "about" && url.name == "blank" && url.frag != null)
			return

		// normalise AFTER the above fudge
		url = normaliseBrowserUrl(url)

		// anything beyond this point will be routed through `Reflux.load()` 
		// so cancel the link event in the browser
		event.data = null

		// route the URI through reflux so it gets stored in the history
		reflux.load(url.toStr)
	}
	
	protected Uri normaliseBrowserUrl(Uri url) {
		// anchors on the same page are defined as `about:blank#anchor`
		if (url.scheme == "about" && url.name == "blank" && url.frag != null)
			url = (resource.uri.parent ?: resource.uri).plusName(resource.uri.name + "#" + url.frag)
		
		// IE gives relative links the scheme 'about' so resolve it relative to the current resource 
		if (url.scheme == "about")
			url = Url(resource.uri + url.pathOnly).plusQuery(url.queryStr).plusFrag(url.frag).toUri

		return url
	}
	
	private static Str fandocToHtml(Str fandoc, Uri? base := null) {
		writer	:= FandocWriter(base)
		doc 	:= FandocParser().parseStr(fandoc)
		doc.write(writer)
		return writer.toHtml
	}
}
