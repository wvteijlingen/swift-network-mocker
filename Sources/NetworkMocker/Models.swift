import Foundation

/// An endpoint for which mocks exist in the mock bundle.
struct Endpoint: Equatable, Identifiable {
    var id: String { "\(method) \(path)" }

    let path: String
    let method: String
    let availableMocks: [Mock]
    var activeMock: Mock?

    var genericMocks: [Mock] { availableMocks.filter(\.isGeneric) }
    var nonGenericMocks: [Mock] { availableMocks.filter { !$0.isGeneric} }

    init(path: String, method: String, availableMocks: [Mock] = [], activeMock: Mock? = nil) {
        self.path = path
        self.method = method
        self.availableMocks = availableMocks
        self.activeMock = activeMock
    }

    func activated(mock: Mock) -> Self {
        Endpoint(path: path, method: method, availableMocks: availableMocks, activeMock: mock)
    }

    func deactivated() -> Self {
        Endpoint(path: path, method: method, availableMocks: availableMocks, activeMock: nil)
    }
}

/// A mock that exists for an endpoint.
struct Mock: Identifiable, Equatable {
    enum Response: Equatable {
        case networkResponse(data: Data, statusCode: Int)
        case networkError(error: NSError)
    }

    let id: String
    let method: String
    let name: String
    let isGeneric: Bool
    let response: Response

    var displayName: String {
        if let statusCode = statusCode {
            return "\(name) (\(statusCode))"
        } else {
            return name
        }
    }

    /// The response data for this mock. If this mock respresents a network error, the data will be nil.
    var data: Data? {
        switch response {
        case .networkResponse(let data, _):
            return data
        case .networkError:
            return nil
        }
    }

    /// The response status code for this mock. If this mock respresents a network error, the status code will be nil.
    var statusCode: Int? {
        switch response {
        case .networkResponse(_, let statusCode):
            return statusCode
        case .networkError:
            return nil
        }
    }
}

// MARK: - Errors

enum MockerError: Error, LocalizedError {
    case invalidFileName(url: URL)
    case couldNotEnumerate(url: URL)
    case couldNotLoadFile(url: URL)
    case mockNotFound(name: String, path: String, method: String)

    var errorDescription: String? {
        switch self {
        case .invalidFileName(let url):
            return "The file \(url) does not match expected filename '[method].[name].[statusCode].[extension]'"
        case .couldNotEnumerate(let url):
            return "The directory \(url) could not be enumerated."
        case .couldNotLoadFile(let url):
            return "The file \(url) could not be loaded."
        case .mockNotFound(let name, let path, let method):
            return "Mock \(name) could not be found for \(method.uppercased()) \(path)"
        }
    }
}

// MARK: - Built-in Mocks

//extension Mock {
//    static let networkTimeout = Mock(
//        id: "get.networkTimeout",
//        method: <#T##String#>, name: <#T##String#>, isGeneric: <#T##Bool#>, response: <#T##Response#>)
//}