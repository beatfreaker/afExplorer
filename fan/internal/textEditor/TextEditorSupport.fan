using fwt
using syntax

**
** TextEditorSupport provides a bunch of convience methods
**
internal mixin TextEditorSupport {

	abstract TextEditor editor()

	SyntaxRules rules() { return editor.rules }

	RichText richText() { return editor.richText }

	TextDoc doc() { return editor.doc }

}