using afIoc
using afReflux

internal class FileResolver : UriResolver {
	@Inject private Registry	registry
	@Inject private Explorer	explorer

	new make(|This|in) { in(this) }	
	
	override Resource? resolve(Str str) {
		file := (File?) null

		// check for some special cases
		if (str == "\${Env.cur.homeDir}")
			file = Env.cur.homeDir.normalize
		if (str == "\${Env.cur.workDir}")
			file = Env.cur.workDir.normalize
		if (str == "\${Env.cur.tempDir}")
			file = Env.cur.tempDir.normalize
		
		// check for os specific paths
		if (file == null)
			try {
				file = File.os(str).normalize
			} catch { }
		
		// check for standard file: scheme URIs
		if (file == null)
			try {
				uri := str.toUri
				if (uri.scheme == "fan")
					file = uri.get
				if (uri.scheme == "file")
					file = uri.toFile.normalize
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
