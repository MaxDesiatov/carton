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

import CustomPathTarget
import Foundation
import JavaScriptKit
import TestLibrary

let document = JSObjectRef.global.document.object!

let button = document.createElement!("button").object!
button.innerText = .string("Crash!")
let body = document.body.object!
_ = body.appendChild!(button)

print("Number of seconds since epoch: \(Date().timeIntervalSince1970)")
print(customTargetText)

func crash() {
  let x = [Any]()
  print(x[1])
}

let buttonNode = document.getElementsByTagName!("button").object![0].object!
buttonNode.onclick = .function { _ in
  print(text)
  crash()
  return .undefined
}

let div = document.createElement!("div").object!
div.innerHTML = .string(#"""
<a href=\#(Bundle.module.path(forResource: "data", ofType: "json")!)>Link to a static resource</a>
"""#)
_ = body.appendChild!(div)
