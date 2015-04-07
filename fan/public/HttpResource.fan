using gfx
using afReflux

** (Resource) - 
** Represents a resource available on the Internet.
class HttpResource : Resource {

	override Uri 	uri
	override Str 	name
	override Image?	icon

	@NoDoc
	internal new make(Uri url, Explorer explorer, |This|in) {
		in(this)
		this.uri	= url
		this.name	= url.name
		this.icon	= explorer.urlToIcon(url)
	}
	
	override Type[] viewTypes() {
		[HtmlViewer#]
	}
}
