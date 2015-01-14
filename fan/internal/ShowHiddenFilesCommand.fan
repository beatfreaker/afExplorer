using afIoc
using afReflux
using gfx
using fwt

internal class ShowHiddenFilesCommand : GlobalCommand, ExplorerEvents {
	@Inject	private Reflux		reflux
	@Inject private Explorer	explorer

	new make(EventHub eventHub, |This|in) : super.make("cmdShowHiddenFiles", in) {
		eventHub.register(this)
		this.command.mode = CommandMode.toggle
		this.command.selected = explorer.preferences.showHiddenFiles
	}

	override Void onInvoke(Event? event) {
		explorer.preferences.showHiddenFiles = !explorer.preferences.showHiddenFiles
		reflux.refresh
	}
	
	override Void onShowHiddenFiles(Bool show)	{
		this.command.selected = show
	}
}
