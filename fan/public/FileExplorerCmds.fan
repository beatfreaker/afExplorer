using afIoc
using afReflux
using gfx
using fwt

class FileExplorerCmds {
	@Inject private Registry		registry
	@Inject private Reflux			reflux
	@Inject private RefluxIcons		refluxIcons
	@Inject	private FileExplorer	fileExplorer

	new make(|This|in) { in(this) }

	Command openFileCmd(File file) {
		command("OpenFile") {
			it.onInvoke.add {
				fileExplorer.openFile(file)
			}
		}
	}

	Command renameFileCmd(File file) {
		command("RenameFile") {
			it.name = "Rename"
			it.accelerator = Key("F2")
			it.onInvoke.add {
				fileExplorer.rename(file)
			}
		}
	}

	Command deleteFileCmd(File file) {
		command("DeleteFile") {
			it.name = "Delete"
			it.onInvoke.add {
				fileExplorer.delete(file)
			}
		}
	}

	Command newFileCmd(File file) {
		command("NewFile") {
			it.onInvoke.add {
				fileExplorer.newFile(file)
			}
		}
	}

	Command newFolderCmd(File file) {
		command("NewFolder") {
			it.onInvoke.add {
				fileExplorer.newFolder(file)
			}
		}
	}

	Command cutFileCmd(File file) {
		command("CutFile") {
			it.name = "Cut"
			it.onInvoke.add {
				fileExplorer.cut(file)
			}
		}
	}

	Command copyFileCmd(File file) {
		command("CopyFile") {
			it.name = "Copy"
			it.onInvoke.add {
				fileExplorer.copy(file)
			}
		}
	}

	Command pasteFileCmd(File file) {
		command("PasteFile") {
			it.name = "Paste"
			it.enabled = file.isDir
			it.onInvoke.add {
				fileExplorer.paste(file)
			}
		}
	}

	Command copyFileNameCmd(File file) {
		command("CopyFileName") {
			it.onInvoke.add {
				reflux.copyToClipboard(file.name)
			}
		}
	}

	Command copyFilePathCmd(File file) {
		command("CopyFilePath") {
			it.onInvoke.add {
				reflux.copyToClipboard(file.osPath)
			}
		}
	}

	Command copyFileUriCmd(File file) {
		command("CopyFileUri") {
			it.onInvoke.add {
				reflux.copyToClipboard(file.uri.toStr)
			}
		}
	}

	Command actionFileCmd(File file, FileAction action, FileLauncher laucher) {
		command("actionFile") {
			it.name = "${action.verb} with ${laucher.name}"
			it.icon = refluxIcons.fromUri(laucher.iconUri)
			it.onInvoke.add {
				Process([laucher.programUri.toFile.osPath, file.osPath], file.parent).run
			}
		}
	}

	private RefluxCommand command(Str baseName) {
		((RefluxCommand) registry.autobuild(RefluxCommand#)) {
			it.name = baseName.toDisplayName
			it.icon = refluxIcons["cmd${baseName}"]
		}
	}
}

