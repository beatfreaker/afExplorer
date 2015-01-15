using afReflux
using afIoc
using fwt

class DeleteFileCommand : GlobalCommand {
	@Inject private Explorer explorer
	
	|->File?|? fileFetcher {
		set { &fileFetcher = it; update }
	}
	
	new make(|This|in) : super("afExplorer.cmdDeleteFile", in) {
		addEnabler("afExplorer.cmdDeleteFile") |->Bool| { fileFetcher?.call() != null }
	}
	
	override Void onInvoke(Event? e) {
		file := fileFetcher?.call()
		if (file != null)
			explorer.delete(file)
	}
}
