using afIoc
using afReflux
using syntax
using gfx
using fwt

** TextEditor provides a syntax color coded editor for working with text files.
class TextEditorView : View {
	
	File? 				file
	TextEditorOptions	options := TextEditorOptions.load
	Charset 			charset := options.charset
	SyntaxRules? 		rules
	RichText? 			richText
	internal TextDoc? 	doc

	internal TextEditorController?	controller
	internal FindBar				find
	internal DateTime? 				fileTimeAtLoad
	internal Label 					caretField		:= Label()
	internal Label 					charsetField	:= Label()
	
	@Inject private GlobalCommands	globalCommands
			private	EdgePane		edgePane
	
	protected new make(|This| in) : super(in) {
		find = FindBar(this)
		content = edgePane = EdgePane {
			it.top = buildToolBar
			it.bottom = buildStatusBar
		}
	}
	
	override Void onActivate() {
		super.onActivate
		
		globalCommands["afReflux.cmdFind"		].addInvoker("afReflux.textEditor", |Event? e|	{ find.showFind } )
		globalCommands["afReflux.cmdFind"		].addEnabler("afReflux.textEditor", |  ->Bool| 	{ true } )
		globalCommands["afReflux.cmdFindNext"	].addInvoker("afReflux.textEditor", |Event? e|	{ find.next } )
		globalCommands["afReflux.cmdFindNext"	].addEnabler("afReflux.textEditor", |  ->Bool| 	{ true } )
		globalCommands["afReflux.cmdFindPrev"	].addInvoker("afReflux.textEditor", |Event? e|	{ find.prev } )
		globalCommands["afReflux.cmdFindPrev"	].addEnabler("afReflux.textEditor", |  ->Bool| 	{ true } )
		globalCommands["afReflux.cmdReplace"	].addInvoker("afReflux.textEditor", |Event? e|	{ find.showFindReplace } )
		globalCommands["afReflux.cmdReplace"	].addEnabler("afReflux.textEditor", |  ->Bool| 	{ true } )
		globalCommands["afReflux.cmdGoto"		].addInvoker("afReflux.textEditor", |Event? e|	{ controller?.onGoto(e) } )
		globalCommands["afReflux.cmdGoto"		].addEnabler("afReflux.textEditor", |  ->Bool| 	{ true } )

		// restore viewport and caret position
//		caretOffset := Actor.locals["fluxText.caretOffset.$resource.uri"]
//		topLine := Actor.locals["fluxText.topLine.$resource.uri"]
//		if (caretOffset != null) richText.caretOffset = caretOffset
//		if (topLine != null) richText.topLine = topLine
		richText?.focus
	}
	
	override Void onDeactivate() {
		super.onDeactivate
		
		globalCommands["afReflux.cmdFind"		].removeInvoker("afReflux.textEditor")
		globalCommands["afReflux.cmdFind"		].removeEnabler("afReflux.textEditor")
		globalCommands["afReflux.cmdFindNext"	].removeInvoker("afReflux.textEditor")
		globalCommands["afReflux.cmdFindNext"	].removeEnabler("afReflux.textEditor")
		globalCommands["afReflux.cmdFindPrev"	].removeInvoker("afReflux.textEditor")
		globalCommands["afReflux.cmdFindPrev"	].removeEnabler("afReflux.textEditor")
		globalCommands["afReflux.cmdReplace"	].removeInvoker("afReflux.textEditor")
		globalCommands["afReflux.cmdReplace"	].removeEnabler("afReflux.textEditor")
		globalCommands["afReflux.cmdGoto"		].removeInvoker("afReflux.textEditor")
		globalCommands["afReflux.cmdGoto"		].removeEnabler("afReflux.textEditor")

		// save viewport and caret position
//		Actor.locals["fluxText.caretOffset.$resource.uri"] = richText.caretOffset
//		Actor.locals["fluxText.topLine.$resource.uri"] = richText.topLine
	}
	
	override Void load(Resource resource) {
		super.load(resource)

		// init
		file = (resource as FileResource).file

		// load the document into memory
		loadDoc
		charsetField.text = charset.toStr

		// create rich text widget
		richText = RichText { model = doc; border = false }

		richText.font = options.font
		richText.tabSpacing = options.tabSpacing

		// initialize controller
		controller = TextEditorController(this)
		controller.register
		controller.updateCaretStatus

		// update ui
		edgePane.center = BorderPane {
			it.content	= richText
			it.border	 = Border("1,0,1,1 $Desktop.sysNormShadow")
		}
		edgePane.relayout
		richText.focus
	}

	
	override Void save() {	
		out := file.out { it.charset = this.charset }
		try		doc.save(out)
		finally	out.close
		fileTimeAtLoad = file.modified

		super.save
	}
	
	
	internal Void loadDoc() {
		// read document into memory, if we fail with the
		// configured charset, then fallback to ISO 8859-1
		// which will always "work" since it is byte based
		lines := readAllLines
		if (lines == null) {
			charset = Charset.fromStr("ISO-8859-1")
			lines	 = readAllLines
		}

		// save this time away to check on focus events
		fileTimeAtLoad = file.modified

		// figure out what syntax file to use
		// based on file extension and shebang
		rules = SyntaxRules.loadForFile(file, lines.first) ?: SyntaxRules()

		// load document
		doc = TextDoc(options, rules)
		doc.load(lines)
	}

	private Str[]? readAllLines() {
		in := file.in { it.charset = this.charset }
		try		return in.readAllLines
		catch	return null
		finally	in.close
	}

	private Widget buildToolBar() {
		return EdgePane {
			top = InsetPane(4,4,5,4) {
				ToolBar {
					addCommand(globalCommands["afReflux.cmdSave"].command)
					addSep
//					addCommand(frame.command(CommandId.cut))
//					addCommand(frame.command(CommandId.copy))
//					addCommand(frame.command(CommandId.paste))
//					addSep
//					addCommand(frame.command(CommandId.undo))
//					addCommand(frame.command(CommandId.redo))
				},
			}
			bottom = find
		}
	}

	private Widget buildStatusBar() {
		return GridPane {
			it.numCols = 2
			it.hgap = 10
			it.halignPane = Halign.right
			it.add(caretField)
			it.add(charsetField)
		}
	}
	
}