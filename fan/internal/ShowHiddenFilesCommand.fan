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
		val := !explorer.preferences.showHiddenFiles
		explorer.preferences.showHiddenFiles = val
		this.command.selected = val
	}
	
	override Void onLoadSession(Str:Obj? session) {
		this.command.selected = session.getOrAdd("afExplorer.cmdShowHiddenFiles") { true }
	}
	override Void onSaveSession(Str:Obj? session) {
		session["afExplorer.cmdShowHiddenFiles"] = this.command.selected
	}
}
