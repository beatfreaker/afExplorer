using afIoc
using afReflux
using gfx
using fwt

** (Resource) - 
** Represents a file on the file system or a pod resource.
class FileResource : Resource {
	@Inject private Explorer		_explorer
	@Inject private FileViewers		_fileViewers
	@Inject private FilePopupMenu	_filePopupMenu

	override Uri 	uri
	override Str 	name
	override Image?	icon
	override Str	displayName
			 File	file

	internal new make(File file, Explorer explorer, |This|in) {
		in(this)
		file				= file.normalize
		this.file			= file
		this.uri			= file.uri
		this.name			= file.uri.name
		this.icon			= explorer.fileToIcon(file)
		this.displayName	= file.osPath ?: file.toStr	// fan: schemes don't have osPaths
	}

	override Str[] children() {
		_children.map { it.uri.toStr }
	}

	override Bool hasChildren() {
		_children.size > 0
	}
	
//	override Resource? resolveChild(Str childUri) {
//		_children.find { it.uri == childUri }
//	}
	
	override Str? parent() { _parent?.uri?.toStr }
	
	** Delegates to `FilePopupMenu`.
	override Menu populatePopup(Menu m) {
		_filePopupMenu.populatePopup(m, this)
	}

	override Type[] viewTypes() {
		_fileViewers.getTypes(file.ext)
	}
	
	private once File[]	_children() {
		file.listDirs.sort |f1, f2->Int| { f1.name <=> f2.name }. exclude { _explorer.preferences.shouldHide(it) }
	}

	private once File? _parent() {
		File.osRoots.any { it.normalize == file } ? null : file.parent?.normalize
	}
}
