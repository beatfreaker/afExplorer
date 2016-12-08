using afIoc
using gfx
using fwt
using afReflux
using afConcurrent
using concurrent

@NoDoc
class FolderView : View, RefluxEvents, ExplorerEvents {
	
	static 	const private	|File,File->Int|	byName	 := |File f1, File f2 -> Int| { f1.name.compareIgnoreCase(f2.name) }

	@Inject private Registry			registry
	@Inject private Reflux				reflux
	@Inject private RefluxIcons			icons
	@Inject	private Explorer			explorer
	@Inject private GlobalCommands		globalCommands
	@Autobuild private FolderMonitor	monitorThread
	@Autobuild private FileResolver		fileResolver
	@Autobuild private FolderViewModel	model
			private	Table				table
			private FolderResource? 	fileResource
			private	Bool				refreshOnActivate

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

	override Void onShow() {
		monitorThread.start(reflux, this)
	}

	override Void onHide() {
		monitorThread.stop
	}

	override Void onActivate() {
		globalCommands["afExplorer.cmdShowHiddenFiles"	].addEnabler("afExplorer.folderView", |->Bool| { true } )
		if (refreshOnActivate) {
			refreshOnActivate = false
			refresh(resource)
		}
	}

	override Void onDeactivate() {
		onBlur	// onBlur doesn't always fire when we switch tabs
		globalCommands["afExplorer.cmdShowHiddenFiles"	].removeEnabler("afExplorer.folderView")
	}

	override Void refresh(Resource? resource := null) {
		if (resource == this.resource || ((resource as FileResource)?.file?.parent == this.fileResource?.file) || resource == null) {
			monitorThread.refresh(resource)

			if (!isActive) {
				refreshOnActivate = true
				return
			}

			super.load(this.resource)	// update tab details
			model.fileRes = fileResource.file.listDirs.sort(byName).addAll(fileResource.file.listFiles.sort(byName)).exclude { explorer.preferences.shouldHide(it) }.map { fileResolver.resolve(it.uri.toStr) }
			try table.refreshAll
			catch {}	// spurious FWT errors - see http://fantom.org/forum/topic/2390
		}
	}

	override Void load(Resource resource) {
		if (this.resource == resource) return
		monitorThread.refresh(resource)

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
		// be aware that this can return null, should the view be auto-refreshed
		fileFetcher := |->File?| { 
			table.selected.isEmpty ? null : model.fileRes[table.selected.first].file 
		}

		globalCommands["afExplorer.cmdRenameFile"].addEnabler("afExplorer.folderView", |->Bool| { !table.selected.isEmpty } )
		globalCommands["afExplorer.cmdDeleteFile"].addEnabler("afExplorer.folderView", |->Bool| { !table.selected.isEmpty } )
		globalCommands["afReflux.cmdCut"		].addEnabler("afExplorer.folderPanel", |->Bool| { !table.selected.isEmpty } )
		globalCommands["afReflux.cmdCopy"		].addEnabler("afExplorer.folderPanel", |->Bool| { !table.selected.isEmpty } )
		globalCommands["afReflux.cmdPaste"		].addEnabler("afExplorer.folderPanel", |->Bool| { explorer.pasteEnabled && (fileFetcher() != null || fileResource != null) } )
		globalCommands["afReflux.cmdCut"		].addInvoker("afExplorer.folderPanel", |->|		{ file := fileFetcher(); if (file != null) explorer.cut (file) } )
		globalCommands["afReflux.cmdCopy"		].addInvoker("afExplorer.folderPanel", |->|		{ file := fileFetcher(); if (file != null) explorer.copy(file) } )
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
		if ((f as Obj) == null) return "???"	// for locked files - expect errors to follow shortly!
		switch (col) {
			case 0:	return f.file.name
			case 1:	return locale.fileSize(f.file.size)
			case 2:	return locale.dateTime(f.file.modified)
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


internal const class FolderMonitor {
	@Inject { id="afExplorer.folderMonitor" }
			private const Synchronized	monitorThread
	@Inject	private const LocalRef		stateRef

	new make(|This| f) { f(this) }
	
	Void start(Reflux reflux, FolderView view) {
		viewRef   := Unsafe(view)
		refluxRef := Unsafe(reflux)
		monitorThread.async |->| {
			if (stateRef.val == null)
				stateRef.val = FolderMonitorState(refluxRef, this)
			state.start
		}
	}
	
	Void stop() {
		monitorThread.async |->| {
			state.stop			
		}		
	}
	
	Void refresh(FolderResource? fileResource) {
		file := fileResource?.file
		monitorThread.async |->| {
			state.refresh(file)
		}
	}
	
	Void checkIn(Duration d) {
		monitorThread.asyncLater(d) |->| {
			state.check
		}
	}
	
	private FolderMonitorState state() {
		stateRef.val
	}
}

internal class FolderMonitorState {
	Unsafe			refluxRef
	FolderMonitor	monitor
	Bool			running
	File?			folder
	Int?			checksum
	Duration?		checksumTs
	Duration		every		:= 5sec
	
	new make(Unsafe refluxRef, FolderMonitor monitor) {
		this.refluxRef	= refluxRef
		this.monitor	= monitor
	}

	Void start() {
		this.running = true
		monitor.checkIn(every)
	}
	
	Void stop() {
		this.running = false
	}
	
	Void refresh(File? folder) {
		this.folder 	= folder ?: this.folder
		this.checksum	= crc
	}
	
	Void check() {
		if (!running || folder == null) return
		
		crc := crc
		if (checksum  != crc) {
			checksum   = crc
			refluxRef := refluxRef
			folder	  := folder
			Desktop.callAsync |->| {
				reflux := (Reflux) refluxRef.val
				folderRes := reflux.scope.build(FolderResource#, [folder])
				reflux.refresh(folderRes)
			}
		}
		monitor.checkIn(every)
	}
	
	private Int? crc() {
		if (folder == null)
			return null
		
		now := Duration.now
		if (checksumTs != null && (now - checksumTs) < 1sec)
			return checksum

		checksumTs = now

		buf := Buf()
		folder.list.sort |f1, f2| { f1.name <=> f2.name  }.each |f| {
			buf.printLine("${f.name}  ${f.modified?.toIso}")				
		}
		return buf.crc("CRC-32-Adler")
	}
}
