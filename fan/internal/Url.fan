
** A wrapper around a URI
internal class Url {
	private Str?	scheme
	private Str?	auth
	private Str?	path
	private Str?	query
	private Str?	frag

	new make(Uri? uri) {
		this.scheme	= uri?.scheme
		this.auth	= uri?.auth
		this.path	= uri?.pathStr
		this.query	= uri?.queryStr
		this.frag	= uri?.frag
	}
	
	This plusQuery(Str? query) {
		this.query = query?.trimToNull
		return this
	}

	This minusQuery() {
		this.query = null
		return this
	}

	This plusFrag(Str? frag) {
		this.frag = frag?.trimToNull
		return this
	}

	This minusFrag() {
		this.frag = null
		return this
	}
	
	Uri toUri() {
		scheme	:= this.scheme != null ? "${this.scheme}:" : ""
		auth	:= this.auth   != null ? "//${this.auth}"  : ""
		path	:= this.path   != null ? path              : ""
		query	:= this.query  != null ? "?${this.query}"  : ""
		frag	:= this.frag   != null ? "#${this.frag}"   : ""
		return (scheme + auth + path + query + frag).toUri		
	}
	
	@NoDoc
	override Bool equals(Obj? that) {
		toUri == (that as Url)?.toUri
	}
	
	@NoDoc
	override Int hash() {
		toUri.hash
	}

	@NoDoc
	override Int compare(Obj that) {
		toUri <=> (that as Url)?.toUri
	}
	
	@NoDoc
	override Str toStr() { toUri.toStr }
}
