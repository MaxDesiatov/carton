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

struct CartonRelease: ParsableCommand {
  static let configuration = CommandConfiguration(
    abstract: "Carton release automation utility",
    subcommands: [Formula.self, HashArchive.self]
  )
}

@main
struct Main: AsyncMain {
  typealias Command = CartonRelease
}