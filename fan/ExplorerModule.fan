using afIoc
using afReflux
using gfx
using fwt

@NoDoc
const class ExplorerModule {

	static Void defineServices(RegistryBuilder defs) {		
		defs.addService(Explorer#)			.withScope("uiThread")
		defs.addService(ExplorerCmds#)		.withScope("uiThread")
		defs.addService(FileViewers#)		.withScope("uiThread")
		defs.addService(AppStash#)			.withScope("uiThread")
		defs.addService(IframeBlocker#)		.withScope("uiThread")
		defs.addService(ObjCache#)			.withScope("uiThread")
		defs.addService(FilePopupMenu#)		.withScope("uiThread")
		defs.addService(FolderPopupMenu#)	.withScope("uiThread")
	}

	@Contribute { serviceType=RefluxIcons# }
	static Void contributeRefluxIcons(Configuration config) {
		ExplorerIcons.iconMap.each |uri, id| {
			config[id] = uri.isAbs || uri.toStr.isEmpty ? uri : `fan://afReflux/res/icons-eclipse/` + uri
		}
	}

	@Contribute { serviceType=UriResolvers# }
	internal static Void contributeUriResolvers(Configuration config) {
		config["file"]		= config.build(FileResolver#)
		config["http"]		= config.build(HttpResolver#)
		config["fandoc"]	= config.build(FandocResolver#)		
	}

	@Contribute { serviceType=Panels# }
	static Void contributePanels(Configuration config) {
		config.add(config.build(FoldersPanel#))
	}
	
	@Contribute { serviceType=EventTypes# }
	static Void contributeEventHub(Configuration config) {
		config["afReflux.explorer"] = ExplorerEvents#
	}
	
	@Contribute { serviceType=GlobalCommands# }
	static Void contributeGlobalCommands(Configuration config) {
		config["afExplorer.cmdRenameFile"]		= config.build(RenameFileCommand#)
		config["afExplorer.cmdDeleteFile"]		= config.build(DeleteFileCommand#)

		config["afExplorer.cmdFind"]			= config.build(GlobalExplorerCommand#, ["afExplorer.cmdFind"])
		config["afExplorer.cmdFindNext"]		= config.build(GlobalExplorerCommand#, ["afExplorer.cmdFindNext"])
		config["afExplorer.cmdFindPrev"]		= config.build(GlobalExplorerCommand#, ["afExplorer.cmdFindPrev"])
		config["afExplorer.cmdReplace"]			= config.build(GlobalExplorerCommand#, ["afExplorer.cmdReplace"])
		config["afExplorer.cmdGoto"]			= config.build(GlobalExplorerCommand#, ["afExplorer.cmdGoto"])

		config["afExplorer.cmdShowHiddenFiles"]	= config.build(ShowHiddenFilesCommand#)
		config["afExplorer.cmdSelectAll"]		= config.build(SelectAllCommand#)
		config["afExplorer.cmdWordWrap"]		= config.build(WordWrapCommand#)

		config["afExplorer.cmdFandocIndex"]		= config.build(FandocIndexCommand#)		
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
		config["afExplorer.launchers"]	= PopupCommands#addFileLaunchers
		config["afExplorer.standard"]	= PopupCommands#addStandardFileCommands
		config["afExplorer.copyPaste"]	= PopupCommands#addCopyPasteCommands
	}
	
	@Contribute { serviceType=FolderPopupMenu# }
	static Void contributeFolderPopupMenu(Configuration config) {
		config["afExplorer.launchers"]	= PopupCommands#addFolderLaunchers
		config["afExplorer.copyPaste"]	= PopupCommands#addCopyPasteCommands		
		config["afExplorer.new"]		= PopupCommands#addFolderNewCommands		
	}
	
	@Contribute { serviceType=IframeBlocker# }
	static Void contributeIframeBlocker(Configuration config) {
		config.add("^https?://.*\\.addthis\\.com/.*\$")
		config.add("^https?://.*\\.google(apis)?\\.com/[_o]/.*\$")
		config.add("^https?://api\\.flattr\\.com/.*\$")
	}

	Void defineRegistryStartup(RegistryBuilder bob) {
		bob.onRegistryStartup |config| {
			log := this.typeof.pod.log
			
			config.remove("afIoc.logServices")

			config["afExplorer.installer"] = |->| {
				installer := (Installer) config.build(Installer#)
				try installer.installFandocSyntaxFile
				catch (Err err)
					log.err("Could not install fandoc syntax file", err)
			}
		}
	}

	// ---- Reflux Menu Bar -----------------------------------------------------------------------

	@Contribute { serviceId="afReflux.fileMenu" }
	static Void contributeFileMenu(Configuration config, GlobalCommands globalCmds) {
		config.set("separator.03",				MenuItem { it.mode = MenuItemMode.sep }).after("afExplorer.cmdDeleteFile").before("afReflux.cmdExit")
		config.set("afExplorer.cmdRenameFile", 	MenuItem.makeCommand(globalCmds["afExplorer.cmdRenameFile"].command)).after("separator.02").before("afExplorer.cmdDeleteFile")
		config.set("afExplorer.cmdDeleteFile",	MenuItem.makeCommand(globalCmds["afExplorer.cmdDeleteFile"].command)).after("afExplorer.cmdRenameFile").before("separator.03")
	}

	@Contribute { serviceId="afReflux.editMenu" }
	static Void contributeEditMenu(Configuration config, GlobalCommands globalCmds) {
		config.set("afExplorer.cmdFind",		MenuItem.makeCommand(globalCmds["afExplorer.cmdFind"].command))		.after("separator.02")
		config.set("afExplorer.cmdFindNext",	MenuItem.makeCommand(globalCmds["afExplorer.cmdFindNext"].command))	.after("afExplorer.cmdFind")
		config.set("afExplorer.cmdFindPrev",	MenuItem.makeCommand(globalCmds["afExplorer.cmdFindPrev"].command))	.after("afExplorer.cmdFindNext")
		config.set("separator.03",				MenuItem { it.mode = MenuItemMode.sep })							.after("afExplorer.cmdFindPrev")
		config.set("afExplorer.cmdReplace",		MenuItem.makeCommand(globalCmds["afExplorer.cmdReplace"].command))	.after("separator.03")
		config.set("separator.04",				MenuItem { it.mode = MenuItemMode.sep })							.after("afExplorer.cmdReplace")
		config.set("afExplorer.cmdSelectAll",	MenuItem.makeCommand(globalCmds["afExplorer.cmdSelectAll"].command)).after("separator.04")
		config.set("separator.05",				MenuItem { it.mode = MenuItemMode.sep })							.after("afExplorer.cmdSelectAll")
		config.set("afExplorer.cmdGoto",		MenuItem.makeCommand(globalCmds["afExplorer.cmdGoto"].command))		.after("separator.05")
	}

	@Contribute { serviceId="afReflux.PrefsMenu" }
	static Void contributePrefsMenu(Configuration config, GlobalCommands globalCmds) {
		config["afExplorer.cmdRefluxPrefs"]		= MenuItem.makeCommand(config.build(EditPrefsCmd#, [RefluxPrefs#, `fan://afExplorer/res/fogs/afReflux.fog`]))
		config["afExplorer.cmdExplorerPrefs"]	= MenuItem.makeCommand(config.build(EditPrefsCmd#, [ExplorerPrefs#, `fan://afExplorer/res/fogs/afExplorer.fog`]))
		config["afExplorer.cmdTextEditorPrefs"]	= MenuItem.makeCommand(config.build(EditPrefsCmd#, [TextEditorPrefs#, `fan://afExplorer/res/fogs/fluxText.fog`]))
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

