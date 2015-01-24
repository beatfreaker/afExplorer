using afReflux
using afIoc
using fwt

internal class DeleteFileCommand : GlobalCommand {
	@Inject private Explorer explorer
	
	|->File?|? fileFetcher {
		set { &fileFetcher = it; update }
	}
	
	new make(|This|in) : super("afExplorer.cmdDeleteFile", in) { }
	
	override Void doInvoke(Event? e) {
		file := fileFetcher?.call()
		if (file != null)
			explorer.delete(file)
	}
	
		** Enables / disables the underlying fwt command based on the 'enabled' property.
	override Void update() {
		in := GlobalCommand#.field("_invokers").get(this)
		en := GlobalCommand#.field("_enablers").get(this)
		super.update
	}
}
