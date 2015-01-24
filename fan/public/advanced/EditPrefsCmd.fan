using afIoc
using afReflux
using fwt

@NoDoc	// advanced
class EditPrefsCmd : RefluxCommand {
	@Inject private Reflux		reflux
	@Inject private Preferences	prefs
	@Inject private RefluxIcons icons
	@Inject private Dialogues	dialogues
			private Uri			fogTemplate
	
	new make(Type prefsType, Uri fogTemplate, |This|in) : super.make(in) {
		this.name = "Edit ${prefsType.name.toDisplayName}..."
		this.icon = icons["cmdEditPrefs"]
		this.fogTemplate = fogTemplate
	}
	
	override Void doInvoke(Event? event) {
		prefsFile := prefs.findFile(fogTemplate.name)
		
		if (prefsFile.exists) {
			reflux.load(prefsFile.uri.toStr)
			return
		}

		msg := "Preferences file does not exist:\n\n${prefsFile.osPath}\n\nCreating it for you..."
		cmd := Dialog.openMsgBox(Explorer#.pod, "cmdEditPrefs", reflux.window, msg, null, [dialogues.ok, dialogues.cancel])
		if (cmd == dialogues.ok) {
			// can't copy from fan:// files so we do it the long way round
			template := ((File) fogTemplate.get).readAllStr
			prefsFile.out.writeChars(template).close
			reflux.load(prefsFile.uri.toStr)
			if (prefsFile.parent != null)
				reflux.refresh(reflux.resolve(prefsFile.parent.uri.toStr))
		}
	}
}
