using afIoc
using afReflux
using fwt

class EditPrefsCmd : RefluxCommand {
	@Inject RefluxIcons icons
	
	new make(Type prefsType, Uri fogTemplate, |This|in) : super.make(in) {
		this.name = "Edit ${prefsType.name.toDisplayName}..."
		this.icon = icons["cmdEditPrefs"]
	}
	
	override Void doInvoke(Event? event) {
		
	}
}
