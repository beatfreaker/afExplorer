using afIoc
using afReflux
using gfx
using fwt
using afBeanUtils

@NoDoc
class FoldersPanel : Panel, RefluxEvents, ExplorerEvents {
	
	@Inject		private Reflux					reflux
	@Inject		private RefluxIcons				icons
	@Inject		private Explorer				explorer
	@Inject 	private GlobalCommands			globalCommands
	@Inject 	private |File->FileResource|	fileResourceFactory
	@Autobuild	private FoldersTreeModel		model
	
	private Combo			combo	:= Combo() { it.onModify.add |e| { this->onComboModify(e) }; it.dropDown=true; }
	private Str:Str			favourites
	private Int				lastComboIndex
	private ResourceTree	tree
	private FolderResource? fileResource
	
	protected new make(|This| in) : super(in) {
		prefAlign	= Halign.left
		
		tree = ResourceTree(reflux) {
			it.tree = Tree {
				it.border = false
				it.onMouseDown.add	|e| { this->onMouseDown	(e) }
				it.onFocus.add		|e| { this->onFocus		( ) }
				it.onBlur.add		|e| { this->onBlur		( ) }				
			}
			it.roots = explorer.osRoots.map { fileResourceFactory(it.normalize) } 
			it.model = this.model
			it.onPopup.add	|e| { this->onPopup	(e) }
			it.onSelect.add	|e| { this->onSelect(e) }
		}
		
		favourites = explorer.preferences.favourites		
		combo.items = favourites.keys

		content = EdgePane {
			top = InsetPane(2, 0, 2, 2) { it.add(combo) }
			center = BorderPane {
				it.content	= tree.tree
				it.border	= Border("1, 1, 0, 0 $Desktop.sysNormShadow")
			}
		}
	}

	Void gotoFavourite(Str favourite) {
		uri := explorer.preferences.favourites[favourite] ?: throw ArgNotFoundErr("Favourite does not exist: ${favourite}", explorer.preferences.favourites.keys)
		combo.selected = favourite
	}
	
	override Void onShow() {
		// without this, the combo get's all squashed up when the panel is re-shown 
		content.relayout
	}

	override Void onActivate() {
		globalCommands["afExplorer.cmdShowHiddenFiles"	].addEnabler("afExplorer.folderPanel", |->Bool| { true } )
		globalCommands["afReflux.cmdNew"			].addInvoker("afExplorer.folderPanel", |Event? e|	{ this->onNew() } )
		globalCommands["afReflux.cmdNew"			].addEnabler("afExplorer.folderPanel", |  ->Bool| 	{ true } )
	}
	
	override Void onDeactivate() {
		onBlur	// onBlur doesn't always fire when we switch tabs
		globalCommands["afExplorer.cmdShowHiddenFiles"].removeEnabler("afExplorer.folderPanel")
		globalCommands["afReflux.cmdNew"		].removeInvoker("afExplorer.folderPanel")
		globalCommands["afReflux.cmdNew"		].removeEnabler("afExplorer.folderPanel")
	}

	override Void onShowHiddenFiles(Bool show) {
		if (!isShowing) return
		refresh(null)
	}
	
	private Void onSelect() {
		globalCommands["afExplorer.cmdRenameFile"].update
		globalCommands["afExplorer.cmdDeleteFile"].update
		globalCommands["afReflux.cmdCut"].update
		globalCommands["afReflux.cmdCopy"].update
		globalCommands["afReflux.cmdPaste"].update
	}

	private Void onFocus() {
		fileFetcher := |->File?| {
			tree.selected.first?->file
		}

		globalCommands["afExplorer.cmdRenameFile"	].addEnabler("afExplorer.folderPanel", |->Bool| { !tree.selected.isEmpty } )
		globalCommands["afExplorer.cmdDeleteFile"	].addEnabler("afExplorer.folderPanel", |->Bool| { !tree.selected.isEmpty } )
		globalCommands["afReflux.cmdCut"			].addEnabler("afExplorer.folderPanel", |->Bool| { !tree.selected.isEmpty } )
		globalCommands["afReflux.cmdCopy"			].addEnabler("afExplorer.folderPanel", |->Bool| { !tree.selected.isEmpty } )
		globalCommands["afReflux.cmdPaste"			].addEnabler("afExplorer.folderPanel", |->Bool| { !tree.selected.isEmpty && fileFetcher().isDir && explorer.pasteEnabled} )
		globalCommands["afReflux.cmdCut"			].addInvoker("afExplorer.folderPanel", |->|		{ explorer.cut(fileFetcher()) } )
		globalCommands["afReflux.cmdCopy"			].addInvoker("afExplorer.folderPanel", |->|		{ explorer.copy(fileFetcher()) } )
		globalCommands["afReflux.cmdPaste"			].addInvoker("afExplorer.folderPanel", |->|		{ explorer.paste(fileFetcher()) } )
		
		cmdR := (RenameFileCommand) globalCommands["afExplorer.cmdRenameFile"]
		cmdR.fileFetcher = fileFetcher
		cmdD := (DeleteFileCommand) globalCommands["afExplorer.cmdDeleteFile"]
		cmdD.fileFetcher = fileFetcher
	}

