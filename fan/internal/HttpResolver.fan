using afIoc
using afReflux

internal class HttpResolver : UriResolver {
	
	@Inject private Registry	registry
	@Inject private Explorer	explorer

	new make(|This|in) { in(this) }	
	
	override Resource? resolve(Str str) {
		url := (Uri?) null

		if (url == null)
			if (str.startsWith("www."))
				url = `http://${str}`
		
		if (url == null)
			try {
				uri := str.toUri
				if (uri.scheme == "http" || uri.scheme == "https")
					url = uri 
			} catch { }
		
		if (url == null)
			return null
		
		return registry.autobuild(HttpResource#, [url])
	}	
}
