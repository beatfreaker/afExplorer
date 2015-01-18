using afIoc
using afReflux
using gfx
using fwt
using afBeanUtils

@NoDoc
class FoldersPanel : Panel, RefluxEvents, ExplorerEvents {
	
	@Inject		private Registry			registry
	@Inject		private Reflux				reflux
	@Inject		private RefluxIcons			icons
	@Inject		private UriResolvers		uriResolvers
	@Inject		private Explorer			explorer
	@Inject 	private GlobalCommands		globalCommands
	@Autobuild	private FoldersTreeModel	model
	
	private Combo	combo	:= Combo() { it.onModify.add |e| { this->onComboModify(e) } }
	private Str:Uri	favourites
	private Int		lastComboIndex
	private Tree	tree
	private FolderResource? fileResource
	
	protected new make(|This| in) : super(in) {
		prefAlign	= Halign.left
		
		tree = Tree {
			it.model = this.model
			it.border = false
			it.onMouseDown.add	|e| { this->onMouseDown	(e) }
			it.onPopup.add		|e| { this->onPopup		(e) }
			it.onSelect.add		|e| { this->onSelect	(e) }
			it.onFocus.add		|e| { this->onFocus		( ) }
			it.onBlur.add		|e| { this->onBlur		( ) }
		}
		
		content = EdgePane {
			top = InsetPane(2, 0, 2, 2) { it.add(combo) }
			center = BorderPane {
				it.content	= tree
				it.border	= Border("1, 1, 0, 0 $Desktop.sysNormShadow")
			}
		}
		
		favourites = explorer.preferences.favourites		
		combo.items = favourites.keys
	}

	Void gotoFavourite(Str favourite) {
		uri := explorer.preferences.favourites[favourite] ?: throw ArgNotFoundErr("Favourite does not exist: ${favourite}", explorer.preferences.favourites.keys)
		combo.selected = favourite
	}

	override Void onActivate() {
		globalCommands["afExplorer.cmdShowHiddenFiles"].addEnabler("afExplorer.folderPanel", |->Bool| { true } )
	}
	
	override Void onDeactivate() {
		globalCommands["afExplorer.cmdShowHiddenFiles"].removeEnabler("afExplorer.folderPanel")
	}

	override Void onShowHiddenFiles(Bool show) {
		if (!isShowing || !isActive) return
		refresh
	}

	private Void onSelect() {
		globalCommands["afExplorer.cmdRenameFile"].update
		globalCommands["afExplorer.cmdDeleteFile"].update
	}

	private Void onFocus() {
		fileFetcher := |->File?| {
			tree.selected.isEmpty ? null : ((FileNode) tree.selected.first).file
		}
		cmdR := (RenameFileCommand) globalCommands["afExplorer.cmdRenameFile"]
		cmdR.fileFetcher = fileFetcher
		cmdD := (DeleteFileCommand) globalCommands["afExplorer.cmdDeleteFile"]
		cmdD.fileFetcher = fileFetcher
	}

	private Void onBlur() {
		cmdR := (RenameFileCommand) globalCommands["afExplorer.cmdRenameFile"]
		cmdR.fileFetcher = null
		cmdD := (DeleteFileCommand) globalCommands["afExplorer.cmdDeleteFile"]
		cmdD.fileFetcher = null
	}

	private Void onComboModify(Event event)	{
		if (isActive && combo.selectedIndex >= 0) {
			// this event fires when we switch tabs - then errs when we're not attached! Grr...
			if (lastComboIndex != combo.selectedIndex) {
				lastComboIndex  = combo.selectedIndex
				reflux.load(favourites[combo.selected].toStr)
			}
		}
	}

	private Void onMouseDown(Event event) {
		if (event.button != 1 || event.button != 1)
			return
		node := (FileNode?) tree.nodeAt(event.pos)
		if (node == null)
			return
		reflux.load(node.file.normalize.uri.toStr)
	}

	private Void onPopup(Event event) {
		if (event.data == null) return
		file := ((FileNode) event.data).file
		res	 := uriResolvers.resolve(file.normalize.uri.toStr)
		event.popup = res.populatePopup(Menu())
	}

	override Void onLoad(Resource resource) {
		if (resource isnot FolderResource || !resource.uri.isAbs) return
		fileResource = resource

		if (!isShowing || !isActive) return
		showFile(fileResource.uri)
	}

	override Void refresh()	{
		tree.refreshAll
		Desktop.callLater(50ms) |->| {
			if (fileResource != null)
				showFile(fileResource.uri)
		}
	}
	
	private Void showFile(Uri uri) {
		// it may be ugly, but if it aint broke - don't fix it!
		file	:= (FileNode?) null
		files	:= model.roots
		path	:= uri.path
		path.eachWhile |Str s, Int i->Obj?| {
			found := files.eachWhile |FileNode f->Obj?| {
				if (f.name == s) {
					file = f
					files = model.children(f)
					if (i+1 < path.size) {
						tree.setExpanded(f, true)
					}
					return true
				}
				return null
			}
			return found == true ? null : false
		}
		
		if (file != null) {
			tree.select(file)
			tree.show(file)
		}		
	}
}

internal class FoldersTreeModel : TreeModel {
	@Inject	private  Explorer		explorer
			override FileNode[]		roots
			private	 Color			hiddenColour

	new make(|This|in) {
		in(this)
		this.roots = FileNode.map(explorer, File.osRoots.map { it.normalize })
		this.hiddenColour = Desktop.sysListFg.lighter(0.5f)
	}
	override Str	text(Obj node)			{ n(node).name		}
	override Image?	image(Obj node)			{ explorer.fileToIcon(n(node).file) }
	override Bool 	hasChildren(Obj node)	{ n(node).hasChildren	}
	override FileNode[]	children(Obj node)	{ n(node).children	}
	override Color? fg(Obj node)			{ explorer.preferences.isHidden(n(node).file) ? hiddenColour : null  }
	private  FileNode n(FileNode node)		{ node }
}

internal class FileNode {
	Explorer fe
	File file
	new make(Explorer fe, File file) { this.fe = fe; this.file = file }
	Str name() { file.name }
	Bool hasChildren() { !children.isEmpty }
	FileNode[]? children {
		get {
			if (&children == null)
				&children = map(fe, file.listDirs.sort |f1, f2->Int| { f1.name <=> f2.name }. exclude { fe.preferences.shouldHide(it) })
			return &children
		}
	}
	Void refresh() {
		children = null
	}
	override Str toStr() { return file.toStr }
	static FileNode[] map(Explorer fe, File[] files) {
		files.map { FileNode(fe, it) }
	}
}
