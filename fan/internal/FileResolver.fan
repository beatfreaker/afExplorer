using afIoc
using afReflux

internal class FileResolver : UriResolver {
	@Inject private Registry	registry
	@Inject private Explorer	explorer

	new make(|This|in) { in(this) }	
	
	override Resource? resolve(Uri uri) {
		if (uri.scheme != "file")
			return null
		file := uri.toFile.normalize
		if (!file.exists)
			return null
		return registry.autobuild(file.isDir ? FolderResource# : FileResource#, null, [
			FileResource#uri	: file.uri,
			FileResource#name	: file.uri.name,
			FileResource#file	: file,
			FileResource#icon	: explorer.fileToIcon(file)
		])
	}	
}
