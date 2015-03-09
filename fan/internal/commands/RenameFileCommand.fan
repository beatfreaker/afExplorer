using afReflux
using afIoc
using fwt

internal class RenameFileCommand : GlobalCommand {
	@Inject private Explorer explorer
	
	|->File?|? fileFetcher {
		set { &fileFetcher = it; update }
	}
	
	new make(|This|in) : super("afExplorer.cmdRenameFile", in) { }
	
	override Void doInvoke(Event? e) {
		file := fileFetcher?.call()
		if (file != null)
			explorer.rename(file)
	}
}
