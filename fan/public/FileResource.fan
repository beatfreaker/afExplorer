using afIoc
using afReflux
using gfx
using fwt

** (Resource) - 
** Represents a file on the file system or a pod resource.
class FileResource : Resource {
	@Inject private Explorer				_explorer
	@Inject private FileViewers				_fileViewers
	@Inject private FilePopupMenu			_filePopupMenu
	@Inject private |File->FileResource|	_fileFactory

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

	override Uri[] children() {
		_children.keys
	}

	override Bool hasChildren() {
		_children.size > 0
	}
	
	override Uri? parent() { _parent?.uri }
	
	** Delegates to `FilePopupMenu`.
	override Menu populatePopup(Menu m) {
		_filePopupMenu.populatePopup(m, this)
	}

	override Type[] viewTypes() {
		_fileViewers.getTypes(file.ext)
	}
	
	override once Resource? resolveParent() {
		_parent == null ? null : _fileFactory(_parent)
	}
	
	private once Uri:FileResource _children() {
		files := (FileResource[]) file.listDirs.sort |f1, f2->Int| { f1.name.compareIgnoreCase(f2.name) }.exclude { _explorer.preferences.shouldHide(it) }.map { _fileFactory(it) }
		return Uri:FileResource[:] { ordered = true }.addList(files) { it.uri }
	}

	private once File? _parent() {
		_explorer.osRoots.any { it.normalize == file } ? null : file.parent?.normalize
	}
}
