using gfx
using afReflux

class HttpResource : Resource {

	override Uri 	uri
	override Str 	name
	override Image?	icon

	new make(|This|in) : super.make(in) { }
}
