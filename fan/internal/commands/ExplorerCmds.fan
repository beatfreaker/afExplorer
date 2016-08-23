using afIoc
using afReflux
using gfx
using fwt

internal class ExplorerCmds {
	@Inject private Scope			scope
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
		command("NewFile...", "cmdNewFile") {
			it.onInvoke.add {
				explorer.newFile(file)
			}
		}
	}

	Command newFolderCmd(File file) {
		command("NewFolder...", "cmdNewFolder") {
			it.onInvoke.add {
				explorer.newFolder(file)
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
		command("CopyOSPath") {
			it.onInvoke.add {
				reflux.copyToClipboard(file.osPath)
			}
		}
	}

	Command copyFileUriCmd(File file) {
		command("CopyURI") {
			it.onInvoke.add {
				reflux.copyToClipboard(file.uri.toStr)
			}
		}
	}

	Command actionFileCmd(File file, FileAction action, FileLauncher launcher) {
		command("ActionFile", "") {
			it.name = "${action.verb} with ${launcher.name}"
			it.icon = refluxIcons.fromUri(launcher.iconUri, false)
			it.onInvoke.add {
				Process([launcher.programUri.toFile.osPath, file.osPath], file.parent).run
			}
		}
	}

	Command compressToZip(File file) {
		name := (!file.isDir && file.ext != null) ? file.name[0..<-(file.ext.size+1)] : file.name
		name += ".zip"
		return command("Compress to '${name}'", "cmdCompressToZip") {
			it.onInvoke.add {
				explorer.compressToZip(file, (file.isDir ? file.parent : file) + name.toUri)
			}
		}
	}

	Command compressToGz(File file) {
		name := file.name + ".gz"
		return command("Compress to '${name}'", "cmdCompressToGz") {
			it.onInvoke.add {
				explorer.compressToGz(file)
			}
		}
	}

	Command openInTextEditor(Resource resource) {
		command("EditText") {
			it.onInvoke.add {
				reflux.loadResource(resource, LoadCtx { it.viewType = TextEditor# })
			}
		}
	}

	Command showFileProperties(FileResource fileResource) {
		command("Properties") {
			it.onInvoke.add {
				props := (FilePropertiesDialog) scope.build(FilePropertiesDialog#, [fileResource])
				props.open
			}
		}
	}

	private RefluxCommand command(Str baseName, Str? iconName := null) {
		((RefluxCommand) scope.build(RefluxCommand#, [null, null, null])) {
			if (baseName.containsChar(' '))
				it.name = baseName
			else
				it.name = baseName.toDisplayName.replace(" In ", " in ")

			if (iconName == null || (iconName != null && !iconName.isEmpty))
				it.icon = refluxIcons[iconName ?: "cmd${baseName}"]
		}
	}
}

