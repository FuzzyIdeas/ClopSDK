import Cocoa
import Foundation

@objcMembers
public class CropSizeObjC: NSObject {
    public init(width: Int, height: Int, name: String = "", longEdge: Bool = false) {
        self.width = width
        self.height = height
        self.name = name
        self.longEdge = longEdge
    }

    public let width: Int
    public let height: Int
    public var name = ""
    public var longEdge = false
}

public struct CropSize: Codable, Hashable, Identifiable {
    init?(_ cropSize: CropSizeObjC?) {
        guard let cropSize else { return nil }
        self.init(width: cropSize.width, height: cropSize.height, name: cropSize.name, longEdge: cropSize.longEdge)
    }

    public init(width: Int, height: Int, name: String = "", longEdge: Bool = false) {
        self.width = width
        self.height = height
        self.name = name
        self.longEdge = longEdge
    }

    public init(width: Double, height: Double, name: String = "", longEdge: Bool = false) {
        self.width = width.evenInt
        self.height = height.evenInt
        self.name = name
        self.longEdge = longEdge
    }

    public static let zero = CropSize(width: 0, height: 0)

    public let width: Int
    public let height: Int
    public var name = ""
    public var longEdge = false

    public var id: String { "\(width == 0 ? "Auto" : width.s)×\(height == 0 ? "Auto" : height.s)" }

    public var aspectRatio: Double { width.d / height.d }
    public var area: Int { (width == 0 ? height : width) * (height == 0 ? width : height) }
    public var ns: NSSize { NSSize(width: width, height: height) }
    public var cg: CGSize { CGSize(width: width, height: height) }
}

public extension NSSize {
    func cropSize(name: String = "", longEdge: Bool = false) -> CropSize {
        CropSize(width: width.evenInt, height: height.evenInt, name: name, longEdge: longEdge)
    }
}
