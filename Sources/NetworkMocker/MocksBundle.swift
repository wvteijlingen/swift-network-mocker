import Foundation

struct MocksBundle {
    private let bundle: Bundle
    private let baseURL: String

    init(bundle: Bundle, baseURL: String? = nil) {
        self.bundle = bundle
        self.baseURL = baseURL.map { "/" + $0.trimmingCharacters(in: .pathSeparator) } ?? ""
    }

    func discoverMocks() throws -> [Endpoint] {
        let endpointsDirectoryURL = bundle.bundleURL.appendingPathComponent("endpoints")
        let genericEndpointsDirectoryURL = bundle.bundleURL.appendingPathComponent("generic")

        let genericMocks = try discoverMocks(fromDirectory: genericEndpointsDirectoryURL, isGeneric: true)
        
        return try discoverEndpoints(
            fromDirectory: endpointsDirectoryURL,
            root: endpointsDirectoryURL,
            genericMocks: genericMocks
        ).sorted { lhs, rhs in
            if lhs.path == rhs.path {
                return lhs.method < rhs.method
            } else {
                return lhs.path < rhs.path
            }
        }
    }
    
    private func discoverEndpoints(
        fromDirectory directory: URL,
        root: URL,
        genericMocks: [Mock]
    ) throws -> [Endpoint] {
        let path = [
            baseURL,
            directory.path.components(separatedBy: root.path)[1].trimmingCharacters(in: .pathSeparator)
        ].joined(separator: "/")

        let mocks = try discoverMocks(fromDirectory: directory, isGeneric: false)
        let mocksGroupedByMethod = Dictionary(grouping: mocks, by: \.method)
        
        var discoveredEndpoints = mocksGroupedByMethod.map { method, mocks in
            Endpoint(
                path: path,
                method: method,
                availableMocks: mocks + genericMocks.filter { $0.method == method || $0.method == "ANY" }
            )
        }

        // Recurse into child directories
        let childEndpoints = try FileManager.default
            .shallowEnumerator(at: directory)
            .filter(\.isDirectory)
            .flatMap {
                try discoverEndpoints(fromDirectory: $0, root: root, genericMocks: genericMocks)
            }
        
        discoveredEndpoints.append(contentsOf: childEndpoints)
        
        return discoveredEndpoints
    }
    
    private func discoverMocks(fromDirectory sourceDirectory: URL, isGeneric: Bool) throws -> [Mock] {
        try FileManager.default
            .shallowEnumerator(at: sourceDirectory)
            .filter(\.isFile)
            .map { fileURL in
                let (fileName, method, name, statusCode) = try parseFileName(ofMockAt: fileURL)

                guard let data = try? Data(contentsOf: fileURL) else {
                    throw NetworkMockerError.couldNotLoadFile(url: fileURL)
                }
                
                return Mock(
                    fileName: fileName,
                    method: method,
                    name: name,
                    isGeneric: isGeneric,
                    response: .networkResponse(data: data, statusCode: statusCode)
                )
            }
            .sorted { lhs, rhs in
                lhs.fileName < rhs.fileName
            }
    }

    private func parseFileName(
        ofMockAt url: URL
    ) throws -> (fileName: String, method: String, name: String, statusCode: Int) {
        let fileName = url.lastPathComponent
        let fileNameComponents = fileName.components(separatedBy: ".")

        guard let method = fileNameComponents[safe: 0],
              let name = fileNameComponents[safe: 1],
              let statusCode = fileNameComponents[safe: 2].flatMap({ Int($0) })
        else {
            throw NetworkMockerError.invalidFileName(url: url)
        }

        return (fileName, method, name, statusCode)
    }
}
