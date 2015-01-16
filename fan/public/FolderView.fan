using afIoc
using gfx
using fwt
using afReflux

@NoDoc
class FolderView : View, RefluxEvents, ExplorerEvents {
	
	@Inject private Registry		registry
	@Inject private Reflux			reflux
	@Inject private RefluxIcons		icons
	@Inject private UriResolvers	uriResolvers
	@Inject	private Explorer		explorer
	@Inject private GlobalCommands	globalCommands
	@Autobuild private FileResolver	fileResolver
	@Autobuild private FolderViewModel model
			private	Table			table
			private FolderResource? fileResource

	protected new make(|This| in) : super(in) {
		this.reuseView = true
		this.content = table = Table {
			it.multi = true
			it.onAction.add |e| { this->onAction (e) }
			it.onPopup.add	|e| { this->onPopup  (e) }
			it.onSelect.add	|e| { this->onSelect (e) }
			it.onFocus.add	|e| { this->onFocus  ( ) }
			it.onBlur.add	|e| { this->onBlur   ( ) }
			it.border = false
			it.model = this.model
		}
	}
	
	override Void onActivate() {
		globalCommands["afExplorer.cmdShowHiddenFiles"].addEnabler("afExplorer.folderView", |->Bool| { true } )
	}
	
	override Void onDeactivate() {
		globalCommands["afExplorer.cmdShowHiddenFiles"].removeEnabler("afExplorer.folderView")
	}

	override Void refresh() {
		super.load(resource)	// update tab details
		model.fileRes = fileResource.file.listDirs.addAll(fileResource.file.listFiles).exclude { explorer.preferences.shouldHide(it) }.map { fileResolver.resolve(it.uri) }
		try table.refreshAll
		catch {}	// supurius FWT errors - see http://fantom.org/forum/topic/2390
	}

	override Void load(Resource resource) {
		if (this.resource == resource) return
		this.resource = resource
		this.fileResource = resource
		refresh
	}
	
	override Void onShowHiddenFiles(Bool show) {
		load(fileResource)
	}

	private Void onSelect() {
		globalCommands["afExplorer.cmdRenameFile"].update
		globalCommands["afExplorer.cmdDeleteFile"].update
	}

	private Void onFocus() {
		fileFetcher := |->File?| { 
			table.selected.isEmpty ? null : model.fileRes[table.selected.first].file 
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

	private Void onPopup(Event event) {
		if (event.index != null) {
			fileRes := model.fileRes[event.index]
			event.popup = fileRes.populatePopup(Menu())
		} else
			event.popup = fileResource?.populatePopup(Menu())
	}

	private Void onAction(Event event) {
		if (event.index != null) {
			fileRes := model.fileRes[event.index]
			fileRes.doAction
		}
	}
}


internal class FolderViewModel : TableModel {
	@Inject private LocaleFormat	locale
	@Inject private UriResolvers	uriResolvers
	@Inject	private Explorer		explorer
			private	Color			hiddenColour
	
	FileResource[]? fileRes
	Str[] headers := ["Name", "Size", "Modified"]
	Int[] width	  := [280, 70, 110]

	new make(|This| in) {
		in(this)
		this.hiddenColour = Desktop.sysListFg.lighter(0.5f)
	}
	
	override Int numCols() { return 3 }
	override Int numRows() { return fileRes?.size ?: 0 }
	override Str header(Int col) { return headers[col] }
	override Halign halign(Int col) { return col == 1 ? Halign.right : Halign.left }
	override Int? prefWidth(Int col) { width[col] }
	override Color? fg(Int col, Int row) { explorer.preferences.isHidden(fileRes[row].file) ? hiddenColour : null }

	override Str text(Int col, Int row) {
		f := fileRes[row]
		switch (col) {
			case 0:	return f.file.name
			case 1:	return locale.formatFileSize(f.file.size)
			case 2:	return locale.formatDateTime(f.file.modified)
			default: return "???"
		}
	}

	override Int sortCompare(Int col, Int row1, Int row2) {
		a := fileRes[row1].file
		b := fileRes[row2].file
		
		// keep directories at the top (unless we're doing a descending sort)
		if (a.isDir != b.isDir)
			return b.isDir <=> a.isDir
		switch (col) {
			case 0:	return a.name.compareIgnoreCase(b.name)
			case 1:	return a.size <=> b.size
			case 2:	return a.modified <=> b.modified
			default: return super.sortCompare(col, row1, row2)
		}
	}

	override Image? image(Int col, Int row) {
		return (col == 0) ? fileRes[row].icon : null
	}
}