import Foundation
import Sparkle

class SparkleUpdater: NSObject, SPUUpdaterDelegate {
    private var updaterController: SPUStandardUpdaterController?

    override init() {
        super.init()

        updaterController = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: self,
            userDriverDelegate: nil
        )
    }

    func checkForUpdates() {
        updaterController?.checkForUpdates(nil)
    }
    
    func checkForUpdatesInBackground() {
        updaterController?.updater.checkForUpdatesInBackground()
    }

    func feedURLString(for updater: SPUUpdater) -> String? {
        return "https://hyperlink.colddev.dev/updates/appcast.xml"
    }
}
