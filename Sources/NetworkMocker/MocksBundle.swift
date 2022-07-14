import Foundation

struct MocksBundle {
    private let bundle: Bundle
    private let baseURL: String
    
    init(bundle: Bundle, baseURL: String) {
        self.bundle = bundle
        self.baseURL = "/" + baseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
    }
    
    func discoverMocks() throws -> [Endpoint] {
        let genericMocks = try discoverMocks(
            fromDirectory: bundle.bundleURL.appendingPathComponent("generic"),
            isGeneric: true
        )
        
        return try discoverEndpoints(
            fromDirectory: bundle.bundleURL.appendingPathComponent("endpoints"),
            root: bundle.bundleURL.appendingPathComponent("endpoints"),
            genericMocks: genericMocks
        ).sorted(by: { lhs, rhs in
            if lhs.path == rhs.path {
                return lhs.method < rhs.method
            } else {
                return lhs.path < rhs.path
            }
        })
    }
    
    private func discoverEndpoints(
        fromDirectory directory: URL,
        root: URL,
        genericMocks: [Mock]
    ) throws -> [Endpoint] {
        let path = [
            baseURL,
            directory.path.components(separatedBy: root.path)[1].trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        ].joined(separator: "/")

        let mocks = try discoverMocks(fromDirectory: directory, isGeneric: false)

        var discoveredEndpoints = Dictionary(grouping: mocks) {
            $0.method
        }.map { method, mocks in
            Endpoint(
                path: path,
                method: method,
                availableMocks: mocks + genericMocks.filter { $0.method == method || $0.method == "ANY" }
            )
        }
        
        let childEndpoints = try FileManager.default.shallowEnumerator(at: directory)
            .filter(\.isDirectory)
            .flatMap {
                try discoverEndpoints(fromDirectory: $0, root: root, genericMocks: genericMocks)
            }
        
        discoveredEndpoints.append(contentsOf: childEndpoints)
        
        return discoveredEndpoints
    }
    
    private func discoverMocks(fromDirectory sourceDirectory: URL, isGeneric: Bool) throws -> [Mock] {
        try FileManager.default.shallowEnumerator(at: sourceDirectory)
            .filter(\.isFile)
            .map { fileURL in
                let fileNameParts = fileURL.lastPathComponent.split(separator: ("."))
                
                guard let method = fileNameParts[safe: 0].flatMap({ String($0).uppercased() }),
                      let name = fileNameParts[safe: 1].flatMap({ String($0) }),
                      let statusCode = fileNameParts[safe: 2].flatMap({ Int($0) })
                else {
                    throw MockerError.invalidFileName(url: fileURL)
                }
                
                guard let data = try? Data(contentsOf: fileURL) else {
                    throw MockerError.couldNotLoadFile(url: fileURL)
                }
                
                return Mock(
                    id: fileURL.lastPathComponent,
                    method: method,
                    name: name,
                    isGeneric: isGeneric,
                    response: .networkResponse(data: data, statusCode: statusCode)
                )
            }
    }
}
