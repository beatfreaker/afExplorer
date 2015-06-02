using afIoc
using afBeanUtils
using afReflux
using fwt

internal class PopupCommands {
	@Inject private	Explorer		explorer
	@Inject private	Errors			errors
	@Inject private	ExplorerCmds	fileCmds
	@Inject private FileViewers		fileViewers
	@Inject private GlobalCommands	globalCommands
			private	File[]			osRoots		:= File.osRoots.map { it.normalize }

	internal new make(|This|in) { in(this) }
	
	Void addFileLaunchers(Menu menu, FileResource resource) {
		file := resource.file
		fileViewers.getViewers(file.ext).each {
			addCmd(menu, fileCmds.openFileWithViewCmd(resource, it))
		}

		addCmd(menu, fileCmds.openFileInSystemCmd(file))
		
		fileExt := file.ext?.lower
		prefs	:= explorer.preferences
		actions := prefs.fileActions.findAll { it.ext == fileExt }
		actions.each |action| {
			launcher := prefs.fileLaunchers.find { it.id == action.launcherId }
			if (launcher == null)
				errors.add(ArgNotFoundErr("Could not find a launcher with id '${action.launcherId}'", prefs.fileLaunchers.map { it.id }))
			else
				addCmd(menu, fileCmds.actionFileCmd(file, action, launcher))
		}		
	}
	
	Void addFolderLaunchers(Menu menu, FileResource resource) {
		file := resource.file

		addCmd(menu, fileCmds.openDirInNewTab(file))
		addCmd(menu, fileCmds.openFileInSystemCmd(file))
		
		if (!osRoots.contains(file)) {
			menu.addSep
			addCmd(menu, fileCmds.compressToZip(file))
		}
	}

	Void addStandardFileCommands(Menu menu, FileResource resource) {
		menu.addSep
		addCmd(menu, fileCmds.compressToZip(resource.file))
		addCmd(menu, fileCmds.openInTextEditor(resource))
	}

	Void addCopyPasteCommands(Menu menu, FileResource resource) {
		file := resource.file
		menu.addSep
		addCmd(menu, globalCommands["afExplorer.cmdRenameFile"].command)
		addCmd(menu, globalCommands["afExplorer.cmdDeleteFile"].command)

		menu.addSep
//		addCmd(menu, fileCmds.cutFileCmd(file))
//		addCmd(menu, fileCmds.copyFileCmd(file))
//		addCmd(menu, fileCmds.pasteFileCmd(file))
		addCmd(menu, globalCommands["afReflux.cmdCut"].command)
		addCmd(menu, globalCommands["afReflux.cmdCopy"].command)
		addCmd(menu, globalCommands["afReflux.cmdPaste"].command)

		menu.addSep
		addCmd(menu, fileCmds.copyFileNameCmd(file))
		addCmd(menu, fileCmds.copyFilePathCmd(file))
		addCmd(menu, fileCmds.copyFileUriCmd(file))
	}	

	Void addFolderNewCommands(Menu menu, FileResource resource) {
		menu.addSep
		addCmd(menu, fileCmds.newFileCmd(resource.file))
		addCmd(menu, fileCmds.newFolderCmd(resource.file))
	}

	private Void addCmd(Menu menu, Command cmd) {
		menu.add(MenuItem.makeCommand(cmd))
	}
}
