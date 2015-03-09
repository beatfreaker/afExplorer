using afIoc
using afReflux
using gfx
using fwt

internal class WordWrapCommand : GlobalCommand, RefluxEvents {
	private Reflux reflux() {
		registry.serviceById(Reflux#.qname)
	}
	@Inject private Registry	registry
	@Inject private Explorer	explorer

	new make(|This|in) : super.make("cmdWordWrap", in) {
		this.command.mode = CommandMode.toggle
		this.addEnabler("afExplorer.cmdWordWrap", |->Bool| { reflux.activeView is TextEditor }, false)
	}

	override Void doInvoke(Event? event) {
		(reflux.activeView as TextEditor).wordWrap = this.command.selected
	}
	
	override Void update() {
		super.update
		if (reflux.activeView is TextEditor)
			this.command.selected = (reflux.activeView as TextEditor).wordWrap
	}

	override Void onLoadSession(Str:Obj? session) {
		this.command.selected = session.getOrAdd("afExplorer.cmdWordWrap") { true }
	}
	override Void onSaveSession(Str:Obj? session) {
		session["afExplorer.cmdWordWrap"] = this.command.selected
	}

	override Void onViewActivated	(View view) { update }
	override Void onViewDeactivated	(View view) { update } 
}
