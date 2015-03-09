using afIoc
using afReflux
using gfx
using fwt

internal class ShowHiddenFilesCommand : GlobalCommand, RefluxEvents {
	@Inject private Explorer	explorer

	new make(|This|in) : super.make("cmdShowHiddenFiles", in) {
		this.command.mode = CommandMode.toggle
		this.command.selected = explorer.preferences.showHiddenFiles
	}

	override Void doInvoke(Event? event) {
		// setting this fires the event
		explorer.preferences.showHiddenFiles = command.selected
	}
	
	override Void onLoadSession(Str:Obj? session) {
		showHide := (Bool?) session["afExplorer.cmdShowHiddenFiles"]
		
		if (showHide != null) {
			command.selected = showHide
			explorer.preferences.showHiddenFiles = showHide
		}
	}
	override Void onSaveSession(Str:Obj? session) {
		session["afExplorer.cmdShowHiddenFiles"] = this.command.selected
	}
}
