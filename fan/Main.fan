using afIoc
using afReflux

** Use to launch the Explorer application.
class Main {
	
	// TODO: allow paths to be passed in on the command line
	Void main() {
		Reflux.start("Explorer", [ExplorerModule#]) |Reflux reflux| {
			
//			this.typeof.pod.log.level = LogLevel.debug
//			Reflux#.pod.log.level = LogLevel.debug

			reflux.showPanel(FoldersPanel#)
			reflux.load(reflux.preferences.homeUri)
		}
	}
}
