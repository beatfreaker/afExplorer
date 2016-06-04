using build
using fanr

class Build : BuildPod {

	new make() {
		podName = "afExplorer"
		summary = "A Reflux file explorer application with reusable editors and viewers"
		version = Version("0.1.1")

		meta = [
			"proj.name"		: "Explorer",
			"afIoc.module"	: "afExplorer::ExplorerModule",
			"repo.internal"	: "true",
			"repo.tags"		: "app",
			"repo.public"	: "false"
		]

		depends = [	
			"sys         1.0.68 - 1.0", 
			"gfx         1.0.68 - 1.0",
			"fwt         1.0.68 - 1.0",
			"syntax      1.0.68 - 1.0",
			"util        1.0.68 - 1.0",
			
			"fandoc      1.0.68 - 1.0",
			"compilerDoc 1.0.68 - 1.0",
			"web         1.0.68 - 1.0",
			
			// ---- Core ------------------------
			"afBeanUtils  1.0.8  - 1.0", 
			"afIoc        3.0.0  - 3.0", 
			"afReflux     0.1.1  - 1.0"
		]

		srcDirs = [`fan/`, `fan/internal/`, `fan/internal/commands/`, `fan/internal/textEditor/`, `fan/public/`, `fan/public/advanced/`, `fan/todo/`, `test/`]
		resDirs = [`doc/`, `locale/`, `res/css/`, `res/fogs/`, `res/icons-file/`, `res/images/`, `res/syntax/`]
	}
}