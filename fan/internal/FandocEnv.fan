using compilerDoc::DefaultDocEnv
using compilerDoc::DocLink
using compilerDoc::DocTheme
using compilerDoc::Doc

internal const class FandocEnv : DefaultDocEnv {
	override DocTheme theme() { FandocTheme() }
	
	override Uri linkUri(DocLink link) {
		uri := ""

		if (link.from.isTopIndex)
			uri += link.target.space.spaceName + "/"
		else if (link.from.space !== link.target.space)
			uri += "../" + link.target.space.spaceName + "/"
	
		docName := link.target.docName
		
		fromDoc := "err"	// topIndex throws UnsupportedErr
		try fromDoc = link.from.docName
		catch {}
		
		// DON'T write `index#wotever` but rather `#wotever` so the SWT browser can perform internal linking
		if (fromDoc != docName) {
			if (docName == "pod-doc")
				docName = "index"
			uri += docName
		}

		if (link.frag != null)
			uri += "#" + link.frag

		// Un-convert (from the build system) http resources to local
		//   - http://fantom.org/doc/flux/index      --> fandoc:/flux/index
		//   - http://repo.status302.com/doc/afSlim/ --> fandoc:/afSlim

		return uri.toUri
	}
	
	override DocLink? link(Doc from, Str link, Bool checked := true) {
		return super.link(from, link, checked)
	}
	
	override Str? linkUriExt() { Str.defVal }
}
