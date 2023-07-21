# carton 📦

## Watcher, bundler, and test runner for your [SwiftWasm](https://swiftwasm.org/) apps

The main goal of `carton` is to provide a smooth zero-config experience when developing for WebAssembly.
It currently supports these features with separate commands:

- Creating basic package boilerplate for apps built with SwiftWasm with `carton init`.
- Watching the app for source code changes and reloading it in your browser with `carton dev`.
- Running your XCTest suite in the full JavaScript/DOM environment with `carton test`.
- Optimizing and packaging the app for distribution with `carton bundle`.
- Managing SwiftWasm toolchain and SDK installations with `carton sdk`.

## Motivation

The main motivation for `carton` came after having enough struggles with
[webpack.js](https://webpack.js.org), trying to make its config file work, looking for appropriate
plugins. At some point the maintainers became convinced that the required use of `webpack` in
SwiftWasm projects could limit the wider adoption of SwiftWasm itself. Hopefully, with `carton` you
can avoid using `webpack` altogether. `carton` also simplifies a few other things in your SwiftWasm
development workflow such as toolchain and SDK installations.

## Getting started

### Requirements

- macOS 11 and Xcode 13.2.1 or later. macOS 10.15 may work, but is untested.
- [Swift 5.5 or later](https://swift.org/download/) and Ubuntu 18.04 or 20.04 for Linux users.

### Installation

On macOS `carton` can be installed with [Homebrew](https://brew.sh/). Make sure you have Homebrew
installed and then run:

```sh
brew install swiftwasm/tap/carton
```

> **Note**
> If you can't install the latest carton via `brew upgrade swiftwasm/tap/carton`, please try `rm -rf $(brew --prefix)/Library/Taps/swiftwasm/homebrew-tap/ && brew tap swiftwasm/tap` and retry again. The `master` branch was renamed to `main`, so you need to update your local tap repo.


`carton` is also available as a Docker image for Linux. You can pull it with this command:

```
docker pull ghcr.io/swiftwasm/carton:latest
```

If Docker images are not suitable for you, you'll have to build `carton` from sources on Ubuntu.
Clone the repository and run `./install_ubuntu_deps.sh` in the root directory of the clone. After
that completes successfully, run `swift build -c release`, the `carton` binary will be located in
the `.build/release` directory after that. Unfortunately, other Linux distributions are currently
not supported.

### Version compatibility

`carton` previously embedded runtime parts of [the JavaScriptKit library](https://github.com/swiftwasm/JavaScriptKit).
This runtime allows Swift and JavaScript code to interoperate in Node.js and browser environments. Because of how
JavaScriptKit runtime was embedded, older versions of JavaScriptKit were incompatible with different versions of
`carton` and vice versa. This incompatibility between different versions was resolved starting with JavaScriptKit 0.15
and `carton` 0.15. All version combinations of `carton` and JavaScriptKit higher than those are compatible with each
other.

You still have to keep in mind that older versions of SwiftWasm may be incompatible with newer `carton`. You can follow
the compatibility matrix if you need to use older verions:

| `carton` version | SwiftWasm version | JavaScriptKit version | Tokamak version |
| ---------------- | ----------------- | --------------------- | --------------- |
| 0.15+            | 5.6               | 0.15+                 | 0.10.1+         |
| 0.14             | 5.6               | 0.14                  | 0.10            |
| 0.13             | 5.5               | 0.13                  | 0.9.1           |
| 0.12.2           | 5.5               | 0.12                  | 0.9.1           |
| 0.12.0           | 5.5               | 0.11                  | 0.9.0           |
| 0.11.0           | 5.4               | 0.10.1                | 0.8.0           |

### Usage

The `carton init` command initializes a new SwiftWasm project for you (similarly to
`swift package init`) with multiple templates available at your choice. `carton init --template tokamak`
creates a new [Tokamak](https://tokamak.dev/) project, while `carton init --template basic` (equivalent
to `carton init`) creates an empty SwiftWasm project with no dependencies. Also, `carton init list-templates`
provides a complete list of templates (with only `basic` and `tokamak` available currently).

The `carton dev` command builds your project with the SwiftWasm toolchain and starts an HTTP server
that hosts your WebAssembly executable and a corresponding JavaScript entrypoint that loads it. The
app, reachable at [http://127.0.0.1:8080/](http://127.0.0.1:8080/), will automatically open in your
default web browser. The port that the development server uses can also be controlled with the
`--port` option (or `-p` for short). You can edit the app source code in your favorite editor and
save it, `carton` will immediately rebuild the app and reload all browser tabs that have the app
open. You can also pass a `--verbose` flag to keep the build process output available, otherwise
stale output is cleaned up from your terminal screen by default. If you have a custom `index.html`
page you'd like to use when serving, pass a path to it with a `--custom-index-page` option.

The `carton test` command runs your test suite in [`wasmer`](https://wasmer.io/), [`node`](https://nodejs.org/en/)
or using your default browser. You can switch between these with the `--environment` option, passing
either: `wasmer`, `node` or `defaultBrowser`. Code that depends on
[JavaScriptKit](https://github.com/swiftwasm/JavaScriptKit) should pass either `--environment node` or
`--environment defaultBrowser` options, depending on whether it needs Web APIs to work. Otherwise
the test run will not succeed, since JavaScript environment is not available with `--environment wasmer`.
If you want to run your test suite on CI or without GUI but on browser, you can pass `--headless` flag.
It enables [WebDriver](https://w3c.github.io/webdriver/)-based headless browser testing. Note that you
need to install a WebDriver executable in `PATH` before running tests.
You can use the command with a prebuilt test bundle binary instead of building it in carton by passing
`--prebuilt-test-bundle-path <your binary path>`.

The `carton sdk` command and its subcommands allow you to manage installed SwiftWasm toolchains, but
is rarely needed, as `carton dev` installs the recommended version of SwiftWasm automatically.
`carton sdk versions` lists all installed versions, and `carton sdk local` prints the version
specified for the current project in the `.swift-version` file. You can however install SwiftWasm
separately if needed, either by passing an archive URL to `carton sdk install` directly, or just
specifying the snapshot version, like `carton sdk install wasm-5.3-SNAPSHOT-2020-09-25-a`.

`carton dev` can also detect existing installations of `swiftenv`, so if you already have SwiftWasm
installed via `swiftenv`, you don't have to do anything on top of that to start using `carton`.

The `carton bundle` command builds your project using the `release` configuration (although you can
pass the `--debug` flag to it to change that), and copies all required assets to the `Bundle`
directory. You can then use a static file hosting (e.g. [GitHub Pages](https://pages.github.com/))
or any other server with support for static files to deploy your application. All resulting bundle
files except `index.html` are named by their content hashes to enable [cache
busting](https://www.keycdn.com/support/what-is-cache-busting). As with `carton dev`, a custom
`index.html` page can be provided through the `--custom-index-page` option. You can also pass
`--debug-info` flag to preserve `names` and DWARF sections in the resulting `.wasm` file, as these
are stripped in the `release` configuration by default. By default, `carton bundle` will run `wasm-opt`
on the resulting .wasm binary in order to reduce its file size. That behaviour can be disabled (in order
to speed up the build) by appending the `--wasm-optimizations none` option.

The `carton package` command proxies its subcommands to `swift package` invocations on the
currently-installed toolchain. This may be useful in situations where you'd like to generate an
Xcode project file for your app with something like `carton package generate-xcodeproj`. It would be
equivalent to `swift package generate-xcodeproj`, but invoked with the SwiftWasm toolchain instead
of the toolchain supplied by Xcode.

All commands that delegate to `swift build` and `swiftc` (namely, `dev`, `test`, and `bundle`)
can be passed `-Xswiftc` arguments, which is equivalent to `-Xswiftc` in `swift build`. All
`-Xswiftc` arguments are propagated to `swiftc` itself unmodified.

All of these commands and subcommands can be passed a `--help` flag that prints usage info and
information about all available options.

## How does it work?

`carton` bundles a [WASI](https://wasi.dev) polyfill, which is currently required to run any SwiftWasm code,
and the [JavaScriptKit](https://github.com/kateinoigakukun/JavaScriptKit/) runtime for convenience.
`carton` also embeds an HTTP server for previewing your SwiftWasm app directly in a browser.
The development version of the polyfill establishes a helper WebSocket connection to the server, so that
it can reload development browser tabs when rebuilt binary is available. This brings the development
experience closer to Xcode live previews, which you may have previously used when developing SwiftUI apps.

`carton` does not require any config files for these basic development scenarios, while some configuration
may be supported in the future, for example for complex asset pipelines if needed. The only requirement
is that your `Package.swift` contains at least a single executable product, which then will be compiled
for WebAssembly and served when you start `carton dev` in the directory where `Package.swift` is located.

`carton` is built with [Vapor](https://vapor.codes/), [SwiftNIO](https://github.com/apple/swift-nio),
[swift-tools-support-core](https://github.com/apple/swift-tools-support-core), and supports both
macOS and Linux. (Many thanks to everyone supporting and maintaining those projects!)

### Running `carton dev` with the `release` configuration

By default `carton dev` will compile in the `debug` configuration. Add the `--release` flag to compile in the `release` configuration.

## Contributing

### Sponsorship

If this tool saved you any amount of time or money, please consider [sponsoring
the SwiftWasm organization](https://github.com/sponsors/swiftwasm). Or you can sponsor some of our
maintainers directly on their personal sponsorship pages:
[@carson-katri](https://github.com/sponsors/carson-katri),
[@kateinoigakukun](https://github.com/sponsors/kateinoigakukun), and
[@MaxDesiatov](https://github.com/sponsors/MaxDesiatov). While some of the
sponsorship tiers give you priority support or even consulting time, any amount is
appreciated and helps in maintaining the project.

[Become a gold or platinum sponsor](https://github.com/sponsors/swiftwasm/) and contact maintainers to add your logo on our README on Github with a link to your site.

<a href="https://www.emergetools.com/">
  <img src="https://github.com/swiftwasm/swift/assets/11702759/6cb83079-f3e0-4749-b40d-a684fae160ad" width="30%">
</a>

### Coding Style

This project uses [SwiftFormat](https://github.com/nicklockwood/SwiftFormat)
and [SwiftLint](https://github.com/realm/SwiftLint) to
enforce formatting and coding style. We encourage you to run SwiftFormat within
a local clone of the repository in whatever way works best for you either
manually or automatically via an [Xcode
extension](https://github.com/nicklockwood/SwiftFormat#xcode-source-editor-extension),
[build phase](https://github.com/nicklockwood/SwiftFormat#xcode-build-phase) or
[git pre-commit
hook](https://github.com/nicklockwood/SwiftFormat#git-pre-commit-hook) etc.

To guarantee that these tools run before you commit your changes on macOS, you're encouraged
to run this once to set up the [pre-commit](https://pre-commit.com/) hook:

```
brew bundle # installs SwiftLint, SwiftFormat and pre-commit
pre-commit install # installs pre-commit hook to run checks before you commit
```

Refer to [the pre-commit documentation page](https://pre-commit.com/) for more details
and installation instructions for other platforms.

SwiftFormat and SwiftLint also run on CI for every PR and thus a CI build can
fail with incosistent formatting or style. We require CI builds to pass for all
PRs before merging.

### Code of Conduct

This project adheres to the [Contributor Covenant Code of
Conduct](https://github.com/swiftwasm/.github/blob/main/CODE_OF_CONDUCT.md).
By participating, you are expected to uphold this code. Please report
unacceptable behavior to hello@swiftwasm.org.
