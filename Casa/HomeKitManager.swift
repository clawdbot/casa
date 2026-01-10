import Foundation
import HomeKit

@MainActor
final class HomeKitManager: NSObject, ObservableObject {
    private let manager = HMHomeManager()
    private let logger: CasaLogger

    @Published private(set) var homes: [HMHome] = []
    @Published private(set) var accessories: [HMAccessory] = []

    init(logger: CasaLogger) {
        self.logger = logger
    }

    func start() {
        manager.delegate = self
        logger.log(level: "info", message: "homekit_start")
        refreshData()
    }

    func stop() {
        manager.delegate = nil
        homes = []
        accessories = []
        logger.log(level: "info", message: "homekit_stop")
    }

    func refreshData() {
        homes = manager.homes
        accessories = manager.homes.flatMap { $0.accessories }
        logger.log(level: "info", message: "homekit_refresh", metadata: [
            "homes": String(homes.count),
            "accessories": String(accessories.count)
        ])
    }

    func characteristic(with id: UUID) -> HMCharacteristic? {
        for home in manager.homes {
            for accessory in home.accessories {
                for service in accessory.services {
                    if let match = service.characteristics.first(where: { $0.uniqueIdentifier == id }) {
                        return match
                    }
                }
            }
        }
        return nil
    }

    func characteristic(with idString: String) -> HMCharacteristic? {
        guard let id = UUID(uuidString: idString) else { return nil }
        return characteristic(with: id)
    }
}

@MainActor
extension HomeKitManager: @preconcurrency HMHomeManagerDelegate {
    func homeManagerDidUpdateHomes(_ manager: HMHomeManager) {
        logger.log(level: "info", message: "homekit_homes_updated")
        refreshData()
    }

    func homeManager(_ manager: HMHomeManager, didUpdate status: HMHomeManagerAuthorizationStatus) {
        logger.log(level: "info", message: "homekit_auth_status", metadata: [
            "status": String(status.rawValue)
        ])
        refreshData()
    }
}
