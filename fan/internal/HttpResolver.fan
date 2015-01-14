using afIoc
using afReflux

internal class HttpResolver : UriResolver {
	
	@Inject private Registry	registry
	@Inject private Explorer	explorer

	new make(|This|in) { in(this) }	
	
	override Resource? resolve(Uri uri) {
		if (uri.scheme != "http" && uri.scheme != "https")
			return null
		return registry.autobuild(HttpResource#, null, [
			HttpResource#uri	: uri,
			HttpResource#name	: uri.name,
			HttpResource#icon	: explorer.urlToIcon(uri)
		])
	}	
}
