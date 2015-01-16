using afIoc
using afReflux

** Use to launch the Explorer application.
class Main {
	
	// TODO: allow paths to be passed in on the command line
	Void main() {
		Reflux.start([ExplorerModule#]) |Reflux reflux| {
			reflux.showPanel(FoldersPanel#)

			// TODO: select from favourites in FileExplorerPanel / FolderPanel
//			reflux.load(File.os("C:\\Projects\\").uri)
			
//			this.typeof.pod.log.level = LogLevel.debug
//			Reflux#.pod.log.level = LogLevel.debug
			
			reflux.callLater(70ms) |->| {
//				panel := (FoldersPanel) reflux.getPanel(FoldersPanel#)
//				panel.gotoFavourite("Projects")
				
				reflux.load(`file:/C:/dude.xml`)
//				fileExplorer := (Explorer) reflux.registry.serviceById(Explorer#.qname)
//				fav := fileExplorer.preferences.favourites["Projects"]
//				if (fav == null)
//					echo("Favourite 'Projects' not found!")
//				else
//					reflux.load(fav)
			}
		}
	}
}
