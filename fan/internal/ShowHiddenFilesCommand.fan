using afIoc
using afReflux
using gfx
using fwt

// TODO: convert to GlobalCommand
internal class ShowHiddenFilesCommand : RefluxCommand, ExplorerEvents {
	@Inject	private Reflux		reflux
	@Inject private Explorer	explorer

	new make(EventHub eventHub, |This|in) : super.make(in) {
		eventHub.register(this)
		this.name = "Show Hidden Files"
		this.mode = CommandMode.toggle
		this.selected = explorer.preferences.showHiddenFiles
	}

	override Void invoked(Event? event) {
		explorer.preferences.showHiddenFiles = !explorer.preferences.showHiddenFiles
		reflux.refresh
	}
	
	override Void onShowHiddenFiles(Bool show)	{
		this.selected = show
	}
}
