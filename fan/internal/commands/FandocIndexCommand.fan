using afReflux
using afIoc
using fwt

internal class FandocIndexCommand : GlobalCommand {
	@Inject private Reflux reflux
	
	new make(|This|in) : super("afExplorer.cmdFandocIndex", in) {
		this.command.enabled = true
	}
	
	override Void doInvoke(Event? e) {
		reflux.load("fandoc:/")
	}
}
