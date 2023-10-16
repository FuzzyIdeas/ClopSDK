import AVFoundation
@testable import ClopSDK
import PDFKit
import XCTest

let png = Bundle.module.path(forResource: "image", ofType: "png")!
let mp4 = Bundle.module.path(forResource: "video", ofType: "mp4")!
let mov = Bundle.module.path(forResource: "video", ofType: "mov")!
let pdf = Bundle.module.path(forResource: "book", ofType: "pdf")!

final class ClopSDKTests: XCTestCase {
    override func setUp() async throws {
        guard ClopSDK.shared.waitForClopToBeAvailable() else {
            throw "Clop is not running".err
        }
    }

    func testOptimiseOneImage() throws {
        let tmp = png.tmpURL
        let resp = try ClopSDK.shared.optimise(url: tmp)

        XCTAssertLessThan(resp.newBytes, resp.oldBytes, "New bytes should be less than old bytes")
        XCTAssertEqual(resp.forURL, tmp, "Response URL should match input URL")
    }

    func testOptimiseMultipleImages() throws {
        let tmp = png.tmpURL
        let tmp2 = png.tmpURL

        let resp = try ClopSDK.shared.optimise(urls: [tmp, tmp2])

        XCTAssertEqual(resp.count, 2, "Response count should match input count")
        XCTAssertTrue(resp.allSatisfy { $0.newBytes < $0.oldBytes }, "All new bytes should be less than old bytes")
        XCTAssertTrue(resp.allSatisfy { $0.forURL == tmp || $0.forURL == tmp2 }, "Response URLs should match input URLs")
    }

    func testOptimiseImageAndVideo() throws {
        let tmpImg = png.tmpURL
        let tmpVideo = mp4.tmpURL

        let resp = try ClopSDK.shared.optimise(urls: [tmpImg, tmpVideo])

        XCTAssertEqual(resp.count, 2, "Response count should match input count")
        XCTAssertTrue(resp.allSatisfy { $0.newBytes < $0.oldBytes }, "All new bytes should be less than old bytes")
        XCTAssertTrue(resp.contains { $0.forURL == tmpImg } && resp.contains { $0.forURL == tmpVideo }, "Response URLs should match input URLs")
    }

    func testCropImage() throws {
        let tmp = png.tmpURL
        let cropSize = CropSize(width: 100, height: 100)
        let resp = try ClopSDK.shared.optimise(url: tmp, cropTo: cropSize)

        XCTAssertLessThan(resp.newBytes, resp.oldBytes, "New bytes should be less than old bytes")
        XCTAssertEqual(resp.forURL, tmp, "Response URL should match input URL")
        XCTAssertEqual(resp.newWidthHeight, cropSize.cg, "New width and height should match crop size")

        let newPNGSize = NSImage(contentsOfFile: resp.path)!.size
        XCTAssertEqual(newPNGSize, cropSize.cg, "New PNG size should match crop size")
    }

    func testDownscaleImage() throws {
        let tmp = png.tmpURL
        let resp = try ClopSDK.shared.optimise(url: tmp, downscaleTo: 0.5)

        XCTAssertLessThan(resp.newBytes, resp.oldBytes, "New bytes should be less than old bytes")
        XCTAssertEqual(resp.forURL, tmp, "Response URL should match input URL")

        let pngSize = NSImage(contentsOfFile: png)!.size
        XCTAssertEqual(resp.newWidthHeight, pngSize.scaled(by: 0.5), "New width and height should match scaled size")

        let newPNGSize = NSImage(contentsOfFile: resp.path)!.size
        XCTAssertEqual(newPNGSize, pngSize.scaled(by: 0.5), "New PNG size should match scaled size")
    }

    func testChangePlaybackSpeed() async throws {
        let tmp = mp4.tmpURL
        let resp = try ClopSDK.shared.optimise(url: tmp, aggressive: true, changePlaybackSpeedBy: 2)

        XCTAssertLessThan(resp.newBytes, resp.oldBytes, "New bytes should be less than old bytes")
        XCTAssertEqual(resp.forURL, tmp, "Response URL should match input URL")

        let oldMetadata = try await getVideoMetadata(url: mp4.url)
        let newMetadata = try await getVideoMetadata(url: resp.path.url)
        XCTAssertEqual(newMetadata.duration!, oldMetadata.duration! / 2, accuracy: 0.1, "New video duration should be half of old video duration")
    }

