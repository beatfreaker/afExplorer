using afIoc
using afReflux
using gfx
using fwt

internal class ExplorerCmds {
	@Inject private Registry		registry
	@Inject private Reflux			reflux
	@Inject private RefluxIcons		refluxIcons
	@Inject	private Explorer		explorer

	new make(|This|in) { in(this) }

	Command openDirInNewTab(File file) {
		command("OpenInNewTab") {
			it.onInvoke.add {
				reflux.load(file.uri.toStr, LoadCtx() { newTab=true })
			}
		}
	}

	Command openFileInSystemCmd(File file) {
		command("OpenInSystem") {
			it.onInvoke.add {
				explorer.openFileInSystem(file)
			}
		}
	}

	Command openFileWithViewCmd(Resource resource, FileViewMapping viewer) {
		command("OpenIn${viewer.viewType.name}", "") {
			it.onInvoke.add {
				reflux.loadResource(resource, LoadCtx() { it.viewType = viewer.viewType })
			}
		}
	}

	Command newFileCmd(File file) {
		command("NewFile...") {
			it.onInvoke.add {
				explorer.newFile(file)
			}
		}
	}

	Command newFolderCmd(File file) {
		command("NewFolder...") {
			it.onInvoke.add {
				explorer.newFolder(file)
			}
		}
	}

	Command cutFileCmd(File file) {
		command("CutFile") {
			it.name = "Cut"
			it.onInvoke.add {
				explorer.cut(file)
			}
		}
	}

	Command copyFileCmd(File file) {
		command("CopyFile") {
			it.name = "Copy"
			it.onInvoke.add {
				explorer.copy(file)
			}
		}
	}

	Command pasteFileCmd(File file) {
		command("PasteFile") {
			it.name = "Paste"
			it.enabled = file.isDir
			it.onInvoke.add {
				explorer.paste(file)
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
		command("ActionFile", "") {
			it.name = "${action.verb} with ${laucher.name}"
			it.icon = refluxIcons.fromUri(laucher.iconUri, false)
			it.onInvoke.add {
				Process([laucher.programUri.toFile.osPath, file.osPath], file.parent).run
			}
		}
	}

	private RefluxCommand command(Str baseName, Str? iconName := null) {
		((RefluxCommand) registry.autobuild(RefluxCommand#, [null, null, null])) {
			it.name = baseName.toDisplayName.replace(" In ", " in ")
			if (iconName != null && !iconName.isEmpty)
				it.icon = refluxIcons[iconName ?: "cmd${baseName}"]
		}
	}
}

