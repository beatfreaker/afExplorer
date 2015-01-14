using afIoc
using afReflux
using gfx
using fwt

@NoDoc
class ExplorerModule {

	static Void defineServices(ServiceDefinitions defs) {		
		defs.add(Explorer#)
		defs.add(ExplorerCmds#)
		defs.add(DefaultFileViews#)
	}

	@Contribute { serviceType=RefluxIcons# }
	static Void contributeRefluxIcons(Configuration config) {
		ExplorerIcons.iconMap.each |uri, id| {
			config[id] = uri.isAbs || uri.toStr.isEmpty ? uri : `fan://afReflux/res/icons-eclipse/` + uri
		}
	}

	@Contribute { serviceType=UriResolvers# }
	internal static Void contributeUriResolvers(Configuration config) {
		config["file"] = config.autobuild(FileResolver#)
		config["http"] = config.autobuild(HttpResolver#)
	}

	@Contribute { serviceType=Panels# }
	static Void contributePanels(Configuration config) {
		config.add(config.autobuild(FoldersPanel#))
	}
	
	@Contribute { serviceType=EventTypes# }
	static Void contributeEventHub(Configuration config) {
		config["afReflux.explorer"] = ExplorerEvents#
	}
	
	@Contribute { serviceType=GlobalCommands# }
	static Void contributeGlobalCommands(Configuration config) {
		config["afExplorer.cmdFind"]			= config.autobuild(GlobalExplorerCommand#, ["afExplorer.cmdFind"])
		config["afExplorer.cmdFindNext"]		= config.autobuild(GlobalExplorerCommand#, ["afExplorer.cmdFindNext"])
		config["afExplorer.cmdFindPrev"]		= config.autobuild(GlobalExplorerCommand#, ["afExplorer.cmdFindPrev"])
		config["afExplorer.cmdReplace"]			= config.autobuild(GlobalExplorerCommand#, ["afExplorer.cmdReplace"])
		config["afExplorer.cmdGoto"]			= config.autobuild(GlobalExplorerCommand#, ["afExplorer.cmdGoto"])
		config["afExplorer.cmdShowHiddenFiles"]	= config.autobuild(ShowHiddenFilesCommand#)
	}

	@Contribute { serviceType=DefaultFileViews# }
	static Void contributeDefaultFileViews(Configuration config) {
		config["bmp"]	= ImageView#
		config["gif"]	= ImageView#
		config["jpg"]	= ImageView#
		config["png"]	= ImageView#

		config["htm"]	= HtmlView#
		config["html"]	= HtmlView#

		// TODO: Have file actions and DEFAULT file actions
//		config["htm"]		= TextEditorView#
//		config["html"]		= TextEditorView#
		"css fan fog fdoc fandoc java js less md slim txt xml".split.each { config[it] = TextEditorView# }
	}

	
	
	// ---- Reflux Tool Bar -----------------------------------------------------------------------

	@Contribute { serviceId="afReflux.editMenu" }
	static Void contributeEditMenu(Configuration config, GlobalCommands globalCmds) {
		config["afExplorer.find"]		= MenuItem.makeCommand(globalCmds["afExplorer.cmdFind"].command)
		config["afExplorer.findNext"]	= MenuItem.makeCommand(globalCmds["afExplorer.cmdFindNext"].command)
		config["afExplorer.findPrev"]	= MenuItem.makeCommand(globalCmds["afExplorer.cmdFindPrev"].command)
		config.add(MenuItem { it.mode = MenuItemMode.sep })
		config["afExplorer.replace"]	= MenuItem.makeCommand(globalCmds["afExplorer.cmdReplace"].command)
		config.add(MenuItem { it.mode = MenuItemMode.sep })
		config["afExplorer.goto"]		= MenuItem.makeCommand(globalCmds["afExplorer.cmdGoto"].command)
	}

	@Contribute { serviceId="afReflux.optionsMenu" }
	static Void contributeOptionsMenu(Configuration config, GlobalCommands globalCmds) {
		config["afReflux.showHiddenFiles"]	= MenuItem.makeCommand(globalCmds["afExplorer.cmdShowHiddenFiles"].command)
	}
}


** Just so the command gets localised from the correct pod 
internal class GlobalExplorerCommand : afReflux::GlobalCommand {	
	new make(Str baseName, |This|in) : super.make(baseName, in) { }
}

