using afIoc
using afReflux

** Use to launch the Explorer application from the command line. 
** 
**   C:\> fan afExplorer <names> 
** 
** Where '<names>' is an optional list of files / URIs to load.
**  
** File examples:
** 
**   C:\> fan afExplorer C:\Temp
** 
**   C:\> fan afExplorer C:\Temp\readme.html
** 
** URI examples:
** 
**   C:\> fan afExplorer file:/C:/Temp/
** 
**   C:\> fan afExplorer file:/C:/Temp/readme.html?view=afExplorer::TextEditor
**  
**   C:\> fan afExplorer http://www.fantomfactory.org/ 
** 
class Main {
	
	Void main(Str[] args) {
		Reflux.start("Explorer", [ExplorerModule#]) |Reflux reflux| {
			if (args.isEmpty)
				reflux.load(reflux.preferences.homeUri.toStr)
			else
				args.each { reflux.load(it) }
		}
	}
}
