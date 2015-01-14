using fwt

// FIXME: undo commands
//internal class TextEditorCommand : RefluxCommand {
//	
//	new make(Str id) : super.ma {
//		localise(Pod.of(this), id)
//	}
//
//	TextEditorView editor() { return view }
//
//	TextEditorController controller() { return editor.controller }
//
//	RichText richText() { return editor.richText }
//
//	TextDoc doc() { return editor.doc }
//
//}
//
//**************************************************************************
//** TextChangeCommand
//**************************************************************************
//
//internal class TextChangeCommand : TextEditorCommand {
//	TextChange change
//
//	new make(TextChange change) : super("textChange") {
//		this.change = change
//	}
//
//	override Void redo() {
//		controller.inUndo = true
//		try		change.redo(richText)
//		finally	controller.inUndo = false
//	}
//
//	override Void undo() {
//		controller.inUndo = true
//		try		change.undo(richText)
//		finally	controller.inUndo = false
//	}
//}

