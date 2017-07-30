using afIoc
using afReflux

internal class FileResolver : UriResolver {
	@Inject private Scope		scope
	@Inject private Explorer	explorer

	new make(|This|in) { in(this) }	
	
	override Resource? resolve(Str str) {

		// check for some special cases
		str = str.replace("\${Env.cur.homeDir}",	Env.cur.homeDir.normalize.osPath)
		str = str.replace("\${Env.cur.workDir}",	Env.cur.workDir.normalize.osPath)
		str = str.replace("\${Env.cur.tempDir}",	Env.cur.tempDir.normalize.osPath)
		str = str.replace("\${Env.cur.user}", 		Env.cur.user)

		uri  := toFileUri(str)
		file := null as File
		try	file = uri?.toFile
		catch { /* meh */ }	// "afIoc::Registry" throws ArgErr: Invalid Uri scheme for local file

		if (file == null || !file.exists)
			return null

		return scope.build(file.isDir ? FolderResource# : FileResource#, [file])
	}
	
	** This method has been copied from afFish::FileUtils
	static Uri? toFileUri(Str path) {
		dot := false
		if (path.endsWith("/.") || path.endsWith("\\.")) {
			dot = true
			path = path[0..<-2]
		}

		file := null as File
		try
			file = !path.startsWith("file:") && (path.containsChar('\\') || path.containsChar(':'))
				? File.os(path)
				: File(path.toUri, false)
		// sys::IOErr: Must use trailing slash for dir: ..
		catch (IOErr err)
			file = File(path.toUri, false)
		// sys::ParseErr: Invalid Uri: '//:c'
		catch (ParseErr err)
			file = File(path.toUri, false)

		if (dot)
			file = file.plus(``.plusName("."))
		
		// return null for nonsense filename, e.g. dd: throws
		//   java.io.IOException: The filename, directory name, or volume label syntax is incorrect
		try 	file.normalize
		catch	return null

		// paths such as `d:` or `/c:` aren't handled correctly, so do it manually
		if (path.size == 2 && path[0].isAlpha && path[1] == ':')
			file = File(`/${path}/`).normalize
		else 
		if (path.size == 3 && path[0] == '/' && path[1].isAlpha && path[2] == ':')
			file = File(`${path}/`).normalize

		uri := file.uri
		if (!uri.isDir && (path.getSafe(-1) == '/' || path.getSafe(-1) == '\\'))
			uri = uri.plusSlash
		return uri
	}

}
