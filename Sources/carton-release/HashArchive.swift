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
import TSCBasic

struct HashArchive: ParsableCommand {
  /** Converts a hexadecimal hash string to Swift code that represents a static
   */
  private func arrayString(from hash: String) -> String {
    precondition(hash.count == 64)

    let commaSeparated = stride(from: 0, to: hash.count, by: 2)
      .map { hash.dropLast(hash.count - $0 - 2).suffix(2) }
      .map { "0x\($0)" }
      .joined(separator: ", ")

    precondition(commaSeparated.count == 190)

    return """
      \(commaSeparated.prefix(95))
      \(commaSeparated.suffix(94))
    """
  }

  func run() throws {
    let terminal = InteractiveWriter.stdout
    let cwd = localFileSystem.currentWorkingDirectory!

    try ProcessRunner(["npm", "run", "build"], terminal).waitUntilFinished()
    try ProcessRunner(["npm", "run", "bundle"], terminal).waitUntilFinished()

    let staticPath = AbsolutePath(cwd, "static")

    let devHash = try SHA256().hash(
      localFileSystem.readFileContents(AbsolutePath(staticPath, "dev.js"))
    ).hexadecimalRepresentation.uppercased()

    let bundleHash = try SHA256().hash(
      localFileSystem.readFileContents(AbsolutePath(staticPath, "bundle.js"))
    ).hexadecimalRepresentation.uppercased()

    let archiveSources = try localFileSystem.traverseRecursively(staticPath)
      // `traverseRecursively` also returns the `staticPath` directory itself, dropping it here
      .dropFirst()
      .map(\.pathString)

    try ProcessRunner(["zip", "-j", "static.zip"] + archiveSources, terminal).waitUntilFinished()

    let archiveHash = try SHA256().hash(
      localFileSystem.readFileContents(AbsolutePath(
        localFileSystem.currentWorkingDirectory!,
        RelativePath("static.zip")
      ))
    ).hexadecimalRepresentation.uppercased()

    let hashes = """
    import TSCBasic

    let devDependencySHA256 = ByteString([
    \(arrayString(from: devHash))
    ])

    let bundleDependencySHA256 = ByteString([
    \(arrayString(from: bundleHash))
    ])

    let staticArchiveHash = ByteString([
    \(arrayString(from: archiveHash)),
    ])

    """

    try localFileSystem.writeFileContents(
      AbsolutePath(cwd, RelativePath("Sources/carton/Server/StaticArchive.swift")),
      bytes: ByteString(encodingAsUTF8: hashes)
    )
  }
}
