using fwt
using syntax

**
** TextEditorSupport provides a bunch of convience methods
**
internal mixin TextEditorSupport {

	abstract TextEditor editor()

//	Frame frame() { return editor.frame }

	TextEditorOptions options() { return editor.options }

	SyntaxRules rules() { return editor.rules }

	TextEditorController controller() { return editor.controller }

	RichText richText() { return editor.richText }

	TextDoc doc() { return editor.doc }

}