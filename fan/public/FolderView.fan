using afIoc
using gfx
using fwt
using afReflux

@NoDoc
class FolderView : View, RefluxEvents, ExplorerEvents {
	
	@Inject private Registry		registry
	@Inject private Reflux			reflux
	@Inject private RefluxIcons		icons
	@Inject	private Explorer		explorer
	@Inject private GlobalCommands	globalCommands
	@Autobuild private FileResolver	fileResolver
	@Autobuild private FolderViewModel model
			private	Table			table
			private FolderResource? fileResource

	protected new make(|This| in) : super(in) {
		this.content = table = Table {
			it.multi = false
			it.onAction.add |e| { this->onAction (e) }
			it.onPopup.add	|e| { this->onPopup  (e) }
			it.onSelect.add	|e| { this->onSelect (e) }
			it.onFocus.add	|e| { this->onFocus  ( ) }
			it.onBlur.add	|e| { this->onBlur   ( ) }
			it.border = false
			it.model = this.model
		}
	}
	
	override Bool reuseView(Resource resource) { true }
	
	override Void onActivate() {
		globalCommands["afExplorer.cmdShowHiddenFiles"	].addEnabler("afExplorer.folderView", |->Bool| { true } )
	}
	
	override Void onDeactivate() {
		onBlur	// onBlur doesn't always fire when we switch tabs
		globalCommands["afExplorer.cmdShowHiddenFiles"	].removeEnabler("afExplorer.folderView")
	}

	override Void refresh(Resource? resource := null) {
		if (resource == this.resource || ((resource as FileResource)?.file?.parent == this.fileResource?.file) ||  resource == null) {
			super.load(this.resource)	// update tab details
			model.fileRes = fileResource.file.listDirs.addAll(fileResource.file.listFiles).exclude { explorer.preferences.shouldHide(it) }.map { fileResolver.resolve(it.uri.toStr) }
			try table.refreshAll
			catch {}	// supurius FWT errors - see http://fantom.org/forum/topic/2390
		}
	}

	override Void load(Resource resource) {
		if (this.resource == resource) return
		this.resource = resource
		this.fileResource = resource
		// revert sorting when showing new resources  
		this.table.sort(null)
		refresh
	}
	
	override Void onShowHiddenFiles(Bool show) {
		refresh(null)
	}

	override Void onRename(File oldFile, File newFile) {
		resource := reflux.resolve(newFile.osPath)
		idx := model.fileRes.index(resource)
		if (idx != null)
			table.selected = [idx]
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
			table.selected.isEmpty ? null : model.fileRes[table.selected.first].file 
		}

		globalCommands["afExplorer.cmdRenameFile"].addEnabler("afExplorer.folderView", |->Bool| { !table.selected.isEmpty } )
		globalCommands["afExplorer.cmdDeleteFile"].addEnabler("afExplorer.folderView", |->Bool| { !table.selected.isEmpty } )
		globalCommands["afReflux.cmdCut"		].addEnabler("afExplorer.folderPanel", |->Bool| { !table.selected.isEmpty } )
		globalCommands["afReflux.cmdCopy"		].addEnabler("afExplorer.folderPanel", |->Bool| { !table.selected.isEmpty } )
		globalCommands["afReflux.cmdPaste"		].addEnabler("afExplorer.folderPanel", |->Bool| { explorer.pasteEnabled && (fileFetcher() != null || fileResource != null) } )
		globalCommands["afReflux.cmdCut"		].addInvoker("afExplorer.folderPanel", |->|		{ explorer.cut(fileFetcher()) } )
		globalCommands["afReflux.cmdCopy"		].addInvoker("afExplorer.folderPanel", |->|		{ explorer.copy(fileFetcher()) } )
		globalCommands["afReflux.cmdPaste"		].addInvoker("afExplorer.folderPanel", |->|		{ explorer.paste(fileFetcher() ?: fileResource.file) } )

		cmdR := (RenameFileCommand) globalCommands["afExplorer.cmdRenameFile"]
		cmdR.fileFetcher = fileFetcher
		cmdD := (DeleteFileCommand) globalCommands["afExplorer.cmdDeleteFile"]
		cmdD.fileFetcher = fileFetcher
	}

	private Void onBlur() {
		globalCommands["afExplorer.cmdRenameFile"].removeEnabler("afExplorer.folderView")
		globalCommands["afExplorer.cmdDeleteFile"].removeEnabler("afExplorer.folderView")
		globalCommands["afReflux.cmdCut"		].removeEnabler("afExplorer.folderPanel")
		globalCommands["afReflux.cmdCopy"		].removeEnabler("afExplorer.folderPanel")
		globalCommands["afReflux.cmdPaste"		].removeEnabler("afExplorer.folderPanel")
		globalCommands["afReflux.cmdCut"		].removeInvoker("afExplorer.folderPanel")
		globalCommands["afReflux.cmdCopy"		].removeInvoker("afExplorer.folderPanel")
		globalCommands["afReflux.cmdPaste"		].removeInvoker("afExplorer.folderPanel")
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
			
			// show view if there is one 
			if (!fileRes.viewTypes.isEmpty) {
				ctx := (event.key != null && event.key.isCtrl) ? LoadCtx() { it.newTab = true } : LoadCtx()
				reflux.loadResource(fileRes, ctx)
				return
			}
	
			if (fileRes.file.isDir) {
				ctx := (event.key != null && event.key.isCtrl) ? LoadCtx() { it.newTab = true } : LoadCtx()
				reflux.loadResource(fileRes, ctx)
				return			
			}
			
			// else launch it
			Desktop.launchProgram(fileRes.uri)
		}
	}
}


internal class FolderViewModel : TableModel {
	@Inject private LocaleFormat	locale
	@Inject private Reflux			reflux
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