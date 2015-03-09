
@NoDoc
class FileViewers {
	private Str:FileViewMapping[] extViewers	:= Str:FileViewMapping[][:]
	
	internal new make(FileViewMapping[] extViewers) {
		extViewers.each |viewer| {
			this.extViewers.getOrAdd(viewer.ext) { FileViewMapping[,] }.add(viewer)
		}
	}
	
	FileViewMapping[] getViewers(Str? ext) {
		ext == null ? Type#.emptyList : (extViewers[ext] ?: Type#.emptyList)
	}

	Type[] getTypes(Str? ext) {
		getViewers(ext).map { it.viewType }
	}
}

@NoDoc
class FileViewMapping {
	Str		ext
	Type	viewType

	new make(Str ext, Type viewType) {
		this.ext		= ext
		this.viewType	= viewType
	}
}
