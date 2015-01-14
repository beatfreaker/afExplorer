using build
using fanr

class Build : BuildPod {

	new make() {
		podName = "afExplorer"
		summary = "A file explorer with associated editors and viewers"
		version = Version("0.0.1")

		meta = [
			"proj.name"		: "Explorer",
			"repo.private"	: "true",

			"afIoc.module"	: "afReflux::RefluxModule"
		]

		depends = [	
			"sys        1.0.67 - 1.0", 
			"gfx        1.0.67 - 1.0",
			"fwt        1.0.67 - 1.0",
			"syntax     1.0.67 - 1.0",
			"concurrent 1.0.67 - 1.0",	// for loading images
			
			// ---- Core ------------------------
			"afBeanUtils  1.0.4  - 1.0", 
			"afConcurrent 1.0.8  - 1.0", 
			"afPlastic    1.0.16 - 1.0", 
			"afIoc        2.0.2  - 2.0", 
			"afIocConfig  1.0.16 - 1.0",
			
			"afReflux     0+"
		]

		srcDirs = [`fan/`, `fan/public/`, `fan/public/advanced/`, `fan/internal/`, `fan/internal/textEditor/`]
		resDirs = [`locale/`, `res/icons-file/`]
	}
}