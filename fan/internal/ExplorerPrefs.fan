using afIoc

@Serializable @NoDoc
class ExplorerPrefs {

	@Inject @Transient 
	private ExplorerEvents?	events
	
	Str:Str favourites := 
		Str:Str[:] { it.ordered=true }
			.add("My Computer", 	"file:/") 
			.add("Fantom Home",		"\${Env.cur.homeDir}")
			.add("Work Dir",		"\${Env.cur.workDir}")
			.add("Temp", 			"\${Env.cur.tempDir}") 

	Bool showHiddenFiles	:= false {
		set {
			if (&showHiddenFiles != it) {
				&showHiddenFiles = it
				events?.onShowHiddenFiles(it)
			}
		}
	}

	Str[] hiddenNameFilters := [
		"^\\..*\$",
		"^\\\$.*\$",
		"^desktop.ini\$"
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
