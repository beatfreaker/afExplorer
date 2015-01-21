using gfx
using afReflux

** (Resource) - 
** Represents Fantom API documentation.
class FandocResource : Resource {

	override Uri 	uri
	override Str 	name
	override Image?	icon

	@NoDoc
	new make(|This|in) : super.make(in) { }
	
	override Type[] viewTypes() {
		[FandocViewer#]
	}
}
