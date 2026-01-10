import UIKit
import UniformTypeIdentifiers

enum CasaPasteboard {
    @MainActor
    static func copy(_ value: String) {
        let item = [UTType.plainText.identifier: value]
        UIPasteboard.general.setItems([item], options: [:])
        UIPasteboard.general.string = value
    }
}
