using afIoc::Inject
using gfx
using fwt
using afReflux
using afConcurrent
using concurrent

internal class FilePropertiesDialog {
	
	@Inject private Reflux			reflux
	@Inject private LocaleFormat	format
	
	FileResource resource
	
	new make(FileResource resource, |This| in) {
		in(this)
		this.resource = resource
	}

	Obj? open() {
		file	:= resource.file
		sizeStr	:= file.size == null ? "???" : format.fileSize(file.size) + " (" + file.size.toLocale + " bytes)"
		
		details	:= GridPane {
			numCols		= 2
			expandCol	= 1
			halignCells	= Halign.fill
			
			Label { it.text="Name:"; it.image = resource.icon }, text(resource.name),
			Label { it.text="OS Path:"	},	text(file.osPath),
			Label { it.text="URI:" 		},	text(file.uri.toStr),
			Label { it.text="Modified:"	},	text(format.dateTime(file.modified)),
		}
		
		isRoot	:= File.osRoots.map { it.normalize }.contains(file)
		isDir	:= !isRoot && file.isDir
		isFile	:= !isRoot && !isDir
		
		if (isFile) {
			details {
				Label { it.text="Size:"	},	text(sizeStr),
			}
		}
		
		dirPool := null as ActorPool
		if (isDir) {
			format		:= Unsafe(format)
			txtSize 	:= Unsafe(text(""))
			txtContains := Unsafe(text(""))
			details {
				Label { it.text="Contains:"	},	txtContains.val,
				Label { it.text="Size:"		},	txtSize.val,
			}

			dirPool = ActorPool()
			Synchronized(dirPool).asyncLater(10ms) |->| {
				noFiles := AtomicInt()
				noDirs  := AtomicInt()
				noBytes := AtomicInt()

				updateFunc := |->| {
					forma := (LocaleFormat) format.val
					tSize := (Text) txtSize.val
					tCont := (Text) txtContains.val
					tSize.text = forma.fileSize(noBytes.val)
					tCont.text = "${noFiles.val.toLocale} files, ${noDirs.val.toLocale} folders"
				}

				tstamp := Duration.now
				file.walk |f| {
					if (f.isDir)
						noDirs.incrementAndGet
					else {
						noFiles.incrementAndGet
						noBytes.addAndGet(f.size ?: 0)
					}
					
					if ((Duration.now - tstamp) > 200ms) {
						tstamp = Duration.now
						Desktop.callAsync(updateFunc)
					}
				}
				Desktop.callAsync(updateFunc)
			}
		}
		
		if (isRoot) {
			store := file.store
			totalInt := 0
			availInt := 0
			usedInt  := 0
			totalStr := null as Str
			availStr := null as Str
			usedStr  := null as Str
			if (store.totalSpace != null) {
				totalInt = store.totalSpace
				totalStr = format.fileSize(totalInt)
				
				if (store.availSpace != null) {
					availInt = store.availSpace
					availStr = format.fileSize(availInt)
					usedInt  = totalInt - availInt
					usedStr  = format.fileSize(usedInt)
				}
			}
			percent := totalInt == 0 ? 0f : 100f * usedInt / totalInt
			details {
				BorderPane { it.border = Border("1, 0, 0, 0"); }, BorderPane { it.border = Border("1, 0, 0, 0"); },
				Label { it.text="Total space:"	},	text(totalStr ?: "???"),
				Label { it.text="Used space:"	},	text(usedStr  ?: "???"),
				Label { it.text="Free space:"	},	text(availStr ?: "???"),
				// only 0 - 100 % seems to work!?
				Label { it.text=percent.toLocale("0.0")+"% full" }, ProgressBar { it.min = 0; it.max = 100; it.val = 100 * usedInt / totalInt; it.indeterminate = (availStr == null) },
			}
		}
		
		dialog := Dialog(reflux.window) {
			it.mode		= WindowMode.modeless
			it.title	= "${resource.name} Properties"
			it.body		= details
			it.details	= null
			it.commands	= [Dialog.ok]
			it.onClose.add |->| {
				dirPool?.kill
			}
		}
		dialog.icon		= resource.icon	// doesn't set when in it-block
		return dialog.open
		
	}

	private Text text(Str txt) {
		Text { it.text=txt; it.editable=false; it.border=false }
	}
}
