using afIoc
using afReflux
using gfx
using fwt

** (Resource) - 
** Represents a folder on the file system.
class FolderResource : FileResource {
	@Inject private FolderPopupMenu	_folderPopupMenu

	internal new make(|This|in) : super.make(in) { }
	
	** Delegates to `FolderPopupMenu`.
	override Menu populatePopup(Menu m) {
		_folderPopupMenu.populatePopup(m, this)
	}
	
	** Returns '[FolderView#]'.
	override Type[] viewTypes() {
		[FolderView#]
	}
}
