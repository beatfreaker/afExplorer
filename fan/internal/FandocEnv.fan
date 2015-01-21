using compilerDoc::DocEnv
using compilerDoc::DocSpace
using compilerDoc::DocTheme
using compilerDoc::UnknownDocErr
using compilerDoc

internal const class FandocEnv : DefaultDocEnv {
	override DocTheme theme() { FandocTheme() }
	
	override Uri linkUri(DocLink link) {
		uri := super.linkUri(link)
		
		// top doc links don't have anything relative to resolve against
		if (link.from.isTopIndex)
			uri = `fandoc://$uri`
		return uri
	}
	
	override Str? linkUriExt() { Str.defVal }
}
