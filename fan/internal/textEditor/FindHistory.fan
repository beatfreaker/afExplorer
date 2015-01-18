using afIoc
using afReflux

**
** FindHistory maintains the most recent find text
** queries for the entire application.
**
@Serializable @NoDoc
class FindHistory {

	** Get whether find should match the case of the query term.
	Bool matchCase := false

	@Transient private Int max := 20
	private Str[] findList	:= Str[,]
	private Uri[] dirList	:= Uri[,]

	**
	** Log the given find text into the history.
	** Return this.
	**
	This pushFind(Str s) {
		if (s.size == 0) return this

		// remove first so it bubbles to top
		findList.remove(s)
		findList.insert(0, s)
		findList = findList[0..<max.min(findList.size)]
		return this
	}

	**
	** Log the given find directory into the history.
	** Return this.
	**
	This pushDir(Uri u) {
		if (!u.isDir) throw ArgErr("Uri must be a directory: $u")

		// remove first so it bubbles to top
		dirList.remove(u)
		dirList.insert(0, u)
		dirList = dirList[0..<max.min(dirList.size)]
		return this
	}

	**
	** Get a readonly copy of all the find text in the history.
	** The first item is the most recent query and the last
	** item is the oldest query.
	**
	Str[] find() {
		return findList.ro
	}

	**
	** Get a readonly copy of all the find directories in the
	** history. The first item is the most recent query and the
	** last item is the oldest query.
	**
	Uri[] dir() {
		return dirList.ro
	}

	**
	** Convenience to return [dir]`FindHistory.dir` as a 'Str[]'.
	**
	Str[] dirAsStr() {
		dirList.map |Uri u->Str| { u.toStr }
	}
}