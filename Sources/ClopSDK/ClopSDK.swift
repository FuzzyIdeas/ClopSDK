import Cocoa
import Foundation
import System

public class ClopSDK {
    public static let shared = ClopSDK()

    @available(macOS 12.0, iOS 14.0, watchOS 7.0, tvOS 14.0, *)
    public func optimise(
        path: FilePath,
        aggressive: Bool = false,
        downscaleTo downscaleFactor: Double? = nil,
        cropTo cropSize: CropSize? = nil,
        changePlaybackSpeedBy playbackSpeedFactor: Double? = nil,
        hideGUI: Bool = false,
        copyToClipboard: Bool = false,
        inTheBackground: Bool = false,
        output: String? = nil,
        removeAudio: Bool? = nil
    ) throws -> OptimisationResponse {
        try optimise(
            url: path.url,
            aggressive: aggressive,
            downscaleTo: downscaleFactor,
            cropTo: cropSize,
            changePlaybackSpeedBy: playbackSpeedFactor,
            hideGUI: hideGUI,
            copyToClipboard: copyToClipboard,
            inTheBackground: inTheBackground,
            output: output,
            removeAudio: removeAudio
        )
    }

    @available(macOS 12.0, iOS 14.0, watchOS 7.0, tvOS 14.0, *)
    public func optimise(
        paths: [FilePath],
        aggressive: Bool = false,
        downscaleTo downscaleFactor: Double? = nil,
        cropTo cropSize: CropSize? = nil,
        changePlaybackSpeedBy playbackSpeedFactor: Double? = nil,
        hideGUI: Bool = false,
        copyToClipboard: Bool = false,
        inTheBackground: Bool = false,
        output: String? = nil,
        removeAudio: Bool? = nil
    ) throws -> [OptimisationResponse] {
        try optimise(
            urls: paths.map(\.url),
            aggressive: aggressive,
            downscaleTo: downscaleFactor,
            cropTo: cropSize,
            changePlaybackSpeedBy: playbackSpeedFactor,
            hideGUI: hideGUI,
            copyToClipboard: copyToClipboard,
            inTheBackground: inTheBackground,
            output: output,
            removeAudio: removeAudio
        )
    }

    public func optimise(
        path: String,
        aggressive: Bool = false,
        downscaleTo downscaleFactor: Double? = nil,
        cropTo cropSize: CropSize? = nil,
        changePlaybackSpeedBy playbackSpeedFactor: Double? = nil,
        hideGUI: Bool = false,
        copyToClipboard: Bool = false,
        inTheBackground: Bool = false,
        output: String? = nil,
        removeAudio: Bool? = nil
    ) throws -> OptimisationResponse {
        try optimise(
            url: path.url,
            aggressive: aggressive,
            downscaleTo: downscaleFactor,
            cropTo: cropSize,
            changePlaybackSpeedBy: playbackSpeedFactor,
            hideGUI: hideGUI,
            copyToClipboard: copyToClipboard,
            inTheBackground: inTheBackground,
            output: output,
            removeAudio: removeAudio
        )
    }

    public func optimise(
        paths: [String],
        aggressive: Bool = false,
        downscaleTo downscaleFactor: Double? = nil,
        cropTo cropSize: CropSize? = nil,
        changePlaybackSpeedBy playbackSpeedFactor: Double? = nil,
        hideGUI: Bool = false,
        copyToClipboard: Bool = false,
        inTheBackground: Bool = false,
        output: String? = nil,
        removeAudio: Bool? = nil
    ) throws -> [OptimisationResponse] {
        try optimise(
            urls: paths.map(\.url),
            aggressive: aggressive,
            downscaleTo: downscaleFactor,
            cropTo: cropSize,
            changePlaybackSpeedBy: playbackSpeedFactor,
            hideGUI: hideGUI,
            copyToClipboard: copyToClipboard,
            inTheBackground: inTheBackground,
            output: output,
            removeAudio: removeAudio
        )
    }

