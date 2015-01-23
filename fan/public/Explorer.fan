using afIoc
using afReflux
using gfx
using fwt

** (Service) - 
** The main service API for Explorer operations.
mixin Explorer {
	abstract Void rename(File file)
	abstract Void delete(File file)
	abstract Void cut(File file)
	abstract Void copy(File file)
	abstract Void paste(File destDir)
	
	** Opens a dialogue for the file name before creating an empty file.
	** File name defaults to 'NewFile.txt'.	
	abstract Void newFile(File containingFolder, Str? defFileName := null)
	
	** Opens a dialogue for the folder name before creating an empty folder.
	** Folder name defaults to 'NewFolder'.
	abstract Void newFolder(File containingFolder, Str? defFolderName := null)

	abstract Void openFileInSystem(File file)

	abstract Void compressToZip(File toCompress, File dst)
	
	abstract Image fileToIcon(File f)
	abstract Image urlToIcon(Uri url)

	abstract ExplorerPrefs preferences()
}
	
internal class ExplorerImpl : Explorer {
	@Inject private Registry	registry
	@Inject private RefluxIcons	icons
	@Inject private Images		images
	@Inject private Preferences	prefs
	@Inject private Reflux		reflux
	@Inject private Errors		errors
	@Inject private Dialogues	dialogues
					Uri			fileIconsRoot	:= `fan://afExplorer/res/icons-file/`

	private File? copiedFile
	private File? cutFile

	new make(|This| in) { in(this) }

	override Void rename(File file) {
		newName := dialogues.openPromptStr("Rename", file.name)
		if (newName != null) {
			file.rename(newName)
			reflux.refresh
		}
	}

	override Void delete(File file) {
		okay := dialogues.openQuestion("Delete ${file.osPath}?", null, dialogues.yesNo)
		if (okay == dialogues.yes) {
			file.delete
			reflux.refresh
		}
	}

	override Void cut(File file) {
		cutFile		= file
		copiedFile	= null
	}
	
	override Void copy(File file) {
		cutFile		= null
		copiedFile	= file
	}

	override Void paste(File destDir) {
		// TODO: dialog for copy overwrite options
		if (cutFile != null) {
			cutFile.moveInto(destDir)
			cutFile = null
		}
		if (copiedFile != null) {
			copiedFile.copyInto(destDir)
			copiedFile = null
		}
		reflux := (Reflux) registry.serviceById(Reflux#.qname)
		reflux.refresh
	}
	
	override Void newFile(File containingFolder, Str? defFileName := null) {
		fileName := dialogues.openPromptStr("New File", defFileName ?: "NewFile.txt")
		if (fileName != null) {
			containingFolder.createFile(fileName)
			reflux.refresh
		}
	}

	override Void newFolder(File containingFolder, Str? defFolderName := null) {
		dirName := dialogues.openPromptStr("New Folder", defFolderName ?: "NewFolder")
		if (dirName != null) {
			containingFolder.createDir(dirName)
			reflux.refresh
		}
	}
	
	override Void openFileInSystem(File file) {
		Desktop.launchProgram(file.uri)
	}
	
	override Void compressToZip(File toCompress, File dst) {
		if (dst.isDir || dst.exists)
			throw ArgErr("Cannot write to $dst")
		
		try {
			// TODO: Pop up progress monitor for long running zip tasks
			parentUri := toCompress.parent.uri
			zip := Zip.write(dst.out)
			try {
				toCompress.walk |src| {
					if (src.isDir) return

					path := src.uri.relTo(parentUri)
					out := zip.writeNext(path)
					try {
						src.in(16 * 1024).pipe(out)
					} finally
						out.close
				}
			} finally
				zip.close

		} catch (Err err)
			errors.add(err)

		reflux.refresh
	}
	
	override Image fileToIcon(File f) {
		hidden := preferences.isHidden(f)

		if (f.isDir) {
			// can't cache osRoots 'cos it changes with flash drives et al
			osRoots	:= File.osRoots.map { it.normalize }		
			name := osRoots.contains(f) ? "icoFolderRoot" : "icoFolder"
			return hidden ? icons.getFaded(name) : icons.get(name)
		}
		
		// if the image is small enough ~5k, return a thumbnail as the icon
		// .svg files and the like cause ugly stack traces as FWT logs the Err before returning null... Grrr!!
		if ("bmp jpg jpeg gif png".split.contains(f.ext) && f.size < (5 * 1024)) {
			if (images.contains(f.uri))
				return hidden ? images.getFaded(f.uri) : images.get(f.uri)

			icon := images.load(f.uri, false)
			if (icon != null) {
				if (icon.size == Size(16, 16)) {
					images[f.uri] = icon
					return icon
				}

				// note we have to return a 16x16 image else SWT scales it for us
				if (icon.size.w <= 16 && icon.size.h <= 16) {
					newIcon := Image(Size(16, 16)) |Graphics g| {
						g.drawImage(icon, (16 - icon.size.w) / 2, (16 - icon.size.h) / 2)
					}
					images[f.uri] = newIcon
					return newIcon
				}

				if (icon.size.w >= icon.size.h) {
					newH := icon.size.h * 16 / icon.size.w
					newIcon := icon.resize(Size(16, newH))
					if (newH < 16) {
						newIcon = Image(Size(16, 16)) |Graphics g| {
							g.drawImage(newIcon, 0, (16 - newH) / 2)
						}
					}
					images[f.uri] = newIcon
					return newIcon
				}

				if (icon.size.w <= icon.size.h) {
					newW := icon.size.w * 16 / icon.size.h
					newIcon := icon.resize(Size(newW, 16))
					if (newW < 16) {
						newIcon = Image(Size(16, 16)) |Graphics g| {
							g.drawImage(newIcon, (16 - newW) / 2, 0)
						}
					}
					images[f.uri] = newIcon
					return newIcon
				}				
			}
		}
		
		// look for explicit match based off ext
		if (f.ext != null) {
			icon := fileIcon("file${f.ext.capitalize}.png", hidden)
			if (icon != null) return icon
		}
		
		mimeType := f.mimeType?.noParams
		if (mimeType != null) {
			mime := mimeType.mediaType.fromDisplayName.capitalize + mimeType.subType.fromDisplayName.capitalize
			icon := fileIcon("file${mime}.png", hidden)
			if (icon != null) return icon

			mime = mimeType.mediaType.fromDisplayName.capitalize
			icon = fileIcon("file${mime}.png", hidden)
			if (icon != null) return icon
		}

		return fileIcon("file.png", hidden)
	}
	
	override Image urlToIcon(Uri url) {

		// look for explicit match based off ext
		if (url.ext != null) {
			icon := fileIcon("file${url.ext.capitalize}.png", false)
			if (icon != null) return icon
		}
		
		mimeType := url.mimeType?.noParams
		if (mimeType != null) {
			mime := mimeType.mediaType.fromDisplayName.capitalize + mimeType.subType.fromDisplayName.capitalize
			icon := fileIcon("file${mime}.png", false)
			if (icon != null) return icon

			mime = mimeType.mediaType.fromDisplayName.capitalize
			icon = fileIcon("file${mime}.png", false)
			if (icon != null) return icon
		}

		return fileIcon("fileTextHtml.png", false)
	}

	override once ExplorerPrefs preferences() {
		prefs.loadPrefs(ExplorerPrefs#)
	}

	private Image? fileIcon(Str fileName, Bool hidden) {
		uri := fileIconsRoot.plusName(fileName)
		return hidden ?	images.getFaded(uri, false) : images.get(uri, false)
	}
}
