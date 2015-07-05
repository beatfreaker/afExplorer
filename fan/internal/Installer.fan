using afIoc

internal class Installer {
	@Inject private Log log
	
	new make(|This|in) { in(this) }

	Void installFandocSyntaxFile() {
		etcUri	:= `etc/syntax/syntax-fandoc.fog`
		etcFile := Env.cur.findFile(etcUri, false)

		// copy over syntax-fandoc.fog
		if (etcFile == null) {
			etcFile = (Env.cur.workDir + etcUri).normalize
			podUri	:= `fan://afExplorer/res/syntax/syntax-fandoc.fog`
			podFile := Explorer#.pod.file(podUri, false)
			
			try {
				podFile.copyTo(etcFile)
				log.info("Installed fandoc syntax file to: ${etcFile}")
			} catch (Err err) {
				log.warn("Could not copy syntax file to: ${etcFile} - ${err.typeof.qname} - ${err.msg}")
				return	// abandon installation - if the syntax file doesn't exist, don't update ext.props 
			}
		}
		
		// update syntax ext.props
		synUri	:= `etc/syntax/ext.props`
		synFile := Env.cur.findFile(synUri, false)?.normalize
		if (synFile == null)
			log.warn("Could not find file: ${synUri}")

		else {
			synProps := synFile.readProps
			if (!synProps.containsKey("fandoc") || !synProps.containsKey("fdoc")) {
				synStr := synFile.readAllStr + "\n// fandoc rules\n"

				if (!synProps.containsKey("fandoc"))
					synStr += "fandoc=fandoc\n"

				if (!synProps.containsKey("fdoc"))
					synStr += "fdoc=fandoc\n"

				synFile.out.writeChars(synStr).close
				log.info("Updated syntax mapping file: ${etcFile}")
			}
		}
	}
}
