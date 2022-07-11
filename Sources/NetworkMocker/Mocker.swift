import Foundation

public class Mocker {
    /// The shared network mocker.
    ///
    /// By default the shared mocker does not contain any mocks. You must call `setMocksBundle` once before using it.
    public static let shared = Mocker()

    /// The simulated network delay that is applied to all activated mocks.
    public var delay: TimeInterval = 0.5

    /// All endpoints that are available for mocking.
    private(set) var endpoints: [Endpoint] = []

    /// Initializes a new `Mocker`.
    /// - Parameter mocksBundle: A bundle containing network mocks.
    internal init(mocksBundle: Bundle, baseURL: String = "") throws {
        self.endpoints = try MocksBundle(bundle: mocksBundle, baseURL: baseURL).discoverMocks()
    }

    private init() {
        self.endpoints = []
    }

    /// Load mocks from the given `bundle`. This will deactivate all previously activated mocks.
    /// - Parameter mocksBundle: A bundle containing network mocks.
    public func setMocksBundle(_ mocksBundle: Bundle, baseURL: String = "") throws {
        self.endpoints = try MocksBundle(bundle: mocksBundle, baseURL: baseURL).discoverMocks()
    }

    /// Activates a predefined mock file for the given path and method.
    /// - Parameters:
    ///   - name: The name of the mock file to activate.
    ///   - path: The path for which to activate the mock.
    ///   - method: The HTTP method for which to activate the mock.
    /// - Throws:
    ///   - MockerError.mockNotFound if the mock file does not exist in the mock bundle.
    public func activate(mockNamed name: String, forPath path: String, method: String) throws {
        guard let index = index(ofEndpointWithPath: path, method: method),
              let mock = endpoints[index].availableMocks.first(where: {
                  $0.id == name
              })
        else {
            throw MockerError.mockNotFound(name: name, path: path, method: method)
        }

        endpoints[index] = endpoints[index].activated(mock: mock)
    }

    /// Activates a mock for the given path and method, simulating a successful network response.
    /// - Parameters:
    ///   - path: The path for which to activate the mock.
    ///   - method: The HTTP method for which to activate the mock.
    ///   - statusCode: The mocked HTTP status code.
    ///   - data: The mocked HTTP response body.
    public func activate(mockForPath path: String, method: String, statusCode: Int, data: Data) throws {
        let mock = Mock(
            id: "ad-hoc",
            method: method,
            name: "ad-hoc",
            isGeneric: false,
            response: .networkResponse(data: data, statusCode: statusCode)
        )

        if let index = index(ofEndpointWithPath: path, method: method) {
            endpoints[index] = endpoints[index].activated(mock: mock)
        } else {
            let endpoint = Endpoint(path: path, method: method, availableMocks: [], activeMock: mock)
            endpoints.append(endpoint)
        }
    }

    /// Activates a mock for the given path and method, simulating a network error.
    /// - Parameters:
    ///   - path: The path for which to activate the mock.
    ///   - method: The HTTP method for which to activate the mock.
    ///   - error: The mocked error.
    public func activate(mockForPath path: String, method: String, networkError error: NSError) throws {
        let mock = Mock(
            id: "ad-hoc",
            method: method,
            name: "ad-hoc",
            isGeneric: false,
            response: .networkError(error: error)
        )

        if let index = index(ofEndpointWithPath: path, method: method) {
            endpoints[index] = endpoints[index].activated(mock: mock)
        } else {
            let endpoint = Endpoint(path: path, method: method, availableMocks: [], activeMock: mock)
            endpoints.append(endpoint)
        }
    }

    /// Deactivate mocking for an endpoint.
    /// - Parameter path: The path of the URL for which to disable mocking.
    /// - Parameter method: The HTTP method for which disable mocking.
    public func deactivateMock(forPath path: String, method: String) {
        guard let index = index(ofEndpointWithPath: path, method: method) else {
            return
        }

        endpoints[index] = endpoints[index].deactivated()
    }

    /// Deactivates all mocking, and sets the delay to 0.
    public func reset() {
        delay = 0
        endpoints = endpoints.map { $0.deactivated() }
    }
}

extension Mocker {
    func activeMock(for url: URL, method: String) -> Mock? {
        for endpoint in endpoints {
            if let mock = endpoint.activeMock,
               endpoint.method == method,
               pathComponentsMatch(input: url.path, check: endpoint.path)
            {
                return mock
            }
        }

        return nil
    }
}

extension Mocker {
    private func pathComponentsMatch(input: String, check: String) -> Bool {
        let inputComponents = input.components(separatedBy: "/")
        let checkComponents = check.components(separatedBy: "/")

        guard inputComponents.count == checkComponents.count else { return false }

        let zip = Array(zip(inputComponents, checkComponents))

        return zip.allSatisfy { (input, check) in
            input == check || (check.hasPrefix("{") && check.hasSuffix("}"))
        }
    }

    private func index(ofEndpointWithPath path: String, method: String) -> Int? {
        endpoints.firstIndex { $0.path == path && $0.method == method }
    }
}