    func testCropVideo() async throws {
        let tmp = mp4.tmpURL
        let cropSize = CropSize(width: 100, height: 100)
        let resp = try ClopSDK.shared.optimise(url: tmp, cropTo: cropSize)

        XCTAssertLessThan(resp.newBytes, resp.oldBytes, "New bytes should be less than old bytes")
        XCTAssertEqual(resp.forURL, tmp, "Response URL should match input URL")
        XCTAssertEqual(resp.newWidthHeight, cropSize.cg, "New width and height should match crop size")

        let newMetadata = try await getVideoMetadata(url: resp.path.url)
        XCTAssertEqual(newMetadata.resolution, cropSize.cg, "New video resolution should match crop size")
    }

    func testDownscaleVideo() async throws {
        let tmp = mp4.tmpURL
        let resp = try ClopSDK.shared.optimise(url: tmp, downscaleTo: 0.5)

        XCTAssertLessThan(resp.newBytes, resp.oldBytes, "New bytes should be less than old bytes")
        XCTAssertEqual(resp.forURL, tmp, "Response URL should match input URL")

        let oldMetadata = try await getVideoMetadata(url: mp4.url)
        let newMetadata = try await getVideoMetadata(url: resp.path.url)
        XCTAssertEqual(newMetadata.resolution, oldMetadata.resolution.scaled(by: 0.5), "New video resolution should match scaled size")
    }

    func testConvertMOVtoMP4() throws {
        let tmp = mov.tmpURL
        let resp = try ClopSDK.shared.optimise(url: tmp)

        XCTAssertGreaterThan(resp.newBytes, resp.oldBytes, "New bytes should be greater than old bytes")
        XCTAssertEqual(resp.forURL, tmp, "Response URL should match input URL")
        XCTAssertEqual(resp.convertedFrom, tmp.path, "Response should indicate conversion from MOV to MP4")
        XCTAssertEqual(resp.path.url.pathExtension, "mp4", "Response path should be an MP4")
    }

    func testOptimisePDF() throws {
        let tmp = pdf.tmpURL
        let resp = try ClopSDK.shared.optimise(url: tmp, aggressive: true)

        XCTAssertLessThan(resp.newBytes, resp.oldBytes, "New bytes should be less than old bytes")
        XCTAssertEqual(resp.forURL, tmp, "Response URL should match input URL")
    }

    func testCropPDF() throws {
        let tmp = pdf.tmpURL
        let cropSize = CropSize(width: 1640, height: 2360)
        let resp = try ClopSDK.shared.optimise(url: tmp, aggressive: true, cropTo: cropSize)

        XCTAssertLessThan(resp.newBytes, resp.oldBytes, "New bytes should be less than old bytes")
        XCTAssertEqual(resp.forURL, tmp, "Response URL should match input URL")

        let pdf = PDFDocument(url: resp.path.url)!
        let page = pdf.page(at: 0)!
        let pageRect = page.bounds(for: .cropBox)
        XCTAssertEqual(pageRect.size.aspectRatio, cropSize.aspectRatio, accuracy: 0.01, "New width and height should match crop size")
    }
}

struct VideoMetadata {
    let resolution: CGSize
    let fps: Float
    var duration: TimeInterval?
}

func getVideoMetadata(url: URL) async throws -> VideoMetadata {
    guard let track = try await AVURLAsset(url: url).loadTracks(withMediaType: .video).first else {
        throw "No video track found".err
    }
    var size = try await track.load(.naturalSize)
    if let transform = try? await track.load(.preferredTransform) {
        size = size.applying(transform)
    }
    let fps = try await track.load(.nominalFrameRate)
    let duration = try await track.load(.timeRange).duration
    return VideoMetadata(resolution: CGSize(width: abs(size.width), height: abs(size.height)), fps: fps, duration: duration.seconds)
}

extension String {
    var tmpURL: URL {
        let url = url
        let tmp = FileManager.default.temporaryDirectory.appending(component: "\(UUID().uuidString).\(url.pathExtension)")

        try? FileManager.default.removeItem(at: tmp)
        try? FileManager.default.copyItem(at: url, to: tmp)
        return tmp
    }
}
