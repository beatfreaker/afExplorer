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

	@Transient	// saved in the session instead
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
const class FileAction {
	private const Str	ext
	private const Str[]	exts
			const Str 	verb
			const Str	launcherId

	new make(|This|? f := null) {
		f?.call(this)
		exts = ext.split
	}
	
	Bool matchesExt(Str that) {
		exts.any { it == that }
	}
}

@Serializable @NoDoc
class FileLauncher {
	Str 	id
	Str 	name
	Uri?	iconUri
	Uri		programUri
	new make(|This|? f := null) { f?.call(this) }
}
