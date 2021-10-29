<img src="./moya-stubber.png" width="150" height="150"/>

# moya-stubber: supercharged stubbing for Moya

Moya-stubber speeds up development and testing by adding a network stubbing screen to your app. It will:

- Provide a view controller to activate and deactivate stubs at runtime.
- Allow you to configure multiple stubbed responses per endpoint, so you can easilty test your code in multiple scenarios.
- Use regular files for stubbed responses (json, xml, or any other filetype).
- Define a clear hierarchical structure for your stubs.

## Installation

**Swift Package Manager**

```swift
.package(url: "https://github.com/wvteijlingen/moya-stubber.git", .upToNextMajor(from: "0.1.0"))
```

**CocoaPods**

```ruby
pod "moya-stubber", :git => "https://github.com/wvteijlingen/moya-stubber.git"
```

**Manually**

Copy `MoyaStubber.swift` and `MoyaStubberViewController.swift` to your project.

## Usage

1. Create a bundle containing your JSON stub responses. See [Stubs.bundle file structure](#Stubs-bundle-file-structure).
2. Configure your MoyaProvider to use the stubber by adding an `endpointClosure` and `stubClosure`:

```swift
let stubsBundle = Bundle(url: Bundle.main.bundleURL.appendingPathComponent("Stubs.bundle"))!

try! MoyaStubber.shared.setStubsBundle(stubsBundle)

MoyaProvider(
    endpointClosure: MoyaStubber.shared.endpointClosure,
    stubClosure: MoyaStubber.shared.stubClosure
)
```

3. Add the stubbing view controller:

```swift
let viewController = MoyaStubberViewController(stubber: MoyaStubber.shared)
navigationController.pushViewController(viewController, animated: true)
```

## Stubs bundle file structure

MoyaStubber expects the Stubs.bundle to have the following structure:

1. Every endpoint that you want to stub must be a subdirectory of the bundle.
   Its name must match a case in your `Moya.TargetType` enum.
1. Within each endpoint directory you can place multiple stubs with the following naming pattern `[name].[statusCode].[extension]`.
1. Stubs that are placed in the root of the bundle will be available to all endpoints.
   You can use this for generic responses such as internal server errors.

### Example

If your Moya target looks like this…

```swift
enum MyMoyaTarget: TargetType {
  case getUser
  case getUserAvatar
  case deleteUser
}
```

…your stubs bundle can be structured like this:

```
Stubs.bundle
  | serverError.500.json
  | notFound.404.json
  |
  | getUser
  |   | ok.200.json
  |
  | getUserAvatar
  |   | ok.200.jpg
  |
  | deleteUser
  |   | ok.204.json
```

## Advanced

### Exclude stubs from release builds

If you don't want to include your stubs in release builds, you can exclude them from your target
and use an Xcode Build Phase to include it only when needed. The exact command will depend on the project setup.

**Example**

```bash
if [ "${CONFIGURATION}" != "Release" ]; then
  rsync --recursive --delete "${SRCROOT}/MyProject/Stubs.bundle" "${BUILT_PRODUCTS_DIR}/${PRODUCT_NAME}.app"
fi
```

### Enable stubs programatically

You can also enable or disable stubs programatically:

```swift
stubber.activate(stubNamed: "ok.200", forEndpoint: "getUser")
stubber.deactivateStub(forEndpoint: "getUser")
```
