using afIoc
using afBeanUtils
using afReflux
using gfx
using fwt

class FileResource : Resource {

	@Inject private 		FileExplorer		_fileExplorer
	@Inject private 		Errors				_errors
	@Inject protected const Registry			registry
	@Inject protected const DefaultFileViews	defaultViews
	@Inject protected 		FileExplorerCmds	fileCmds

	override Uri 	uri
	override Str 	name
	override Image?	icon
	override Str	displayName
			 File	file

	new make(|This|in) : super.make(in) { 
		displayName = file.osPath
	}

	override Type? defaultView() {
		defaultViews[file.ext]
	}
	
	override Menu populatePopup(Menu m) {
		menu := super.populatePopup(m)
		
		if (!file.isDir) {
			addCmd(menu, fileCmds.openFileCmd(file))
			
			fileExt := file.ext.lower
			prefs	:= _fileExplorer.preferences
			actions := prefs.fileActions.findAll { it.ext == fileExt }
			actions.each |action| {
				launcher := prefs.fileLaunchers.find { it.id == action.launcherId }
				if (launcher == null)
					_errors.add(ArgNotFoundErr("Could not find a launcher with id '${action.launcherId}'", prefs.fileLaunchers.map { it.id }))
				else
					addCmd(menu, fileCmds.actionFileCmd(file, action, launcher))
			}

			menu.addSep
		}		

		addCmd(menu, fileCmds.renameFileCmd(file))
		addCmd(menu, fileCmds.deleteFileCmd(file))

		menu.addSep
		addCmd(menu, fileCmds.cutFileCmd(file))
		addCmd(menu, fileCmds.copyFileCmd(file))
		addCmd(menu, fileCmds.pasteFileCmd(file))

		menu.addSep
		addCmd(menu, fileCmds.copyFileNameCmd(file))
		addCmd(menu, fileCmds.copyFilePathCmd(file))
		addCmd(menu, fileCmds.copyFileUriCmd(file))

		if (file.isDir) {
			menu.addSep
			addCmd(menu, fileCmds.newFileCmd(file))
			addCmd(menu, fileCmds.newFolderCmd(file))
		}
		
		// open
		// open in new tab
		// edit
		// find in files
		// cmd prompt
		// add to zip
		// properties
		
		return menu 
	}
	
	override Void doAction() {
		// show view if there is one 
		if (defaultViews[file.ext] != null) {
			super.doAction
			return
		}

		if (file.isDir) {
			super.doAction
			return			
		}
		
		// else launch it
		Desktop.launchProgram(uri)
	}
	
	Void addCmd(Menu menu, Command cmd) {
		menu.add(MenuItem.makeCommand(cmd))
	}
}



class FolderResource : FileResource {
	new make(|This|in) : super.make(in) { }
	override Type? defaultView() {
		FolderView#
	}
}
