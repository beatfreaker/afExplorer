using gfx
using afReflux

** (Resource) - 
** Represents Fantom API documentation.
class FandocResource : Resource {

	override Uri 	uri
	override Str 	name
	override Image?	icon

	@NoDoc
	new make(|This|in) { in(this) }
	
	override Type[] viewTypes() {
		[FandocViewer#]
	}
}
