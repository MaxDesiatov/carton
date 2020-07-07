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

import AsyncHTTPClient
import Foundation
import TSCBasic
import TSCUtility

private let archiveHash = ByteString([
  0x1D, 0xCC, 0x1A, 0x8B, 0x89, 0x3C, 0xFD, 0xF6, 0x07, 0xF3, 0x9A, 0xBE, 0x22, 0xF1, 0xB7, 0x22,
  0x5B, 0x7B, 0x41, 0x86, 0x66, 0xDF, 0x98, 0x52, 0x2C, 0x7B, 0xE5, 0x54, 0x73, 0xD2, 0x3E, 0x8A,
])

private let archiveURL = "https://github.com/swiftwasm/carton/releases/download/0.3.0/static.zip"

private let verifyHash = Equality<ByteString, String> {
  """
  Expected SHA256 of \($2), which is
  \($0.hexadecimalRepresentation)
  to equal
  \($1.hexadecimalRepresentation)
  """
}

enum DependencyError: Error {
  case downloadFailed(url: String)
}

struct Dependency {
  let fileName: String
  let sha256: ByteString

  func check(on fileSystem: FileSystem, _ terminal: TerminalController) throws {
    let cartonDir = fileSystem.homeDirectory.appending(component: ".carton")
    let staticDir = cartonDir.appending(component: "static")
    let devPolyfill = cartonDir.appending(components: "static", fileName)

    // If dev.js hash fails, download the `static.zip` archive and unpack it/
    if try !fileSystem.exists(devPolyfill) || SHA256().hash(
      fileSystem.readFileContents(devPolyfill)
    ) != sha256 {
      terminal.logLookup("Directory doesn't exist or contains outdated polyfills: ", staticDir)
      try fileSystem.removeFileTree(cartonDir)

      let client = HTTPClient(eventLoopGroupProvider: .createNew)
      let request = try HTTPClient.Request.get(url: archiveURL)
      let response: HTTPClient.Response = try await {
        client.execute(request: request).whenComplete($0)
      }
      try client.syncShutdown()

      guard
        var body = response.body,
        let bytes = body.readBytes(length: body.readableBytes)
      else { throw DependencyError.downloadFailed(url: archiveURL) }

      terminal.logLookup("Polyfills archive successfully downloaded from ", archiveURL)

      let downloadedArchive = ByteString(bytes)

      let downloadedHash = SHA256().hash(downloadedArchive)
      try verifyHash(downloadedHash, archiveHash, context: archiveURL)

      let archiveFile = cartonDir.appending(component: "static.zip")
      try fileSystem.createDirectory(cartonDir, recursive: true)
      try fileSystem.writeFileContents(archiveFile, bytes: downloadedArchive)
      terminal.logLookup("Unpacking the archive: ", archiveFile)

      try await {
        ZipArchiver().extract(from: archiveFile, to: cartonDir, completion: $0)
      }
    }

    let unpackedPolyfillHash = try SHA256().hash(fileSystem.readFileContents(devPolyfill))
    // Nothing we can do after the hash doesn't match after unpacking
    try verifyHash(unpackedPolyfillHash, sha256, context: devPolyfill.pathString)
    terminal.logLookup("Polyfill integrity verified: ", devPolyfill)
  }
}
