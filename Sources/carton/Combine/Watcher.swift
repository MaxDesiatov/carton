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

#if canImport(Combine)
import Combine
#else
import OpenCombine
#endif
import TSCBasic
import TSCUtility

final class Watcher {
  private let subject = PassthroughSubject<[AbsolutePath], Never>()
  private var fsWatch: FSWatch!
  let publisher: AnyPublisher<[AbsolutePath], Never>

  init(_ paths: [AbsolutePath]) throws {
    publisher = subject.eraseToAnyPublisher()

    fsWatch = FSWatch(paths: paths, latency: 0.1) { [weak self] in
      self?.subject.send($0)
    }
    try fsWatch.start()
  }
}
