import Foundation
import Moya

public class MoyaStubber {
  /// The shared network stubber.
  ///
  /// By default this stubber does not contain any stubs. You must call `setStubsBundle` to load stubs.
  public static let shared = MoyaStubber()

  /// The simulated network delay that is applied to all activated stubs.
  public var delay: TimeInterval = 0

  /// All endpoints that are available for stubbing.
  private(set) var stubbableEndpoints: [StubbableEndpoint]

  private var activeStubs: [String: Stub] = [:]

  /// Initializes a new `MoyaStubber`.
  /// - Parameter stubsBundle: A bundle containing network stubs.
  public init(stubsBundle: Bundle) throws {
    self.stubbableEndpoints = try loadStubsBundle(stubsBundle)
  }

  private init() {
    self.stubbableEndpoints = []
  }

  /// Load stubs from the given `bundle`. This will deactivate all previously activated stubs.
  /// - Parameter stubsBundle: A bundle containing network stubs.
  public func setStubsBundle(_ stubsBundle: Bundle) throws {
    self.activeStubs = [:]
    self.stubbableEndpoints = try loadStubsBundle(stubsBundle)
  }

  /// Activate a stub with given `name` for an endpoint.
  ///
  /// - Parameters:
  ///   - stubName: The name of the stub file. For example: "ok.200.json"
  ///   - endpointName: The name of the endpoint to activate the stub for.
  public func activate(stubNamed name: String, forEndpoint endpointName: String) throws {
    guard let stub = stubbableEndpoints
            .first(where: { $0.name == endpointName })?
            .availableStubs.first(where: { $0.fileName == name })
    else {
      throw MoyaStubberError.stubNotFound(stubName: name, endpointName: endpointName)
    }

    activeStubs[endpointName] = stub
  }

  /// Deactivate stubbing for an endpoint.
  /// - Parameter endpointName: The name of the endpoint to deactivate stubbing for.
  public func deactivateStub(forEndpoint endpointName: String) {
    activeStubs[endpointName] = nil
  }

  /// Deactivates all stubbing, and sets the delay to 0.
  public func reset() {
    delay = 0
    activeStubs = [:]
  }

  /// Returns the active stub for the given `endpointName`, or nil if no stub is active for that endpoint.
  func activeStub(forEndpointNamed endpointName: String) -> Stub? {
    activeStubs[endpointName]
  }

  /// Activate the given `stub` for an endpoint. If `stub` is nil, stubbing will be deactivated for the endpoint.
  ///
  /// - Parameters:
  ///   - stub: The stub to activate.
  ///   - endpointName: The endpoint to stub.
  func activate(stub: Stub?, forEndpointNamed endpointName: String) {
    guard let stub = stub else {
      activeStubs[endpointName] = nil
      return
    }

    activeStubs[endpointName] = stub
  }

  func activeStub(for target: TargetType) -> Stub? {
    // Use reflection to get the name of the enum case
    let mirror = Mirror(reflecting: target)
    let endpointName = mirror.children.first?.label ?? String(describing: target)
    return activeStubs[endpointName]
  }
}

// MARK: - Moya

extension MoyaStubber {
  /// Don't call this function yourself. Instead, pass a reference to it in the `endpointClosure` parameter
  /// of the MoyaProvider initializer.
  ///
  /// Example:
  /// ```
  /// MoyaProvider(
  ///     endpointClosure: NetworkStubber.shared.endpointClosure,
  ///     stubClosure: NetworkStubber.shared.stubClosure
  /// )
  /// ```
  public func endpointClosure<T: TargetType>(for target: T) -> Endpoint {
    wrappingEndpointClosure(originalClosure: MoyaProvider<T>.defaultEndpointMapping)(target)
  }

  /// Returns an endpoint closure that wraps arpund around the `originalClosure`.
  /// You should only use this if you want to use a custom Moya endpointClosure.
  ///
  /// - Returns: The underlying endpoint closure.
  public func wrappingEndpointClosure<T: TargetType>(
    originalClosure: @escaping MoyaProvider<T>.EndpointClosure
  ) -> MoyaProvider<T>.EndpointClosure {
    { target in
      let defaultEndpoint = originalClosure(target)

      guard let stub = self.activeStub(for: target) else {
        return defaultEndpoint
      }

      return Endpoint(
        url: defaultEndpoint.url,
        sampleResponseClosure: { stub.response },
        method: defaultEndpoint.method,
        task: defaultEndpoint.task,
        httpHeaderFields: defaultEndpoint.httpHeaderFields
      )
    }
  }

  /// Don't call this function yourself. Instead, pass a reference to it in the `stubClosure` parameter
  /// of the MoyaProvider initializer.
  ///
  /// Example:
  /// ```
  /// MoyaProvider(
  ///     endpointClosure: NetworkStubber.shared.endpointClosure,
  ///     stubClosure: NetworkStubber.shared.stubClosure
  /// )
  /// ```
  public func stubClosure(for target: TargetType) -> StubBehavior {
    guard activeStub(for: target) != nil else { return .never }
    return delay > 0 ? .delayed(seconds: delay) : .immediate
  }
}

// MARK: - Stub discovery

private func loadStubsBundle(_ bundle: Bundle) throws -> [StubbableEndpoint] {
  let builtInStubs = [Stub.timeoutError]
  let genericStubs = try discoverStubs(fromDirectory: bundle.bundleURL, isGeneric: true)
  let endpoints = try discoverEndpoints(fromDirectory: bundle.bundleURL)

  return try endpoints.map {
    let endpointStubs = try discoverStubs(fromDirectory: $0.directory, isGeneric: false)
    return StubbableEndpoint(name: $0.name, availableStubs: builtInStubs + genericStubs + endpointStubs)
  }
}

private func discoverEndpoints(fromDirectory sourceDirectory: URL) throws -> [(name: String, directory: URL)] {
  try FileManager.default.shallowEnumerator(at: sourceDirectory)
    .filter(\.isDirectory)
    .map { (name: $0.lastPathComponent, directory: $0) }
}

private func discoverStubs(fromDirectory sourceDirectory: URL, isGeneric: Bool) throws -> [Stub] {
  try FileManager.default.shallowEnumerator(at: sourceDirectory)
    .filter(\.isFile)
    .map { fileURL in
      let fileNameParts = fileURL.lastPathComponent.split(separator: ("."))
      let fileExtension = fileURL.pathExtension

      guard let statusCode = fileNameParts[safe: 1].flatMap({ Int($0) }),
            let name = fileNameParts[safe: 0].map({ "\($0) \(statusCode) (\(fileExtension))" })
      else {
        throw MoyaStubberError.invalidFileName(url: fileURL)
      }

      guard let data = try? Data(contentsOf: fileURL) else {
        throw MoyaStubberError.couldNotLoadFile(url: fileURL)
      }

      return Stub(
        name: name,
        fileName: fileURL.lastPathComponent,
        isGeneric: isGeneric,
        response: .networkResponse(statusCode, data)
      )
    }
}
