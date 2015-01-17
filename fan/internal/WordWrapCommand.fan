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

	new make(EventHub eventHub, |This|in) : super.make("cmdWordWrap", in) {
		eventHub.register(this)
		this.command.mode = CommandMode.toggle
		this.command.selected = explorer.preferences.wordWrap
		this.addEnabler("afExplorer.cmdWordWrap", |->Bool| { reflux.activeView is TextEditor }, false)
	}

	override Void doInvoke(Event? event) {
		val := this.command.selected
		explorer.preferences.wordWrap = val
		(reflux.activeView as TextEditor).wordWrap = val
	}
	
	override Void update() {
		super.update
		if (reflux.activeView is TextEditor)
			this.command.selected = (reflux.activeView as TextEditor).wordWrap
	}

	override Void onViewActivated	(View view) { update }
	override Void onViewDeactivated	(View view) { update } 
}
