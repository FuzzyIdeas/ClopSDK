import Cocoa
import Foundation
import System

extension Data {
    var s: String? {
        String(data: self, encoding: .utf8)
    }
}

extension String {
    var err: NSError {
        NSError(domain: self, code: 1)
    }
    var url: URL { URL(fileURLWithPath: self) }
}

extension Encodable {
    var jsonString: String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try! encoder.encode(self)
        return String(data: data, encoding: .utf8)!
    }
    var jsonData: Data {
        try! JSONEncoder().encode(self)
    }
}
extension Decodable {
    static func from(_ data: Data) -> Self? {
        try? JSONDecoder().decode(Self.self, from: data)
    }
}

extension NSSize {
    var aspectRatio: Double {
        width / height
    }
    func scaled(by factor: Double) -> CGSize {
        CGSize(width: (width * factor).evenInt, height: (height * factor).evenInt)
    }
}

extension Int {
    var s: String {
        String(self)
    }
    var d: Double {
        Double(self)
    }
}

extension Double {
    @inline(__always) @inlinable var intround: Int {
        rounded().i
    }

    @inline(__always) @inlinable var i: Int {
        Int(self)
    }

    var evenInt: Int {
        let x = intround
        return x + x % 2
    }
}

extension CGFloat {
    @inline(__always) @inlinable var intround: Int {
        rounded().i
    }

    @inline(__always) @inlinable var i: Int {
        Int(self)
    }

    var evenInt: Int {
        let x = intround
        return x + x % 2
    }
}

@available(macOS 12.0, iOS 14.0, watchOS 7.0, tvOS 14.0, *)
extension FilePath {
    var url: URL { URL(fileURLWithPath: string) }
}
