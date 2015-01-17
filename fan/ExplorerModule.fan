using afIoc
using afReflux
using gfx
using fwt

@NoDoc
class ExplorerModule {

	static Void defineServices(ServiceDefinitions defs) {		
		defs.add(Explorer#)
		defs.add(ExplorerCmds#)
		defs.add(FileViewers#)
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
		config["afExplorer.cmdRenameFile"]		= config.autobuild(RenameFileCommand#)
		config["afExplorer.cmdDeleteFile"]		= config.autobuild(DeleteFileCommand#)

		config["afExplorer.cmdFind"]			= config.autobuild(GlobalExplorerCommand#, ["afExplorer.cmdFind"])
		config["afExplorer.cmdFindNext"]		= config.autobuild(GlobalExplorerCommand#, ["afExplorer.cmdFindNext"])
		config["afExplorer.cmdFindPrev"]		= config.autobuild(GlobalExplorerCommand#, ["afExplorer.cmdFindPrev"])
		config["afExplorer.cmdReplace"]			= config.autobuild(GlobalExplorerCommand#, ["afExplorer.cmdReplace"])
		config["afExplorer.cmdGoto"]			= config.autobuild(GlobalExplorerCommand#, ["afExplorer.cmdGoto"])

		config["afExplorer.cmdShowHiddenFiles"]	= config.autobuild(ShowHiddenFilesCommand#)
		config["afExplorer.cmdWordWrap"]		= config.autobuild(WordWrapCommand#)
	}

	@Contribute { serviceType=FileViewers# }
	static Void contributeFileViewers(Configuration config) {
		"bmp gif jpg png".split.each {
			config["imageViewer-${it}"] = FileViewMapping(it, ImageViewer#)
		}

		"htm html svg xml".split.each {
			config["htmlViewer-${it}"] = FileViewMapping(it, HtmlViewer#)
		}

		"fandoc fdoc".split.each {
			config["fandocViewer-${it}"] = FileViewMapping(it, FandocViewer#)
		}

		"cs css csv efan fan fandoc fdoc fog htm html inf ini java js less md slim svg txt xhtml xml".split.each {
			config["textEditor-${it}"] = FileViewMapping(it, TextEditor#)
		}
	}



	// ---- Reflux Tool Bar -----------------------------------------------------------------------

	@Contribute { serviceId="afReflux.fileMenu" }
	static Void contributeFileMenu(Configuration config, GlobalCommands globalCmds) {
		config.set("afExplorer.cmdRenameFile", 	MenuItem.makeCommand(globalCmds["afExplorer.cmdRenameFile"].command)).after("separator.01").before("afExplorer.cmdDeleteFile")
		config.set("afExplorer.cmdDeleteFile",	MenuItem.makeCommand(globalCmds["afExplorer.cmdDeleteFile"].command)).after("afExplorer.cmdRenameFile").before("separator.02")
		config.set("separator.02",				MenuItem { it.mode = MenuItemMode.sep }).after("afExplorer.cmdDeleteFile").before("afReflux.cmdExit")
	}

	@Contribute { serviceId="afReflux.editMenu" }
	static Void contributeEditMenu(Configuration config, GlobalCommands globalCmds) {
		config["afExplorer.cmdFind"]		= MenuItem.makeCommand(globalCmds["afExplorer.cmdFind"].command)
		config["afExplorer.cmdFindNext"]	= MenuItem.makeCommand(globalCmds["afExplorer.cmdFindNext"].command)
		config["afExplorer.cmdFindPrev"]	= MenuItem.makeCommand(globalCmds["afExplorer.cmdFindPrev"].command)
		config["separator.02"]				= MenuItem { it.mode = MenuItemMode.sep }
		config["afExplorer.cmdReplace"]		= MenuItem.makeCommand(globalCmds["afExplorer.cmdReplace"].command)
		config["separator.03"]				= MenuItem { it.mode = MenuItemMode.sep }
		config["afExplorer.cmdGoto"]		= MenuItem.makeCommand(globalCmds["afExplorer.cmdGoto"].command)
	}

	@Contribute { serviceId="afReflux.PrefsMenu" }
	static Void contributePrefsMenu(Configuration config, GlobalCommands globalCmds) {
		config["afExplorer.cmdShowHiddenFiles"]	= MenuItem.makeCommand(globalCmds["afExplorer.cmdShowHiddenFiles"].command)
		config["afExplorer.cmdWordWrap"]		= MenuItem.makeCommand(globalCmds["afExplorer.cmdWordWrap"].command)
	}
}


** Just so the command gets localised from the correct pod 
internal class GlobalExplorerCommand : afReflux::GlobalCommand {	
	new make(Str baseName, |This|in) : super.make(baseName, in) { }
}

