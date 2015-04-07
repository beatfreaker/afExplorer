using gfx
using afReflux

** (Resource) - 
** Represents Fantom API documentation.
class FandocResource : Resource {

	override Uri 	uri
	override Str 	name
	override Image?	icon

	@NoDoc
	internal new make(Uri uri, |This|in) {
		in(this)
		this.uri	= uri
		this.name	= uri.name
		this.icon	= Image(`fan://afExplorer/res/icons-file/fileFandoc.png`)
	}
	
	override Type[] viewTypes() {
		[FandocViewer#]
	}
}
