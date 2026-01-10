import Foundation

#if canImport(Sparkle)
import Sparkle

@MainActor
final class SparkleUpdater: NSObject, ObservableObject {
    private let controller: SPUStandardUpdaterController

    override init() {
        controller = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)
        super.init()
    }

    func checkForUpdates() {
        controller.checkForUpdates(nil)
    }
}
#endif
