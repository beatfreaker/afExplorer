using fandoc::Doc
using fandoc::DocElem
using fandoc::DocNodeId
using fandoc::DocText
using fandoc::HtmlDocWriter
using fandoc::Para
using web::WebOutStream

internal class FandocWriter : HtmlDocWriter {
	private StrBuf			buff
	private Uri?			base
	private WebOutStream	web

	static new fromNew(Uri? base) {
		FandocWriter(StrBuf(), base)
	}
	
	new make(StrBuf buff, Uri? base) : super(buff.out) {
		this.buff 	= buff
		this.web 	= WebOutStream(buff.out)
		this.base 	= base
	}

	override Void docStart(Doc doc) {
		super.docStart(doc)
		
		web.div("class='mainSidebar'")
		web.div("class='main type'")
	}
	
	override Void docEnd(Doc doc) {
		web.divEnd
		web.divEnd		
	}

	override Void docHead(Doc doc) {
		super.docHead(doc)
		
		if (base.scheme == "file") {
			web.tag("base", "href='${base.toFile.normalize.osPath}'")
		}
		
		// we can't link to anything (unless we start our own web server) so just embedd the css
		web.style("type='text/css'")
		web.printLine(cssAsStr(true))
		web.styleEnd
	}
	
	Str toHtml() {
		buff.toStr
	}
	
	** Returns the CSS for fandoc as a Str. 'skinny' CSS is used for '.fandoc' files .  
	private static Str cssAsStr(Bool skinny) {
		cssFileName := skinny ? "fandoc-skinny.css" : "fandoc.css"
		
		// look for a file in the 'etc' dir, if not, load a default css from the pod 
		cssFile := Env.cur.findFile(`etc/${Explorer#.pod.name}/${cssFileName}`, false)
		if (cssFile == null)
			cssFile =  Explorer#.pod.file(`/res/css/${cssFileName}`)
		return cssFile.in.readAllStr
	}
}

