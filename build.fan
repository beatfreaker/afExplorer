using build
using fanr

class Build : BuildPod {

	new make() {
		podName = "afExplorer"
		summary = "A Reflux file explorer application with reusable editors and viewers"
		version = Version("0.0.9")

		meta = [
			"proj.name"		: "Explorer",
			"afIoc.module"	: "afReflux::RefluxModule",
			"internal"		: "true",
			"tags"			: "app",
			"repo.private"	: "true"
		]

		depends = [	
			"sys         1.0.67 - 1.0", 
			"gfx         1.0.67 - 1.0",
			"fwt         1.0.67 - 1.0",
			"syntax      1.0.67 - 1.0",
			"util        1.0.67 - 1.0",
			
			"fandoc      1.0.67 - 1.0",
			"compilerDoc 1.0.67 - 1.0",
			"web         1.0.67 - 1.0",
			
			
			// ---- Core ------------------------
			"afBeanUtils  1.0.4  - 1.0", 
			"afIoc        2.0.6  - 2.0", 
			
			"afReflux     0.0.6+"
		]

		srcDirs = [`test/`, `fan/`, `fan/todo/`, `fan/public/`, `fan/public/advanced/`, `fan/internal/`, `fan/internal/textEditor/`, `fan/internal/commands/`]
		resDirs = [`locale/`, `res/css/`, `res/fogs/`, `res/icons-file/`, `res/syntax/`]
	}
}