using compilerDoc::DefaultDocEnv
using compilerDoc::DocLink
using compilerDoc::DocTheme

internal const class FandocEnv : DefaultDocEnv {
	override DocTheme theme() { FandocTheme() }
	
	override Uri linkUri(DocLink link) {
		uri := super.linkUri(link)

		// Note the #frag from super.linkUri(link) is for doc chapters
		
//		// top doc links don't have anything relative to resolve against
//		if (link.from.isTopIndex)
//			uri = `fandoc:/$uri`
		return uri
	}
	
	override Str? linkUriExt() { Str.defVal }
}
