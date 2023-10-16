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
        inTheBackground: Bool = false
    ) throws -> OptimisationResponse {
        try optimise(
            url: path.url,
            aggressive: aggressive,
            downscaleTo: downscaleFactor,
            cropTo: cropSize,
            changePlaybackSpeedBy: playbackSpeedFactor,
            hideGUI: hideGUI,
            copyToClipboard: copyToClipboard,
            inTheBackground: inTheBackground
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
        inTheBackground: Bool = false
    ) throws -> [OptimisationResponse] {
        try optimise(
            urls: paths.map(\.url),
            aggressive: aggressive,
            downscaleTo: downscaleFactor,
            cropTo: cropSize,
            changePlaybackSpeedBy: playbackSpeedFactor,
            hideGUI: hideGUI,
            copyToClipboard: copyToClipboard,
            inTheBackground: inTheBackground
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
        inTheBackground: Bool = false
    ) throws -> OptimisationResponse {
        try optimise(
            url: path.url,
            aggressive: aggressive,
            downscaleTo: downscaleFactor,
            cropTo: cropSize,
            changePlaybackSpeedBy: playbackSpeedFactor,
            hideGUI: hideGUI,
            copyToClipboard: copyToClipboard,
            inTheBackground: inTheBackground
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
        inTheBackground: Bool = false
    ) throws -> [OptimisationResponse] {
        try optimise(
            urls: paths.map(\.url),
            aggressive: aggressive,
            downscaleTo: downscaleFactor,
            cropTo: cropSize,
            changePlaybackSpeedBy: playbackSpeedFactor,
            hideGUI: hideGUI,
            copyToClipboard: copyToClipboard,
            inTheBackground: inTheBackground
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
        inTheBackground: Bool = false
    ) throws -> OptimisationResponse {
        let responses = try optimise(
            urls: [url],
            aggressive: aggressive,
            downscaleTo: downscaleFactor,
            cropTo: cropSize,
            changePlaybackSpeedBy: playbackSpeedFactor,
            hideGUI: hideGUI,
            copyToClipboard: copyToClipboard,
            inTheBackground: inTheBackground
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
        inTheBackground: Bool = false
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
            source: "sdk"
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

    public func stopCurrentRequests() {
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

    public func ensureClopIsRunning(completion: ((Bool) -> Void)? = nil) {
        DispatchQueue.main.async { [weak self] in
            guard let clopAppURL else {
                if isClopRunning() {
                    clopAppURL = runningClopApp()?.bundleURL
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

    static let OPTIMISATION_PORT = LocalMachPort(portLocation: "com.lowtechguys.Clop.optimisationService")
    static let OPTIMISATION_STOP_PORT = LocalMachPort(portLocation: "com.lowtechguys.Clop.optimisationServiceStop")

    var currentRequestIDs: [String] = []
    var clopAppQuery: MetaQuery?

}

var clopAppURL = runningClopApp()?.bundleURL
