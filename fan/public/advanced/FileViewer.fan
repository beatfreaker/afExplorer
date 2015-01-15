
class FileViewers {
	private Str:FileViewer[] extViewers	:= Str:FileViewer[][:]
	
	internal new make(FileViewer[] extViewers) {
		extViewers.each |viewer| {
			this.extViewers.getOrAdd(viewer.ext) { FileViewer[,] }.add(viewer)
		}
	}
	
	FileViewer[] getViewers(Str? ext) {
		ext == null ? Type#.emptyList : (extViewers[ext] ?: Type#.emptyList)
	}

	Type[] getTypes(Str? ext) {
		getViewers(ext).map { it.viewType }
	}
}

class FileViewer {
	Str		ext
	Type	viewType

	new make(Str ext, Type viewType) {
		this.ext		= ext
		this.viewType	= viewType
	}
}
