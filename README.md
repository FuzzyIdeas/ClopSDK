<p align="center">
    <a href="https://lowtechguys.com/clop"><img width="128" height="128" src="https://lowtechguys.com/static/img/clop-icon.webp" style="filter: drop-shadow(0px 2px 4px rgba(80, 50, 6, 0.2));"></a>
    <h1 align="center"><code style="text-shadow: 0px 3px 10px rgba(8, 0, 6, 0.35); font-size: 3rem; font-family: ui-monospace, Menlo, monospace; font-weight: 800; background: transparent; color: #4d3e56; padding: 0.2rem 0.2rem; border-radius: 6px">Clop SDK</code></h1>
    <h5 align="center" style="padding: 0; margin: 0; font-family: ui-monospace, monospace; font-weight: 400">Image, video, PDF and clipboard optimiser</h4>
    <h4 align="center" style="padding: 0; margin: 0; font-family: ui-monospace, monospace; font-weight: 700;">Software Development Kit</h6>
</p>


ClopSDK is a Swift Package that optimizes images, videos, and PDFs by sending them to the [Clop](https://lowtechguys.com/clop) macOS app.

## Installation
You can install ClopSDK using the Swift Package Manager. To add it to your Xcode project, go to File > Swift Packages > Add Package Dependency and enter the URL of this repository.

You can also add it to a standalone Swift package by adding it to your `Package.swift` file:

```swift
let package = Package(
    name: "MyPackage",
    dependencies: [
        .package(url: "https://github.com/FuzzyIdeas/ClopSDK.git", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "MyPackage",
            dependencies: ["ClopSDK"])
    ]
)
```

## Usage
To use ClopSDK, simply import it into your Swift file:

```swift
import ClopSDK
```

Then, you can use the `ClopSDK` class to send file paths to the Clop app:

```swift
// Optimise a single file
try ClopSDK.shared.optimise(path: "/path/to/image.jpg")

// Optimise multiple files
try ClopSDK.shared.optimise(paths: ["/path/to/image.jpg", "/path/to/video.mp4", "/path/to/document.pdf"])

// Send a file to be optimised in background by Clop (don't wait for a response, return immediately)
try ClopSDK.shared.optimise(path: "/path/to/image.jpg", inTheBackground: true)
```

The `optimise` method will connect to a local mach port ([CFMessagePort](https://developer.apple.com/documentation/corefoundation/cfmessageport-rs2#)) that Clop is listening to, and send the file paths to the app through it.

To make sure the app is running before sending the file paths, you can use the `waitForClopToBeAvailable` method:

```swift
// Wait for Clop to be available for 5 seconds
let clopIsAvailable = ClopSDK.shared.waitForClopToBeAvailable(for: 5)
```

### Stop running optimisations

You can stop currently running optimisations by calling the `stopOptimisations` method:

```swift
ClopSDK.shared.stopOptimisations()
```

### Options

You can also pass options to the `optimise` method to change the way Clop optimises the files, or to add additional functionality like cropping, downscaling, changing playback speed etc.

```swift
func optimise(
    urls                   : [URL],
    aggressive             : Bool       = false,
    downscaleTo            : Double?    = nil,
    cropTo                 : CropSize?  = nil,
    changePlaybackSpeedBy  : Double?    = nil,
    hideGUI                : Bool       = false,
    copyToClipboard        : Bool       = false,
    inTheBackground        : Bool       = false
) throws -> [OptimisationResponse]

// There are various overloads of the method for convenience in path passing

optimise(path  : FilePath, ...)
optimise(path  : String, ...)
optimise(url   : URL, ...)

optimise(paths : [FilePath], ...)
optimise(paths : [String], ...)
optimise(urls  : [URL], ...)
```

The response will contain the optimised file path, which can be different if the file had to be converted to a more compatible format *(depending on how the app is configured by the user)*.

```swift
struct OptimisationResponse {
    let path: String // The optimised file path
    let forURL: URL // The original file URL
    var convertedFrom: String? = nil // File that started the conversion

    var oldBytes = 0 // File size before optimisation
    var newBytes = 0 // File size after optimisation

    var oldWidthHeight: CGSize? = nil // Dimensions before optimisation
    var newWidthHeight: CGSize? = nil // Dimensions after optimisation
}
```

For more examples on how to use the SDK, check out the [tests](Tests/ClopSDKTests/ClopSDKTests.swift).

### Objective-C

ClopSDK is also available in Objective-C:

```objc
bool clopIsAvailable = [ClopSDKObjC.shared waitForClopToBeAvailableFor:5];
if (!clopIsAvailable) {
    NSLog(@"Clop is not available");
    return 1;
}

OptimisationResponseObjC* response = [ClopSDKObjC.shared optimiseWithPath:@"/path/to/image.png" error:nil];
if (response) {
    NSLog(@"File optimised at %@", response.path);
}
```

## License
ClopSDK is available under the MIT license. See the [LICENSE](LICENSE) file for more info.
