using afIoc
using afReflux

class Main {
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
				
				fileExplorer := (FileExplorer) reflux.registry.serviceById(FileExplorer#.qname)
				fav := fileExplorer.preferences.favourites["Projects"]
				if (fav == null)
					echo("Favourite 'Projects' not found!")
				else
					reflux.load(fav)
			}
		}
	}
	
//	static Void main() {
//		Reflux.start([,]) |Reflux reflux| {
//			reflux.showPanel(FoldersPanel#)
//			reflux.load(File.osRoots.first.normalize.uri)			
//		}
//	}
}
