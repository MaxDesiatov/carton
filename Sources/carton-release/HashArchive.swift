// Copyright 2020 Carton contributors
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import ArgumentParser
import CartonHelpers
import Foundation
import WasmTransformer

struct HashArchive: AsyncParsableCommand {
  /** Converts a hexadecimal hash string to Swift code that represents an archive of static assets.
   */
  private func arrayString(from hash: String) -> String {
    precondition(hash.count == 64)

    let commaSeparated = stride(from: 0, to: hash.count, by: 2)
      .map { "0x\(hash.dropLast(hash.count - $0 - 2).suffix(2))" }
      .joined(separator: ", ")

    precondition(commaSeparated.count == 190)

    return """
        \(commaSeparated.prefix(95))
        \(commaSeparated.suffix(94))
      """
  }

  func run() async throws {
    let terminal = InteractiveWriter.stdout
    let cwd = localFileSystem.currentWorkingDirectory!
    let staticPath = try AbsolutePath(validating: "static", relativeTo: cwd)
    let dotFilesStaticPath = try localFileSystem.homeDirectory.appending(
      components: ".carton",
      "static"
    )

    try localFileSystem.createDirectory(dotFilesStaticPath, recursive: true)
    var hashes: [(String, String)] = []
    for entrypoint in ["dev", "bundle", "test", "testNode"] {
      let filename = "\(entrypoint).js"
      var arguments = [
        "esbuild", "--bundle", "entrypoint/\(filename)", "--outfile=static/\(filename)",
      ]

      if entrypoint == "testNode" {
        arguments.append(contentsOf: [
          "--format=cjs", "--platform=node",
          "--external:./JavaScriptKit_JavaScriptKit.resources/Runtime/index.js",
        ])
      } else {
        arguments.append(contentsOf: [
          "--format=esm",
          "--external:./JavaScriptKit_JavaScriptKit.resources/Runtime/index.mjs",
        ])
      }

      guard let npx = Process.findExecutable("npx") else {
        fatalError("\"npx\" command not found in PATH")
      }
      try Foundation.Process.run(npx.asURL, arguments: arguments).waitUntilExit()
      let entrypointPath = try AbsolutePath(validating: filename, relativeTo: staticPath)
      let dotFilesEntrypointPath = dotFilesStaticPath.appending(component: filename)
      try localFileSystem.removeFileTree(dotFilesEntrypointPath)
      try localFileSystem.copy(from: entrypointPath, to: dotFilesEntrypointPath)

      hashes.append(
        (
          entrypoint,
          try SHA256().hash(localFileSystem.readFileContents(entrypointPath))
            .hexadecimalRepresentation.uppercased()
        ))
    }

    try localFileSystem.writeFileContents(
      staticPath.appending(component: "so_sanitizer.wasm"),
      bytes: .init(StackOverflowSanitizer.supportObjectFile)
    )
    print("file written to \(staticPath.appending(component: "so_sanitizer.wasm"))")

    let archiveSources = try localFileSystem.getDirectoryContents(staticPath)
      .map { try AbsolutePath(validating: $0, relativeTo: staticPath) }
      .map(\.pathString)

    try await Process.run(["zip", "-j", "static.zip"] + archiveSources, terminal)

    let staticArchiveContents = try localFileSystem.readFileContents(
      AbsolutePath(
        validating: "static.zip",
        relativeTo: localFileSystem.currentWorkingDirectory!
      ))

    // Base64 is not an efficient way, but too long byte array literal breaks type-checker
    let hashesFileContent = """
      import CartonHelpers

      \(hashes.map {
      """
      public let \($0)EntrypointSHA256 = ByteString([
      \(arrayString(from: $1))
      ])
      """
      }.joined(separator: "\n\n"))

      public let staticArchiveContents = "\(staticArchiveContents.withData { $0.base64EncodedString() })"
      """

    try localFileSystem.writeFileContents(
      AbsolutePath(
        cwd,
        RelativePath(validating: "Sources").appending(
          components: "CartonKit", "Server", "StaticArchive.swift")
      ),
      bytes: ByteString(encodingAsUTF8: hashesFileContent)
    )
  }
}