	private Void onBlur() {
		globalCommands["afExplorer.cmdRenameFile"].removeEnabler("afExplorer.folderPanel")
		globalCommands["afExplorer.cmdDeleteFile"].removeEnabler("afExplorer.folderPanel")
		globalCommands["afReflux.cmdCut"		].removeEnabler("afExplorer.folderPanel")
		globalCommands["afReflux.cmdCopy"		].removeEnabler("afExplorer.folderPanel")
		globalCommands["afReflux.cmdPaste"		].removeEnabler("afExplorer.folderPanel")
		globalCommands["afReflux.cmdCut"		].removeInvoker("afExplorer.folderPanel")
		globalCommands["afReflux.cmdCopy"		].removeInvoker("afExplorer.folderPanel")
		globalCommands["afReflux.cmdPaste"		].removeInvoker("afExplorer.folderPanel")
	}

	private Void onComboModify(Event event)	{
		if (isActive && combo.selectedIndex >= 0) {
			// this event fires when we switch tabs - then errs when we're not attached! Grr...
//			if (lastComboIndex != combo.selectedIndex) {
			// dunno, seems to work now! I revisited this 'cos I wanted to re-select an option in the drop down
				lastComboIndex  = combo.selectedIndex
				reflux.load(favourites[combo.selected])
//			}
		}
	}

	private Void onMouseDown(Event event) {
		if (event.button != 1 || event.button != 1)
			return
		node := (FileResource?) tree.resourceAt(event.pos)
		if (node == null)
			return
		ctx := (event.key != null && event.key.isCtrl) ? LoadCtx() { it.newTab = true } : LoadCtx()
		reflux.load(node.file.normalize.uri.toStr, ctx)
	}

	private Void onPopup(Event event) {
		if (event.data == null) return
		file := ((FileResource) event.data).file
		res	 := reflux.resolve(file.normalize.uri.toStr)
		event.popup = res.populatePopup(Menu())
	}

	override Void onLoad(Resource resource) {
		if (resource isnot FolderResource && resource is FileResource) {
			folder := ((FileResource) resource).file.parent
			if (folder != null)
				resource = reflux.resolve(folder.uri.toStr)
		}

		if (resource isnot FolderResource || !resource.uri.isAbs) return
		fileResource = resource

		if (!isShowing) return
		Desktop.callLater(50ms) |->| {
			if (fileResource != null)
				tree.showResource(fileResource)
		}
	}

	override Void refresh(Resource? resource := null) {
		if (resource == null) {
			tree.roots = explorer.osRoots.map { fileResourceFactory(it.normalize) }
			tree.refreshAll

		} else {
			tree.refreshResource(resource)
		}

		Desktop.callLater(50ms) |->| {
			if (fileResource != null)
				tree.showResource(fileResource)
		}
	}
	
	private Void onNew() {
		if (fileResource?.file != null) {
			newFile := explorer.newFile(fileResource.file)
			if (newFile != null)
				reflux.load(newFile.uri.toStr)
		}
	}
}

internal class FoldersTreeModel : ResourceTreeModel {
	@Inject	private  Explorer		explorer
			private	 Color			hiddenColour

	new make(|This|in) {
		in(this)
		this.hiddenColour = Desktop.sysListFg.lighter(0.5f)
	}
	
//	override Str text(Resource resource)		{ resource.name }
//	override Image? image(Resource resource)	{ resource.icon }
//	override Font? font(Resource resource)		{ null }
	override Color? fg(Resource resource)		{ explorer.preferences.isHidden(resource->file) ? hiddenColour : null }
//	override Color? bg(Resource resource)		{ null }
//	override Bool hasChildren(Resource resource){ resource.hasChildren }
//	override Str[] children(Resource resource) 	{ resource.children }
}
