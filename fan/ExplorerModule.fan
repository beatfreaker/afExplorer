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
		defs.add(AppStash#)
		defs.add(IframeBlocker#)
		defs.add(ObjCache#)
		defs.add(FilePopupMenu#)
		defs.add(FolderPopupMenu#)
	}

	@Contribute { serviceType=RefluxIcons# }
	static Void contributeRefluxIcons(Configuration config) {
		ExplorerIcons.iconMap.each |uri, id| {
			config[id] = uri.isAbs || uri.toStr.isEmpty ? uri : `fan://afReflux/res/icons-eclipse/` + uri
		}
	}

	@Contribute { serviceType=UriResolvers# }
	internal static Void contributeUriResolvers(Configuration config) {
		config["file"]		= config.autobuild(FileResolver#)
		config["http"]		= config.autobuild(HttpResolver#)
		config["fandoc"]	= config.autobuild(FandocResolver#)
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
		config["afExplorer.cmdSelectAll"]		= config.autobuild(SelectAllCommand#)
		config["afExplorer.cmdWordWrap"]		= config.autobuild(WordWrapCommand#)

		config["afExplorer.cmdFandocIndex"]		= config.autobuild(FandocIndexCommand#)
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

		"bat cmd cs css csv efan fan fandoc fdoc fog htm html inf ini java js less md props properties slim svg txt xhtml xml".split.each {
			config["textEditor-${it}"] = FileViewMapping(it, TextEditor#)
		}
		
		// F4 config files
		"buildpath classpath project".split.each {
			config["textEditor-${it}"] = FileViewMapping(it, TextEditor#)
		}
		
		// other . files
		"gitignore hgignore hgtags".split.each {
			config["textEditor-${it}"] = FileViewMapping(it, TextEditor#)
		}
	}

	@Contribute { serviceType=FilePopupMenu# }
	static Void contributeFilePopupMenu(Configuration config) {
		config["fileLaunchers"]	= PopupCommands#addFileLaunchers
		config["fileStandard"]	= PopupCommands#addStandardFileCommands
		config["copyPaste"]		= PopupCommands#addCopyPasteCommands
	}
	
	@Contribute { serviceType=FolderPopupMenu# }
	static Void contributeFolderPopupMenu(Configuration config) {
		config["folderLaunchers"]	= PopupCommands#addFolderLaunchers
		config["copyPaste"]			= PopupCommands#addCopyPasteCommands		
		config["newFile"]			= PopupCommands#addFolderNewCommands		
	}
	
	@Contribute { serviceType=IframeBlocker# }
	static Void contributeIframeBlocker(Configuration config) {
		config.add("^https?://.*\\.addthis\\.com/.*\$")
		config.add("^https?://.*\\.google(apis)?\\.com/[_o]/.*\$")
		config.add("^https?://api\\.flattr\\.com/.*\$")
	}

	@Contribute { serviceType=RegistryStartup# }
	static Void contributeRegistryStartup(Configuration config, Log log) {
		config.remove("afIoc.logServices")
		
		config["afExplorer.installer"] = |->| {
			installer := (Installer) config.autobuild(Installer#)
			try installer.installFandocSyntaxFile
			catch (Err err)
				log.err("Could not install fandoc syntax file", err)
		}
	}

	// ---- Reflux Menu Bar -----------------------------------------------------------------------

	@Contribute { serviceId="afReflux.fileMenu" }
	static Void contributeFileMenu(Configuration config, GlobalCommands globalCmds) {
		config.set("separator.02",				MenuItem { it.mode = MenuItemMode.sep }).after("afExplorer.cmdDeleteFile").before("afReflux.cmdExit")
		config.set("afExplorer.cmdRenameFile", 	MenuItem.makeCommand(globalCmds["afExplorer.cmdRenameFile"].command)).after("separator.01").before("afExplorer.cmdDeleteFile")
		config.set("afExplorer.cmdDeleteFile",	MenuItem.makeCommand(globalCmds["afExplorer.cmdDeleteFile"].command)).after("afExplorer.cmdRenameFile").before("separator.02")
	}

	@Contribute { serviceId="afReflux.editMenu" }
	static Void contributeEditMenu(Configuration config, GlobalCommands globalCmds) {
		config["afExplorer.cmdFind"]		= MenuItem.makeCommand(globalCmds["afExplorer.cmdFind"].command)
		config["afExplorer.cmdFindNext"]	= MenuItem.makeCommand(globalCmds["afExplorer.cmdFindNext"].command)
		config["afExplorer.cmdFindPrev"]	= MenuItem.makeCommand(globalCmds["afExplorer.cmdFindPrev"].command)
		config["separator.02"]				= MenuItem { it.mode = MenuItemMode.sep }
		config["afExplorer.cmdReplace"]		= MenuItem.makeCommand(globalCmds["afExplorer.cmdReplace"].command)
		config["separator.03"]				= MenuItem { it.mode = MenuItemMode.sep }
		config["afExplorer.cmdSelectAll"]	= MenuItem.makeCommand(globalCmds["afExplorer.cmdSelectAll"].command)
		config["separator.04"]				= MenuItem { it.mode = MenuItemMode.sep }
		config["afExplorer.cmdGoto"]		= MenuItem.makeCommand(globalCmds["afExplorer.cmdGoto"].command)
	}

	@Contribute { serviceId="afReflux.PrefsMenu" }
	static Void contributePrefsMenu(Configuration config, GlobalCommands globalCmds) {
		config["afExplorer.cmdRefluxPrefs"]		= MenuItem.makeCommand(config.autobuild(EditPrefsCmd#, [RefluxPrefs#, `fan://afExplorer/res/fogs/afReflux.fog`]))
		config["afExplorer.cmdExplorerPrefs"]	= MenuItem.makeCommand(config.autobuild(EditPrefsCmd#, [ExplorerPrefs#, `fan://afExplorer/res/fogs/afExplorer.fog`]))
		config["afExplorer.cmdTextEditorPrefs"]	= MenuItem.makeCommand(config.autobuild(EditPrefsCmd#, [TextEditorPrefs#, `fan://afExplorer/res/fogs/fluxText.fog`]))
		config["separator.01"]					= MenuItem { it.mode = MenuItemMode.sep }
		config["afExplorer.cmdShowHiddenFiles"]	= MenuItem.makeCommand(globalCmds["afExplorer.cmdShowHiddenFiles"].command)
		config["afExplorer.cmdWordWrap"]		= MenuItem.makeCommand(globalCmds["afExplorer.cmdWordWrap"].command)
	}

	@Contribute { serviceId="afReflux.helpMenu" }
	static Void contributeAboutMenu(Configuration config, GlobalCommands globalCmds) {
		config.set("afExplorer.cmdFandocs", MenuItem(globalCmds["afExplorer.cmdFandocIndex"].command))
			.before("afReflux.cmdAbout")
	}

//	@Contribute { serviceId="afReflux.toolBar" }
//	static Void contributeToolBar(Configuration config, GlobalCommands globalCmds) {
//		config["afExplorer.cmdFandocIndex"]		= toolBarCommand(globalCmds["afExplorer.cmdFandocIndex"].command)
//	}
	
    private static Button toolBarCommand(Command command) {
        button  := Button.makeCommand(command)
        if (command.icon != null)
            button.text = ""
        return button
    }
}


** Just so the command gets localised from the correct pod 
internal class GlobalExplorerCommand : afReflux::GlobalCommand {	
	new make(Str baseName, |This|in) : super.make(baseName, in) { }
}

