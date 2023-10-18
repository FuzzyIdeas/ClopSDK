import Cocoa
import Foundation

@objcMembers
public class OptimisationResponseObjC: NSObject {
    public init(path: String, forURL: URL) {
        self.path = path
        self.forURL = forURL
    }

    public let path: String
    public let forURL: URL
    public var convertedFrom: String? = nil

    public var oldBytes = 0
    public var newBytes = 0

    public var oldWidthHeight: CGSize? = nil
    public var newWidthHeight: CGSize? = nil

    public var id: String { path }
}

public struct OptimisationResponse: Codable, Identifiable {
    public let path: String
    public let forURL: URL
    public var convertedFrom: String? = nil

    public var oldBytes = 0
    public var newBytes = 0

    public var oldWidthHeight: CGSize? = nil
    public var newWidthHeight: CGSize? = nil

    public var id: String { path }

    var objc: OptimisationResponseObjC {
        let resp = OptimisationResponseObjC(path: path, forURL: forURL)
        resp.convertedFrom = convertedFrom
        resp.oldBytes = oldBytes
        resp.newBytes = newBytes
        resp.oldWidthHeight = oldWidthHeight
        resp.newWidthHeight = newWidthHeight
        return resp
    }
}

public struct StopOptimisationRequest: Codable {
    public let ids: [String]
    public let remove: Bool
}

public struct OptimisationRequest: Codable, Identifiable {
    public let id: String
    public let urls: [URL]
    public var originalUrls: [URL: URL] = [:] // [tempURL: originalURL]
    public let size: CropSize?
    public let downscaleFactor: Double?
    public let changePlaybackSpeedFactor: Double?
    public let hideFloatingResult: Bool
    public let copyToClipboard: Bool
    public let aggressiveOptimisation: Bool
    public let source: String
    public var output: String?
}

public func runningClopApp() -> NSRunningApplication? {
    NSRunningApplication.runningApplications(withBundleIdentifier: "com.lowtechguys.Clop").first
}

public func isClopRunning() -> Bool {
    runningClopApp() != nil
}

public func isClopRunningAndListening() -> Bool {
    runningClopApp() != nil && ClopSDK.OPTIMISATION_PORT.isValidForSending
}

func printerr(_ msg: String, terminator: String = "\n") {
    fputs("\(msg)\(terminator)", stderr)
}
