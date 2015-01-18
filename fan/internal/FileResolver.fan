using afIoc
using afReflux

internal class FileResolver : UriResolver {
	@Inject private Registry	registry
	@Inject private Explorer	explorer

	new make(|This|in) { in(this) }	
	
	override Resource? resolve(Str uri) {
		file := (File?) null

		try {
			file = File.os(uri).normalize
		} catch { }
		
		try {
			if (uri.toUri.scheme == "file")
				file = uri.toUri.toFile.normalize
		} catch { }

		if (file == null || !file.exists)
			return null

		return registry.autobuild(file.isDir ? FolderResource# : FileResource#, null, [
			FileResource#uri	: file.uri,
			FileResource#name	: file.uri.name,
			FileResource#file	: file,
			FileResource#icon	: explorer.fileToIcon(file)
		])
	}	
}
