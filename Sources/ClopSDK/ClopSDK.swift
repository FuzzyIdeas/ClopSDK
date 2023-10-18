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
        output: String? = nil
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
            output: output
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
        output: String? = nil
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
            output: output
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
        output: String? = nil
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
            output: output
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
        output: String? = nil
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
            output: output
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
        output: String? = nil
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
            output: output
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
        output: String? = nil
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
            output: output
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
        output: String? = nil
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
            output: output
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
        output: String? = nil
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
            output: output
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
        output: String? = nil
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
            output: output
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
        output: String? = nil
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
            output: output
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
