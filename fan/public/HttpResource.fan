using gfx
using afReflux

** (Resource) - 
** Represents a resource available on the Internet.
class HttpResource : Resource {

	override Uri 	uri
	override Str 	name
	override Image?	icon

	@NoDoc
	new make(|This|in) { in(this) }
	
	override Type[] viewTypes() {
		[HtmlViewer#]
	}
}