    public func optimise(
        url: URL,
        aggressive: Bool = false,
        downscaleTo downscaleFactor: Double? = nil,
        cropTo cropSize: CropSize? = nil,
        changePlaybackSpeedBy playbackSpeedFactor: Double? = nil,
        hideGUI: Bool = false,
        copyToClipboard: Bool = false,
        inTheBackground: Bool = false,
        output: String? = nil,
        removeAudio: Bool? = nil
    ) throws -> OptimisationResponse {
        let responses = try optimise(
            urls: [url],
            aggressive: aggressive,
            downscaleTo: downscaleFactor,
            cropTo: cropSize,
            changePlaybackSpeedBy: playbackSpeedFactor,
            hideGUI: hideGUI,
            copyToClipboard: copyToClipboard,
            inTheBackground: inTheBackground,
            output: output,
            removeAudio: removeAudio
        )
        return responses[0]
    }

    public func optimise(
        urls: [URL],
        aggressive: Bool = false,
        downscaleTo downscaleFactor: Double? = nil,
        cropTo cropSize: CropSize? = nil,
        changePlaybackSpeedBy playbackSpeedFactor: Double? = nil,
        hideGUI: Bool = false,
        copyToClipboard: Bool = false,
        inTheBackground: Bool = false,
        output: String? = nil,
        removeAudio: Bool? = nil
    ) throws -> [OptimisationResponse] {
        currentRequestIDs = urls.map(\.absoluteString)
        let req = OptimisationRequest(
            id: UUID().uuidString,
            urls: urls,
            size: cropSize,
            downscaleFactor: downscaleFactor,
            changePlaybackSpeedFactor: playbackSpeedFactor,
            hideFloatingResult: hideGUI,
            copyToClipboard: copyToClipboard,
            aggressiveOptimisation: aggressive,
            source: "sdk",
            output: output,
            removeAudio: removeAudio
        )

        guard !inTheBackground else {
            try Self.OPTIMISATION_PORT.sendAndForget(data: req.jsonData)
            return []
        }

        let respData = try Self.OPTIMISATION_PORT.sendAndWait(data: req.jsonData)
        guard let respData, let responses = [OptimisationResponse].from(respData), !responses.isEmpty else {
            throw "Optimisation failed".err
        }

        return responses
    }

    public func stopOptimisations() {
        guard !currentRequestIDs.isEmpty else {
            return
        }

        let req = StopOptimisationRequest(ids: currentRequestIDs, remove: false)
        try? Self.OPTIMISATION_STOP_PORT.sendAndForget(data: req.jsonData)
    }

    public func waitForClopToBeAvailable(for seconds: TimeInterval = 5.0) -> Bool {
        ensureClopIsRunning()

        var waitForClop = seconds
        while !isClopRunningAndListening(), waitForClop > 0 {
            Thread.sleep(forTimeInterval: 0.1)
            waitForClop -= 0.1
        }
        return isClopRunningAndListening()
    }

    public func getClopAppURL() -> URL? {
        if let clopAppURL {
            return clopAppURL
        }

        if isClopRunning(), let app = runningClopApp() {
            clopAppURL = app.bundleURL
            clopAppIdentifier = app.bundleIdentifier ?? "com.lowtechguys.Clop"
            return clopAppURL
        }

        if FileManager.default.fileExists(atPath: "/Applications/Setapp/Clop.app") {
            clopAppURL = URL(fileURLWithPath: "/Applications/Setapp/Clop.app")
            return clopAppURL
        }

        if FileManager.default.fileExists(atPath: "/Applications/Clop.app") {
            clopAppURL = URL(fileURLWithPath: "/Applications/Clop.app")
            return clopAppURL
        }

        let sema = DispatchSemaphore(value: 0)
        clopAppQuery = findClopApp { url in
            guard let url else {
                sema.signal()
                return
            }
            DispatchQueue.main.async {
                clopAppURL = url
                sema.signal()
            }
        }
        _ = sema.wait(timeout: .now() + 3)
        return clopAppURL
    }

