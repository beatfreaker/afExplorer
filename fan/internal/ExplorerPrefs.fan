using afIoc

@Serializable @NoDoc
class ExplorerPrefs {

	@Inject @Transient 
	private ExplorerEvents?	events
	
	Str:Uri favourites := 
		// FIXME: maps are serialised as ordered
		Str:Uri[:] { it.ordered=true }
			// FIXME: These dirs are Windows only
			.add("My Computer", 	`file:/C:/`) 
			.add("My Documents",	`file:/C:/Users/${Env.cur.user}/Documents/`) 
			.add("My Downloads",	`file:/C:/Users/${Env.cur.user}/Downloads/`) 
			.add("Fantom Home",		Env.cur.homeDir.normalize.uri)
			.add("Temp", 			`file:/C:/Temp/`) 

	Bool showHiddenFiles	:= false {
		set {
			&showHiddenFiles = it
			events?.onShowHiddenFiles(it)
		}
	}
	
	Str[] hiddenNameFilters := [
		"^\\..*\$",
		"^\\\$.*\$"
	]

	Str[] hiddenPathFilters := [
		"^/C:/Boot/\$",
		"^/C:/MSOCache/\$",
		"^/C:/ProgramData/\$",
		"^/C:/Recovery/\$",
		"^/C:/System Volume Information/\$",
		"^/C:/bootmgr\$",
		"^/C:/BOOTSECT.BAK\$",
	]
	
	FileLauncher[] fileLaunchers := [,]
	
	FileAction[] fileActions := [,]
	
	new make(|This|? f := null) { f?.call(this) }

	Bool isHidden(File file) {
		hiddenNameFilters.map { it.toRegex }.any |Regex rex -> Bool| { rex.matches(file.name) } ||
		hiddenPathFilters.map { it.toRegex }.any |Regex rex -> Bool| { rex.matches(file.uri.pathStr) }
	}

	Bool shouldHide(File file) {
		showHiddenFiles ? false : isHidden(file)
	}
}


@Serializable @NoDoc
class FileAction {
	Str 	verb
	Str		ext
	Str		launcherId
	new make(|This|? f := null) { f?.call(this) }
}

@Serializable @NoDoc
class FileLauncher {
	Str 	id
	Str 	name
	Uri		iconUri
	Uri		programUri
	new make(|This|? f := null) { f?.call(this) }
}
