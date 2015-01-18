using afIoc
using afReflux

internal class HttpResolver : UriResolver {
	
	@Inject private Registry	registry
	@Inject private Explorer	explorer

	new make(|This|in) { in(this) }	
	
	override Resource? resolve(Str str) {
		try {
			uri := str.toUri
			if (uri.scheme == "http" || uri.scheme == "https")
				return registry.autobuild(HttpResource#, null, [
					HttpResource#uri	: uri,
					HttpResource#name	: uri.name,
					HttpResource#icon	: explorer.urlToIcon(uri)
				])
		} catch { }
		
		return null
	}	
}
