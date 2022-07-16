<img src="./swift-network-mocker.png" width="150" height="150"/>

# swift-network-mocker: network mocking for Swift

Swift Network Mocker speeds up development and testing by adding a network mocking screen to your app.

Want to add a mock response? It's as easy as creating a new JSON file in your project repository.
Swift Network Mocker will automatically find it and make it activatable for mockbing.

Swift Network Mocker will:

- Provide an autogenerated view to activate and deactivate mocks at runtime.
- Allow you to configure multiple mocked responses per endpoint, so you can easilty test your code in multiple scenarios.
- Allow you to activate mocks programatically to simulate network responses in unit tests.
- Define a clear hierarchical structure for your mocks.

## Installation

**Swift Package Manager**

```swift
.package(url: "https://github.com/wvteijlingen/swift-network-mocker.git", .upToNextMajor(from: "0.2.0"))
```

**CocoaPods**

```ruby
pod "swift-network-mocker", :git => "https://github.com/wvteijlingen/swift-network-mocker.git"
```

## Usage

1. Create a bundle containing your JSON mock responses. See [Mock bundle file structure](#Mock-bundle-file-structure).
2. Configure your URLSession to use the mocker:

```swift
// Load the mocks bundle
let mocksBundle = Bundle(url: Bundle.main.bundleURL.appendingPathComponent("Mocks.bundle"))!
try! NetworkMocker.shared.setMocksBundle(mocksBundle)

// Configure the URLSessionConfiguration
let configuration = URLSessionConfiguration.default
configuration.protocolClasses = [MockingURLProtocol.self] + (configuration.protocolClasses ?? [])
```

3. Add the mocking view (using SwiftUI):

```swift
NavigationLink("Mocking", destination: NetworkMocker.EndpointsView())
```

## Mock bundle file structure

Swift Network Mocker expects the Mocks bundle to have the following structure:

1. Mock files must be named according to this pattern: `[method].[name].[statusCode].json. For example: `get.ok.200.json` is a mock for a get request returning an 200 status code. You can use the method `any` to make the mock available for any request method.
1. Mock files must be placed in directories matching the URL structure of your API. For example: `Mocks.bundle/endpoints/users/{id}/posts` will match `https://example.com/users/1/posts`.
1. Directories can contain placeholders in the form of `{foo}`. These will any URL path component. For example `https://example.com/users/1/posts` will match both `Mocks.bundle/endpoints/users/1/posts` and `Mocks.bundle/endpoints/users/{id}/posts`.

**Generic mocks**
Some mocks are applicable to all endpoints, for example a generic mock for a server error. Instead of duplicating such mocks in your bundle, you can place these in the `generic` folder. These mocks will then be made available for all known endpoints.

### Example
```
Mocks.bundle
  | generic
  |   | any.serverError.500.json
  |   | any.unauthorized.401.json
  |
  | endpoints
      | users
      |   | get.ok.200.json
      |   | get.empty.200.json
      |
      | users/0
      |   | get.notFound.404.json
      |
      | users/{id}
      |   | get.ok.200.json
      |
      | users/{id}/posts
      |   | get.ok.200.json
      |   | post.ok.202.json
      |   | post.badRequest.400.json
```
