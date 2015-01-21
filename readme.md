#Explorer v0.0.2
---
[![Written in: Fantom](http://img.shields.io/badge/written%20in-Fantom-lightgray.svg)](http://fantom.org/)
[![pod: v0.0.2](http://img.shields.io/badge/pod-v0.0.2-yellow.svg)](http://www.fantomfactory.org/pods/afExplorer)
![Licence: MIT](http://img.shields.io/badge/licence-MIT-blue.svg)

## Overview

*Explorer is a support library that aids Alien-Factory in the development of other libraries, frameworks and applications. Though you are welcome to use it, you may find features are missing and the documentation incomplete.*

`Explorer` is a file explorer application based on the [Reflux](http://www.fantomfactory.org/pods/afReflux) framework. More than just an application, Explorer also provides Views and

Current features:

- System file explorer
- Fantom documentation viewer
- A better web browser / html viewer
- Fandoc file viewer
- Text editor (borrowed from [fluxText](http://fantom.org/doc/fluxText/index.html))
- Syntax highlighting (uses [syntax](http://fantom.org/doc/syntax/index.html))

The small things that make me use it:

- Quick view / edit toggling with F12
- Easily show / hide hidden files
- Text editor word wrapping (optional)
- Address bar accepts pod names, e.g. `afIoc`

## Install

Install `Explorer` with the Fantom Repository Manager ( [fanr](http://fantom.org/doc/docFanr/Tool.html#install) ):

    C:\> fanr install -r http://repo.status302.com/fanr/ afExplorer

To use in a [Fantom](http://fantom.org/) project, add a dependency to `build.fan`:

    depends = ["sys 1.0", ..., "afExplorer 0.0"]

## Documentation

Full API & fandocs are available on the [Status302 repository](http://repo.status302.com/doc/afExplorer/).

## Quick Start

Simply start Explorer from the command line:

```
C:\> fan afExplorer

[afIoc] Adding module definition for afReflux::RefluxModule
[afIoc] Adding module definition for afExplorer::ExplorerModule
   ___    __                 _____        _
  / _ |  / /_____  _____    / ___/__  ___/ /_________  __ __
 / _  | / // / -_|/ _  /===/ __// _ \/ _/ __/ _  / __|/ // /
/_/ |_|/_//_/\__|/_//_/   /_/   \_,_/__/\__/____/_/   \_, /
                                     Explorer v0.0.2 /___/

IoC Registry built in 216ms and started up in 10ms
```

![Example Screenshot](http://static.alienfactory.co.uk/fantom-docs/afExplorer.screenshot.png)

Explorer may optionally be started with a list of URIs to be opened up in tabs:

```
C:\> fan afExplorer C:\Temp

C:\> fan afExplorer http://www.fantomfactory.org/ 

C:\> fan afExplorer afIoc::Registry
```

