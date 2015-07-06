using afIoc
using afReflux
using syntax
using gfx
using fwt

** (View) - 
** A text editor with syntax highlighting. Borrowed from [fluxtext]`pod:fluxText`.
class TextEditor : View {
	@Inject private Registry		registry
	@Inject private Explorer		explorer
	@Inject private Reflux			reflux
	@Inject private AppStash		stash
	@Inject private GlobalCommands	globalCommands
	@Inject private Dialogues		dialogues
	@Inject private Preferences		preferences
			private	EdgePane		edgePane
	
	
	** The 'File' being edited.
			File? 				file
	internal TextEditorPrefs?	options
	internal Charset? 			charset
	internal SyntaxRules? 		rules
	internal RichText? 			richText
	internal TextDoc? 			doc

	private TextEditorController?	controller
	internal FindBar				find
	internal DateTime? 				fileTimeAtLoad
	internal Label 					caretField		:= Label()
	internal Label 					charsetField	:= Label()
	
	Bool wordWrap {
		set {
			&wordWrap = it
			stashPrefs
			newWidgets
			restorePrefs
		}
	}

	protected new make(GlobalCommands globCmds, |This| in) : super(in) {
		find = registry.autobuild(FindBar#, [this])
		content = edgePane = EdgePane {
			it.top = buildToolBar
			it.bottom = buildStatusBar
		}
		&wordWrap = globCmds["afExplorer.cmdWordWrap"].command.selected
	}
	
	@NoDoc
	override Void onActivate() {
		globalCommands["afExplorer.cmdFind"				].addInvoker("afExplorer.textEditor", |Event? e|	{ find.showFind } )
		globalCommands["afExplorer.cmdFind"				].addEnabler("afExplorer.textEditor", |  ->Bool| 	{ true } )
		globalCommands["afExplorer.cmdFindNext"			].addInvoker("afExplorer.textEditor", |Event? e|	{ find.next } )
		globalCommands["afExplorer.cmdFindNext"			].addEnabler("afExplorer.textEditor", |  ->Bool| 	{ true } )
		globalCommands["afExplorer.cmdFindPrev"			].addInvoker("afExplorer.textEditor", |Event? e|	{ find.prev } )
		globalCommands["afExplorer.cmdFindPrev"			].addEnabler("afExplorer.textEditor", |  ->Bool| 	{ true } )
		globalCommands["afExplorer.cmdReplace"			].addInvoker("afExplorer.textEditor", |Event? e|	{ find.showFindReplace } )
		globalCommands["afExplorer.cmdReplace"			].addEnabler("afExplorer.textEditor", |  ->Bool| 	{ true } )
		globalCommands["afExplorer.cmdGoto"				].addInvoker("afExplorer.textEditor", |Event? e|	{ controller?.onGoto(e) } )
		globalCommands["afExplorer.cmdGoto"				].addEnabler("afExplorer.textEditor", |  ->Bool| 	{ true } )
		globalCommands["afReflux.cmdSaveAs"				].addInvoker("afExplorer.textEditor", |Event? e|	{ this->onSaveAs() } )
		globalCommands["afReflux.cmdSaveAs"				].addEnabler("afExplorer.textEditor", |  ->Bool| 	{ true } )
		restorePrefs
	}

	@NoDoc
	override Void onDeactivate() {
		globalCommands["afExplorer.cmdFind"				].removeInvoker("afExplorer.textEditor")
		globalCommands["afExplorer.cmdFind"				].removeEnabler("afExplorer.textEditor")
		globalCommands["afExplorer.cmdFindNext"			].removeInvoker("afExplorer.textEditor")
		globalCommands["afExplorer.cmdFindNext"			].removeEnabler("afExplorer.textEditor")
		globalCommands["afExplorer.cmdFindPrev"			].removeInvoker("afExplorer.textEditor")
		globalCommands["afExplorer.cmdFindPrev"			].removeEnabler("afExplorer.textEditor")
		globalCommands["afExplorer.cmdReplace"			].removeInvoker("afExplorer.textEditor")
		globalCommands["afExplorer.cmdReplace"			].removeEnabler("afExplorer.textEditor")
		globalCommands["afExplorer.cmdGoto"				].removeInvoker("afExplorer.textEditor")
		globalCommands["afExplorer.cmdGoto"				].removeEnabler("afExplorer.textEditor")
		globalCommands["afReflux.cmdSaveAs"				].removeEnabler("afExplorer.textEditor")
		globalCommands["afReflux.cmdSaveAs"				].removeInvoker("afExplorer.textEditor")
		
		// onBlur doesn't always fire!?
		globalCommands["afExplorer.cmdSelectAll"		].removeInvoker("afExplorer.textEditor")
		globalCommands["afExplorer.cmdSelectAll"		].removeEnabler("afExplorer.textEditor")		

		stashPrefs
	}
	
	@NoDoc
	override Void load(Resource resource) {
		super.load(resource)
		file = ((FileResource) resource).file

		prefsFileName
			:= preferences.findFile("fluxText-${file?.ext}.fog").exists
			?  "fluxText-${file?.ext}.fog"
			:  "fluxText.fog"
		options = preferences.loadPrefs(TextEditorPrefs#, prefsFileName)
		charset = options.charset
		
		loadDoc
		charsetField.text = charset.toStr

		newWidgets
		restorePrefs
	}
	
	private Void newWidgets() {
		// create rich text widget
		richText = RichText { model = doc; border = false; wrap = wordWrap }
		richText.font = options.font
		richText.tabSpacing = options.tabSpacing

		// initialize controller
		controller = registry.autobuild(TextEditorController#, [this])
		controller.register
		controller.updateCaretStatus

		edgePane.center = richText
		edgePane.relayout
	}
	
	private Void stashPrefs() {
		// we want to keep the scroll pos when switching between views, 
		// but clear it when closing the tab - so when re-opened, we're at the top again!
		if (stash["${resource?.uri}.textEditor.clear"] == true)
			stash.remove("${resource?.uri}.textEditor.clear")
		else {
			// save viewport and caret position
			stash["${resource?.uri}.textEditor.caretOffset"] = richText.caretOffset
			stash["${resource?.uri}.textEditor.topLine"] 	 = richText.topLine
		}
	}

	private Void restorePrefs() {
		if (richText == null) return

		// restore viewport and caret position
		caretOffset := stash["${resource?.uri}.textEditor.caretOffset"]
		topLine		:= stash["${resource?.uri}.textEditor.topLine"]
		if (caretOffset != null) richText.caretOffset = caretOffset
		if (topLine != null)	 richText.topLine = topLine		
		richText.focus
	}

	@NoDoc
	override Void save() {
		doSave(this.file)
		fileTimeAtLoad = file.modified
		super.save
	}

	** Callback for when the 'afReflux.cmdSaveAs' 'GlobalCommand' is activated.
	** Default implementation is to perform the *save as*.
	@NoDoc
	virtual Void onSaveAs() {	
		file := (File?) FileDialog {
			it.mode = FileDialogMode.saveFile
			if (file != null) {
				it.dir	= this.file.parent
				it.name	= this.file.name
				it.filterExts = ["*.${this.file.ext}", "*.*"]
			} else
				it.filterExts = ["*.*"]
		}.open(reflux.window)

		if (file != null) {
			doSave(file)
			fileRes := registry.autobuild(FileResource#, [file])
			reflux.loadResource(fileRes)
			
			isDirty = false	// mark as not dirty so confirmClose() doesn't give a dialog
			reflux.closeView(this, true)

			// refresh any views on the containing directory
			dirRes := registry.autobuild(FolderResource#, [file.parent])
			reflux.refresh(dirRes)
		}
	}
	
	private Void doSave(File file) {
		out := file.out { it.charset = this.charset }
		try		doc.save(out)
		finally	out.close
	}
	
	@NoDoc
	override Bool confirmClose(Bool force) {
		stash.remove("${resource?.uri}.textEditor.caretOffset")
		stash.remove("${resource?.uri}.textEditor.topLine")
		stash["${resource?.uri}.textEditor.clear"] = true
		
		if (!isDirty) return true
		
		if (force) {
			r := dialogues.openQuestion("Save changes to $resource.name?", [dialogues.yes, dialogues.no])
			if (r == dialogues.yes) save

		} else {
			r := dialogues.openQuestion("Save changes to $resource.name?\n\nClick 'Cancel' to continue editing.", [dialogues.yes, dialogues.no, Dialog.cancel])
			if (r == dialogues.cancel) return false
			if (r == dialogues.yes) save
		}
		
		// clear flag to reset the tab text, because the tab (not this view panel) gets reused if we're switching views
		isDirty = false

		return true
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
//			top = InsetPane(4,4,5,4) {
//				ToolBar {
//					addCommand(globalCommands["afReflux.cmdSave"].command)
//					addSep
////					addCommand(frame.command(CommandId.cut))
////					addCommand(frame.command(CommandId.copy))
////					addCommand(frame.command(CommandId.paste))
////					addSep
////					addCommand(frame.command(CommandId.undo))
////					addCommand(frame.command(CommandId.redo))
//				},
//			}
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
