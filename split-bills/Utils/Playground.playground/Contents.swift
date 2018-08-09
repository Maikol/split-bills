import UIKit

let dict = ["One": 1.0, "Two": 2.0]
let dict2 = ["One": -0.5, "Two": 0.5, "Three": 3]

let res = dict.merging(dict2) { $0 + $1 }.sorted { $0.value > $1.value }

print(res)
