using afIoc
using afReflux

internal class FileResolver : UriResolver {
	@Inject private Registry	registry
	@Inject private Explorer	explorer

	new make(|This|in) { in(this) }	
	
	override Resource? resolve(Str uri) {
		file := (File?) null

		// check for some special cases
		if (uri == "\${Env.cur.homeDir}")
			file = Env.cur.homeDir.normalize
		if (uri == "\${Env.cur.workDir}")
			file = Env.cur.workDir.normalize
		if (uri == "\${Env.cur.tempDir}")
			file = Env.cur.tempDir.normalize
		
		// check for os specific paths
		if (file == null)
			try {
				file = File.os(uri).normalize
			} catch { }
		
		// check for standard file: scheme URIs
		if (file == null)
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
