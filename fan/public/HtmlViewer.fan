using afIoc
using afReflux
using gfx
using fwt
using fandoc

** (View) - A HTML viewer for HTTP and file resources. 
class HtmlViewer : View {
	@Inject private IframeBlocker	iframeBlocker
	@Inject private AppStash		stash
	@Inject private GlobalCommands	globalCommands
	@Inject private Registry		registry
	@Inject private Reflux			reflux
			private Browser			browser
			private Label			statusBar
			private Obj?			resolvedContent

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

	** Returns 'true'.
	override Bool reuseView(Resource resource) { true }
	
	** Scrolls the page to an ID. Handy for when setting the HTML via the text attribute.
	** 
	**   scrollToId("#myId")
	Void scrollToId(Str id) {
		browser.execute("var ele = document.getElementById(${id.toCode}); if (ele) window.scrollTo(ele.offsetLeft, ele.offsetTop);")
	}

	@NoDoc
	override Void onActivate() {
		enableCmds

		// fudge to prevent blank tabs when panel switches to / from a single pane
		if (resolvedContent != null)
			Desktop.callLater(50ms) |->| {
				if (resolvedContent is Str) {
					browser.html = resolvedContent
					browser.focus
				}
				if (resolvedContent is Uri) {
					if (browser.url != resolvedContent) {
						browser.url = resolvedContent
						browser.focus
					}
				}
			}
	}

	private Void enableCmds() {
		if (resource is FileResource) {
			globalCommands["afReflux.cmdSaveAs"].addInvoker("afExplorer.imageViewer", |Event? e| { this->onSaveAs() } )
			globalCommands["afReflux.cmdSaveAs"].addEnabler("afExplorer.imageViewer", |  ->Bool| { true } )
		}		
	}

	@NoDoc
	override Void onDeactivate() {
		globalCommands["afReflux.cmdSaveAs"].removeEnabler("afExplorer.htmlViewer")
		globalCommands["afReflux.cmdSaveAs"].removeInvoker("afExplorer.htmlViewer")

		try {
			// we want to keep the scrollTop when switching between views, 
			// but clear it when closing the tab - so when re-opened, we're at the top again!
			if (stash["${resource?.uri}.htmlViewer.clear"] == true)
				stash.remove("${resource.uri}.htmlViewer.clear")
			else {
				scrollTop := browser.evaluate("return document.documentElement ? document.documentElement.scrollTop : 0;")
				stash["${resource?.uri}.htmlViewer.scrollTop"] = scrollTop
			}
			
		} catch (Err err)
			typeof.pod.log.warn("JS Err: ${err.msg}")
	}

	@NoDoc
	override Bool confirmClose(Bool force) {
		stash.remove("${resource.uri}.htmlViewer.scrollTop")
		stash["${resource?.uri}.htmlViewer.clear"] = true
		return true
	}
	
	@NoDoc
	override Void load(Resource resource) {
		super.load(resource)
		enableCmds

		resolvedContent = resolveResource(resource)
		if (resolvedContent is Uri)
			browser.url = resolvedContent
		else if (resolvedContent is Str)
			// this delay prevents a blank browser when going to or from a single tab pane
			Desktop.callLater(50ms) |->| {
				browser.html = resolvedContent
			}
		else
			throw Err("Resource should resolve to either a URI or a Str, not: $resolvedContent")

		// set focus so browser responds to scroll events
		// see http://fantom.org/sidewalk/topic/2024#c13355
		Desktop.callLater(50ms) |->| {
			browser.focus
		}
	}

	@NoDoc
	override Void refresh(Resource? resource := null) {
		res := resource ?: this.resource
		if (res != null)
			load(res)
		else
			browser.refresh
	}
	
	** Hook for subclasses to convert the resource into either a URI or a Str.
	** Returns 'resource.uri' by default.
	virtual Obj resolveResource(Resource resource) {
		resource.uri
	}
	
	** Callback for when the Browser's page loads.
	virtual Void onLoad(Event event) {
		scrollTop := stash["${resource?.uri}.htmlViewer.scrollTop"]
		if (scrollTop != null)
			browser.execute("window.scrollTo(0, ${scrollTop});")
	}

	** Callback for when the Browser's status text changes.
	virtual Void onStatusText(Event event) {
		try {
			url := event.data.toStr.toUri
			if (url.scheme == "about") 
				event.data = normaliseBrowserUrl(this.resource.uri, url).toStr
		} catch {}
		statusBar.text = event.data
	}

	** Callback for when the Browser's status text changes.
	virtual Void onTitleText(Event event) {
		// don't show useless titles!
		if (event.data != "about:blank") {
			// set resource name first so it gets picked up by the window
			if (resource is HttpResource)
				((HttpResource) resource).name = event.data
			// this triggers a frame update
			name = event.data
		}
	}
	
	** Callback for when the 'afReflux.cmdSaveAs' 'GlobalCommand' is activated.
	** Default implementation is to perform the *save as*.
	virtual Void onSaveAs() {	
		fileResource := (FileResource) resource
		file := (File?) FileDialog {
			it.mode 		= FileDialogMode.saveFile
			it.dir			= fileResource.file.parent
			it.name			= fileResource.file.name
			it.filterExts	= ["*.${fileResource.file.ext}", "*.*"]
		}.open(reflux.window)

		if (file != null) {
			fileResource.file.copyTo(file)

			fileRes := registry.autobuild(FileResource#, [file])
			reflux.loadResource(fileRes)
			
			isDirty = false	// mark as not dirty so confirmClose() doesn't give a dialog
			reflux.closeView(this, true)

			// refresh any views on the containing directory
			dirRes := registry.autobuild(FolderResource#, [file.parent])
			reflux.refresh(dirRes)
		}
	}

	** Callback for normalising Browser URIs into Reflux URIs.
	virtual Uri normaliseBrowserUrl(Uri resourceUri, Uri url) {
		// anchors on the same page are defined as `about:blank#anchor`
		if (url.scheme == "about" && url.name == "blank" && url.frag != null)
			url = (resourceUri.parent ?: resourceUri).plusName(resourceUri.name + "#" + url.frag)
		
		// IE gives relative links the scheme 'about' so resolve it relative to the current resource 
		if (url.scheme == "about")
			url = Url(resourceUri + url.pathOnly).plusQuery(url.queryStr).plusFrag(url.frag).toUri

		return url
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
		url = normaliseBrowserUrl(this.resource.uri, url)

		// anything beyond this point will be routed through `Reflux.load()` 
		// so cancel the link event in the browser
		event.data = null

		// route the URI through reflux so it gets stored in the history
		reflux.load(url.toStr)
	}
}
