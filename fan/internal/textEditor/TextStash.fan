
** Stashes resource specific values for use by multiple view instances. 
internal class TextStash {
	
	Str:Obj?	stash	:= Str:Obj?[:]
	
	@Operator
	Obj? get(Str key) {
		stash[key]
	}

	@Operator
	Void set(Str key, Obj? val) {
		stash[key] = val
	}
}
