# Nim Application Bundler

Nab's goal is to allow you to bundle any Nim project for various platforms with
a single command -- without cluttering your repo with a bunch of files.

## Credit

A lot of credit goes to yglukhov, who put a lot of work into getting nimx builds
working. The goal here is to take a lot of that effort, untether it, and add a
user experience that makes bundling Nim so easy that users don't have to worry
about setup.

## Supported platforms

Currently supported:

* Linux
* Mac
* iOs simulator

## Installation

To install, run:

```
nimble install https://github.com/Nycto/nab.git
```

## Getting started

To configure the bundling for a nimble package, run:

```
nab init
```

This will create a `nab.cfg` file in the root of your project -- check this
file in to your git repo.

## Building for various platforms

Once installed and initialized, you can build for various platforms using the
following commands:

```
nab iOsSim
```

```
nab Linux
```

```
nab MacOS
```

Note that nab doesn't support cross compiling. To build for iOs or Mac, you must
be _on_ a Mac.

## Building and running

You can add `--run` or `-r` to both build and execute your application. For
example:

```
nab --run iOsSim
```

## Resources

* https://blog.wasin.io/2018/10/19/build-sdl2-application-on-ios.html
* https://github.com/yglukhov/nim-sdl-template
* https://www.thomasdenney.co.uk/blog/2015/1/27/nim-on-ios/
* https://github.com/yglukhov/nimx/blob/cf71e8ae/nimx/naketools.nim