    public func ensureClopIsRunning(completion: ((Bool) -> Void)? = nil) {
        listenForRunningClopApp()
        DispatchQueue.main.async { [weak self] in
            guard let clopAppURL else {
                if isClopRunning(), let app = runningClopApp() {
                    clopAppURL = app.bundleURL
                    clopAppIdentifier = app.bundleIdentifier ?? "com.lowtechguys.Clop"
                    return
                }

                if FileManager.default.fileExists(atPath: "/Applications/Setapp/Clop.app") {
                    clopAppURL = URL(fileURLWithPath: "/Applications/Setapp/Clop.app")
                    self?.ensureClopIsRunning(completion: completion)
                    return
                }

                if FileManager.default.fileExists(atPath: "/Applications/Clop.app") {
                    clopAppURL = URL(fileURLWithPath: "/Applications/Clop.app")
                    self?.ensureClopIsRunning(completion: completion)
                    return
                }

                self?.clopAppQuery = findClopApp { [weak self] url in
                    guard let url else { return }

                    DispatchQueue.main.async { [weak self] in
                        clopAppURL = url
                        self?.ensureClopIsRunning(completion: completion)
                    }
                }
                return
            }

            guard !isClopRunning() else { return }
            NSWorkspace.shared.open(clopAppURL)

            guard let completion else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                completion(isClopRunning())
            }
        }
    }

    static var OPTIMISATION_PORT = LocalMachPort(portLocation: "\(clopAppIdentifier).optimisationService")
    static var OPTIMISATION_STOP_PORT = LocalMachPort(portLocation: "\(clopAppIdentifier).optimisationServiceStop")

    private var currentRequestIDs: [String] = []
    private var clopAppQuery: MetaQuery?
    private var runningAppListener: NSObjectProtocol?

    private func listenForRunningClopApp() {
        guard runningAppListener == nil else { return }

        let center = NSWorkspace.shared.notificationCenter
        runningAppListener = center.addObserver(forName: NSWorkspace.didLaunchApplicationNotification, object: nil, queue: OperationQueue.main) { (notification: Notification) in
            guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
                  let id = app.bundleIdentifier, id.starts(with: "com.lowtechguys.Clop"), let url = app.bundleURL
            else {
                return
            }
            DispatchQueue.main.async {
                clopAppIdentifier = id
                clopAppURL = url
                ClopSDK.OPTIMISATION_PORT = LocalMachPort(portLocation: "\(clopAppIdentifier).optimisationService")
                ClopSDK.OPTIMISATION_STOP_PORT = LocalMachPort(portLocation: "\(clopAppIdentifier).optimisationServiceStop")
            }
        }
    }

}

var clopAppURL: URL? = runningClopApp()?.bundleURL
var clopAppIdentifier: String = runningClopApp()?.bundleIdentifier ?? "com.lowtechguys.Clop"

@objcMembers
public class ClopSDKObjC: NSObject {
    public static let shared = ClopSDKObjC()

    public func optimise(path: String) throws -> OptimisationResponseObjC {
        let resp = try ClopSDK.shared.optimise(path: path)
        return resp.objc
    }

    public func optimise(paths: [String]) throws -> [OptimisationResponseObjC] {
        let resp = try ClopSDK.shared.optimise(paths: paths)
        return resp.map(\.objc)
    }

    public func optimise(url: URL) throws -> OptimisationResponseObjC {
        let resp = try ClopSDK.shared.optimise(url: url)
        return resp.objc
    }

    public func optimise(urls: [URL]) throws -> [OptimisationResponseObjC] {
        let resp = try ClopSDK.shared.optimise(urls: urls)
        return resp.map(\.objc)
    }

    public func optimise(path: String, output: String? = nil) throws -> OptimisationResponseObjC {
        let resp = try ClopSDK.shared.optimise(path: path, output: output)
        return resp.objc
    }

    public func optimise(paths: [String], output: String? = nil) throws -> [OptimisationResponseObjC] {
        let resp = try ClopSDK.shared.optimise(paths: paths, output: output)
        return resp.map(\.objc)
    }

    public func optimise(url: URL, output: String? = nil) throws -> OptimisationResponseObjC {
        let resp = try ClopSDK.shared.optimise(url: url, output: output)
        return resp.objc
    }

    public func optimise(urls: [URL], output: String? = nil) throws -> [OptimisationResponseObjC] {
        let resp = try ClopSDK.shared.optimise(urls: urls, output: output)
        return resp.map(\.objc)
    }

