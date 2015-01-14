using afIoc
using afReflux
using gfx
using fwt

// TODO: convert to GlobalCommand
internal class ShowHiddenFilesCommand : RefluxCommand, FileExplorerEvents {
	@Inject	private FileExplorer	fileExplorer
	@Inject	private Reflux			reflux

	new make(EventHub eventHub, |This|in) : super.make(in) {
		eventHub.register(this)
		this.name = "Show Hidden Files"
		this.mode = CommandMode.toggle
		this.selected = fileExplorer.preferences.showHiddenFiles
	}

	override Void invoked(Event? event) {
		fileExplorer.preferences.showHiddenFiles = !fileExplorer.preferences.showHiddenFiles
		reflux.refresh
	}
	
	override Void onShowHiddenFiles(Bool show)	{
		this.selected = show
	}
}
