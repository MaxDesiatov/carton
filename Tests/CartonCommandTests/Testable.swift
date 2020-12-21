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
//
//  Created by Cavelle Benjamin on Dec/20/20.
//

import Foundation
import TSCBasic

public protocol Testable {
  var productsDirectory: AbsolutePath { get }
  var testFixturesDirectory: AbsolutePath { get }
  var packageDirectory: AbsolutePath { get }
}

public extension Testable {
  /// Returns path to the built products directory.
  var productsDirectory: AbsolutePath {
    #if os(macOS)
    for bundle in Bundle.allBundles where bundle.bundlePath.hasSuffix(".xctest") {
      print(bundle.bundleURL.deletingLastPathComponent().path)
      return AbsolutePath(bundle.bundleURL.deletingLastPathComponent().path)
    }
    fatalError("couldn't find the products directory")
    #else
    return AbsolutePath(url: Bundle.main.bundleURL.absoluteString)
    #endif
  }

  var testFixturesDirectory: AbsolutePath {
    packageDirectory.appending(components: "Test", "Fixtures")
  }

  var packageDirectory: AbsolutePath {
    // necessary if you are using xcode
    if let _ = ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] {
      return productsDirectory
        .parentDirectory
        .parentDirectory
        .parentDirectory
        .parentDirectory
        .parentDirectory
    }

    return productsDirectory
      .parentDirectory
      .parentDirectory
      .parentDirectory
  }
}

extension AbsolutePath {
  func mkdir() throws {
    _ = try FileManager.default.createDirectory(
      atPath: pathString,
      withIntermediateDirectories: true
    )
  }

  func delete() throws {
    _ = try FileManager.default.removeItem(atPath: pathString)
  }

  var url: URL {
    URL(fileURLWithPath: pathString)
  }

  static var home: AbsolutePath {
    AbsolutePath(FileManager.default.homeDirectoryForCurrentUser.path)
  }
}
