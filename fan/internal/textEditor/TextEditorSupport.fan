using fwt
using syntax

**
** TextEditorSupport provides a bunch of convience methods
**
internal mixin TextEditorSupport {

	abstract TextEditor editor()

	TextEditorOptions options() { return editor.options }

	SyntaxRules rules() { return editor.rules }

	RichText richText() { return editor.richText }

	TextDoc doc() { return editor.doc }

}