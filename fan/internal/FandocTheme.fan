using compilerDoc::Doc
using compilerDoc::DocChapter
using compilerDoc::DocPodIndex
using compilerDoc::DocRenderer
using compilerDoc::DocSrc
using compilerDoc::DocTheme
using web::WebOutStream

** The theme used for styling Fandoc documention. The default theme looks like the Fantom website.
** 
** To override, create the following CSS files:
**  - '%FAN_HOME%/etc/afFandocViewer/fandoc.css' for styling pod documentation. 
**  - '%FAN_HOME%/etc/afFandocViewer/fandoc-skiny.css' for styling '.fandoc' file. This usually a 
** subset of 'fandoc.css'. 
const class FandocTheme : DocTheme {

	** Write opening HTML for page.  This should generate the doc type, html, head, and opening body tags.  
	override Void writeStart(DocRenderer r) {
		out := r.out
		out.docType
		out.html
		out.head
			.title.esc(r.doc.title).titleEnd
			.printLine("<meta http-equiv='Content-Type' content='text/html; charset=UTF-8'/>")
			.style
				.print(cssAsStr(false))
			.styleEnd		
		out.headEnd
		out.body
	}
	
	override Void writeBreadcrumb(DocRenderer r) {
		out := r.out
		out.div("class='header'")
		out.div
		out.a(`fandoc://`)
		out.img(`http://fantom.org/pod/fantomws/res/img/fantom.png`)
		out.aEnd
		out.divEnd
		out.divEnd

		out.div("class='subHeader'")
		out.div
		writeCrumbs(r)
		out.divEnd
		out.divEnd
		
		// a hack to wrap Manual content in a div to give padding
		if (isManual(r.doc)) {
			out.div("class='manual'")
			out.div
		}		
	}

	** Write closing HTML for page.  This should generate the common footer and close the body and html tags.
	override Void writeEnd(DocRenderer r) {
		out := r.out
		if (isManual(r.doc)) {
			out.divEnd
			out.divEnd
		}

		out.div("class='footer'")
		// Hello me!
		out.a(`http://www.fantomfactory.org/pods/afExplorer`).w("Explorer v${typeof.pod.version}").aEnd
		out.divEnd

		out.bodyEnd
		out.htmlEnd
	}
	
	Void writeCrumbs(DocRenderer r) {
		out := r.out
		doc := r.doc
		out.div("class='breadcrumb'").ul
		
		if (doc.isTopIndex) {
			writeCrumb(out, `fandoc://`, "Doc Index", true)
			
		} else {
			writeCrumb(out, `fandoc://`, "Doc Index", false)
			writeCrumb(out, `../index`, r.doc.space.breadcrumb, doc.isSpaceIndex)
			
			if (doc.isSpaceIndex) {
				// skip
			} else if (doc is DocChapter) {
				writeCrumb(out, `${doc.docName}`, r.doc.title, true)
				
			} else if (doc is DocSrc) {
				src := (DocSrc)doc
				type := src.pod.type(src.uri.basename, false)
				if (type != null)
					writeCrumb(out, `${doc.docName}`, type.breadcrumb, true)
				else
					writeCrumb(out, `${doc.docName}`, src.breadcrumb, true)
				
			} else {
				writeCrumb(out, `${doc.docName}`, r.doc.breadcrumb, true)
			}
		}
		out.ulEnd.divEnd		
	}
	
	private Void writeCrumb(WebOutStream out, Uri link, Str text, Bool last) {
		out.span
		out.a(link).w(text).aEnd
		if (!last)
			out.w(" > ")
		out.spanEnd
	}
	
	** Returns the CSS for fandoc as a Str. 'skinny' CSS is used for '.fandoc' files .  
	internal static Str cssAsStr(Bool skinny) {
		cssFileName := skinny ? "fandoc-skinny.css" : "fandoc.css"
		
		// look for a file in the 'etc' dir, if not, load a default css from the pod 
		cssFile := Env.cur.findFile(`etc/${FandocTheme#.pod.name}/${cssFileName}`, false)
		if (cssFile == null)
			cssFile =  FandocTheme#.pod.file(`/res/css/${cssFileName}`)
		return cssFile.in.readAllStr
	}
		
	private static Bool isManual(Doc doc) {
		doc is DocPodIndex && (doc as DocPodIndex).pod.isManual
	}
}
