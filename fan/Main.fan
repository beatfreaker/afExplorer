using afIoc
using afReflux
using util
using fwt

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
class Main : AbstractMain {

	@Opt { help = "Hides all panels on startup"; aliases=["noTabs"] }
	Bool noPanels
	
	@Opt { help = "Hides all panels on startup" }
	Bool noPlugins
	
	@Arg { help = "A resource URI, name or file to load" }
	Str[]? uri
	
	override Int run() {
		moduleTypes := [ExplorerModule#]
		
		if (!noPlugins) {
			moduleTypeNames := Env.cur.index("afExplorer.module")
			pluginTypes := moduleTypeNames.join(",")
				.split(',', true)
				.exclude { it.trim.isEmpty }
				.map |moduleTypeName -> Type?| {
					return Type.find(moduleTypeName)
				}
			moduleTypes.addAll(pluginTypes)
		}
		
		Reflux.start("Explorer", moduleTypes.unique) |Reflux reflux, Window window| {
			if (noPanels) {
				panels := (Panels) reflux.registry.serviceById(Panels#.qname)
				panels.panelTypes.each { reflux.hidePanel(it) }
			}

			if (uri == null)
				reflux.load(reflux.preferences.homeUri.toStr)
			else
				uri.each { reflux.load(it) }
		}
		return 0
	}
	
	
}