    public func optimise(
        path: String,
        aggressive: Bool = false,
        downscaleTo downscaleFactor: Double,
        cropTo cropSize: CropSizeObjC? = nil,
        changePlaybackSpeedBy playbackSpeedFactor: Double,
        hideGUI: Bool = false,
        copyToClipboard: Bool = false,
        inTheBackground: Bool = false,
        output: String? = nil,
        removeAudio: Bool? = nil
    ) throws -> OptimisationResponseObjC {
        let resp = try ClopSDK.shared.optimise(
            url: path.url,
            aggressive: aggressive,
            downscaleTo: downscaleFactor == -1 ? nil : downscaleFactor,
            cropTo: CropSize(cropSize),
            changePlaybackSpeedBy: playbackSpeedFactor == -1 ? nil : playbackSpeedFactor,
            hideGUI: hideGUI,
            copyToClipboard: copyToClipboard,
            inTheBackground: inTheBackground,
            output: output,
            removeAudio: removeAudio
        )
        return resp.objc
    }

    public func optimise(
        paths: [String],
        aggressive: Bool = false,
        downscaleTo downscaleFactor: Double,
        cropTo cropSize: CropSizeObjC? = nil,
        changePlaybackSpeedBy playbackSpeedFactor: Double,
        hideGUI: Bool = false,
        copyToClipboard: Bool = false,
        inTheBackground: Bool = false,
        output: String? = nil,
        removeAudio: Bool? = nil
    ) throws -> [OptimisationResponseObjC] {
        let resp = try ClopSDK.shared.optimise(
            urls: paths.map(\.url),
            aggressive: aggressive,
            downscaleTo: downscaleFactor == -1 ? nil : downscaleFactor,
            cropTo: CropSize(cropSize),
            changePlaybackSpeedBy: playbackSpeedFactor == -1 ? nil : playbackSpeedFactor,
            hideGUI: hideGUI,
            copyToClipboard: copyToClipboard,
            inTheBackground: inTheBackground,
            output: output,
            removeAudio: removeAudio
        )
        return resp.map(\.objc)
    }

    public func optimise(
        url: URL,
        aggressive: Bool = false,
        downscaleTo downscaleFactor: Double,
        cropTo cropSize: CropSizeObjC? = nil,
        changePlaybackSpeedBy playbackSpeedFactor: Double,
        hideGUI: Bool = false,
        copyToClipboard: Bool = false,
        inTheBackground: Bool = false,
        output: String? = nil,
        removeAudio: Bool? = nil
    ) throws -> OptimisationResponseObjC {
        let responses = try ClopSDK.shared.optimise(
            urls: [url],
            aggressive: aggressive,
            downscaleTo: downscaleFactor == -1 ? nil : downscaleFactor,
            cropTo: CropSize(cropSize),
            changePlaybackSpeedBy: playbackSpeedFactor == -1 ? nil : playbackSpeedFactor,
            hideGUI: hideGUI,
            copyToClipboard: copyToClipboard,
            inTheBackground: inTheBackground,
            output: output,
            removeAudio: removeAudio
        )
        return responses[0].objc
    }

    public func optimise(
        urls: [URL],
        aggressive: Bool = false,
        downscaleTo downscaleFactor: Double = -1,
        cropTo cropSize: CropSizeObjC? = nil,
        changePlaybackSpeedBy playbackSpeedFactor: Double = -1,
        hideGUI: Bool = false,
        copyToClipboard: Bool = false,
        inTheBackground: Bool = false,
        output: String? = nil,
        removeAudio: Bool? = nil
    ) throws -> [OptimisationResponseObjC] {
        let resp = try ClopSDK.shared.optimise(
            urls: urls,
            aggressive: aggressive,
            downscaleTo: downscaleFactor == -1 ? nil : downscaleFactor,
            cropTo: CropSize(cropSize),
            changePlaybackSpeedBy: playbackSpeedFactor == -1 ? nil : playbackSpeedFactor,
            hideGUI: hideGUI,
            copyToClipboard: copyToClipboard,
            inTheBackground: inTheBackground,
            output: output,
            removeAudio: removeAudio
        )
        return resp.map(\.objc)
    }

    public func waitForClopToBeAvailable(for seconds: TimeInterval = 5.0) -> Bool {
        ClopSDK.shared.waitForClopToBeAvailable(for: seconds)
    }

    public func ensureClopIsRunning(completion: ((Bool) -> Void)? = nil) {
        ClopSDK.shared.ensureClopIsRunning(completion: completion)
    }

    public func stopOptimisations() {
        ClopSDK.shared.stopOptimisations()
    }
}
