using afIoc
using afReflux
using gfx
using fwt

** (Resource) - 
** Represents a folder on the file system.
class FolderResource : FileResource {
	@Inject private	Explorer		_explorer
	@Inject private	ExplorerCmds	_fileCmds
			private	File[]			osRoots		:= File.osRoots.map { it.normalize }

	internal new make(|This|in) : super.make(in) { }
	
	override Menu populatePopup(Menu m) {
		menu := Menu()
		
		addCmd(menu, _fileCmds.openDirInNewTab(file))
		addCmd(menu, _fileCmds.openFileInSystemCmd(file))
		
		if (!osRoots.contains(file)) {
			menu.addSep
			addCmd(menu, _fileCmds.compressToZip(file))
		}

		return addFileCommands(menu) 
	}
	
	** Returns '[FolderView#]'.
	override Type[] viewTypes() {
		[FolderView#]
	}
}
