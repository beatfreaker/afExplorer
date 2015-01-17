using afIoc
using afReflux
using gfx
using fwt
using concurrent

** (View) - A simple image viewer for file resources. 
class ImageViewer : View {

	@Inject private RefluxIcons 		icons
	@Inject private Registry			registry
			private ImageViewWidget?	imageWidget

	@NoDoc	// Boring!
	protected new make(|This| in) : super(in) { }
	
	** Displays the given 'FileResource' as an image.
	override Void load(Resource resource) {
		super.load(resource)
		fileResource := (FileResource) resource
		image := loadImage(fileResource.file) 

		imageWidget = ImageViewWidget(image ?: icons["icoImageNotFound"])
		toolBar := ToolBar {
			it.addCommand(registry.autobuild(ImageFullSizeCommand#, [this]))
			it.addCommand(registry.autobuild(ImageFitToWindowCommand#, [this]))
		}

	    content = EdgePane {
	    	top = EdgePane {
				it.top = InsetPane(2) {
					EdgePane {
						if (image != null) {
							left = GridPane {
								numCols = 2
								Label { text="Size"; font=Desktop.sysFont.toBold },
								Label { text="${image.size.w}px x ${image.size.h}px"},
							}
						} else
							left = Label { text="Image not found: ${fileResource.file.osPath}"}
						right =  toolBar
					},
				}
				it.bottom = BorderPane {
					it.border = Border("1, 0, 1, 0 $Desktop.sysNormShadow, #000, $Desktop.sysHighlightShadow")
				}
			}
			center = ScrollPane { it.content = imageWidget; it.border = false }
	    }		
	}
	
	** Expands or shrinks the image to fit the view.
	Void fitToWindow() {
		imageWidget?.doFitToWindow
	}

	** Displays the image at 100%
	Void showFullSize() {
		imageWidget?.doFullSize
	}

	private Image? loadImage(File file) {
		image := (Image?) (file.exists ? Image.makeFile(file) : null)
		
		if (image != null) {
			napTime := 0sec
			while (napTime < 200ms && (image.size.w == 0 || image.size.h == 0)) {
				napTime += 20ms
				Actor.sleep(20ms)
			}
			if (image.size.w == 0 || image.size.h == 0)
				image = null
		}
		
		return image
	}
	
	private Button toolBarCommand(Type cmdType, Obj[] args) {
		command	:= (Command) registry.autobuild(cmdType, args)
	    button  := Button.makeCommand(command)
	    if (command.icon != null)
	    	button.text = ""
		return button
	}

}

internal class ImageViewWidget : Canvas {
	Image 	image
	Float	zoom	:= 1f
	Int		border	:= 8
	Size	iSize
	
	new make(Image image) {
		this.image = image
		this.iSize = image.size
	}

	override Void onPaint(Graphics g) {
		// centre the image if it's smaller than the view
		w  := (parent.size.w - (border*2))
		h  := (parent.size.h - (border*2))
		dw := (zoom * image.size.w.toFloat).toInt
		dh := (zoom * image.size.h.toFloat).toInt
		x  := 0.max((w - dw) / 2)
		y  := 0.max((h - dh) / 2)
		g.brush = Color.white
		g.fillRect(0, 0, size.w, size.h)
		g.copyImage(image, Rect(0, 0, image.size.w, image.size.h), Rect(x + border, y + border, dw, dh))
	}

	override Size prefSize(Hints hints := Hints.defVal) { iSize }

	Void doFitToWindow() {
		w := (parent.size.w - (border*2)).toFloat / image.size.w.toFloat
		h := (parent.size.h - (border*2)).toFloat / image.size.h.toFloat
		zoom = w.min(h)
		iSize = parent.size
		parent->onLayout
		repaint
	}

	Void doFullSize() {
		zoom = 1f
		iSize = image.size
		parent->onLayout
		repaint
	}
}

internal class ImageFitToWindowCommand : RefluxCommand {
			private ImageViewer	imageView
	@Inject private RefluxIcons	icons

	new make(ImageViewer imageView, |This|in) : super.make(in) {
		this.imageView = imageView
		this.name = "Fit to Window"
		this.icon = icons["cmdImageFitToWindow"]
	}

	override Void doInvoke(Event? event) {
		imageView.fitToWindow
	}
}

internal class ImageFullSizeCommand : RefluxCommand {
			private ImageViewer	imageView
	@Inject private RefluxIcons	icons

	new make(ImageViewer imageView, |This|in) : super.make(in) {
		this.imageView = imageView
		this.name = "Zoom to 100%"
		this.icon = icons["cmdImageFullSize"]
	}

	override Void doInvoke(Event? event) {
		imageView.showFullSize
	}
}
