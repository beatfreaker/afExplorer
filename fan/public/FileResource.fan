using afIoc
using afReflux
using gfx
using fwt

** (Resource) - 
** Represents a file on the file system or a pod resource.
class FileResource : Resource {
	@Inject private FileViewers		_fileViewers
	@Inject private FilePopupMenu	_filePopupMenu

	override Uri 	uri
	override Str 	name
	override Image?	icon
	override Str	displayName
			 File	file

	internal new make(|This|in) {
		in(this)
		displayName = file.osPath ?: file.toStr	// fan: schemes don't have osPaths
	}

	** Delegates to `FilePopupMenu`.
	override Menu populatePopup(Menu m) {
		_filePopupMenu.populatePopup(m, this)
	}

	override Type[] viewTypes() {
		_fileViewers.getTypes(file.ext)
	}
}
