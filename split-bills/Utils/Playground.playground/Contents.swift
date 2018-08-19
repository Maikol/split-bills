import UIKit

struct Test {
    let id: String?
}

let test: Test? = Test(id: nil)
let other = test.flatMap { $0.id }
print(other ?? "QUE:")
