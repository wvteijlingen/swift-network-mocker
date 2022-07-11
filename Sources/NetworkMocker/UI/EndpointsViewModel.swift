import Foundation

class EndpointsViewModel: ObservableObject {
    let mocker: Mocker

    var delay: TimeInterval { mocker.delay }
    var endpoints: [Endpoint] { mocker.endpoints }

    init(mocker: Mocker) {
        self.mocker = mocker
    }
    
    func activate(mockNamed name: String, for endpoint: Endpoint) {
        objectWillChange.send()

        if name == "nil" {
            mocker.deactivateMock(forPath: endpoint.path, method: endpoint.method)
        } else {
            try? mocker.activate(mockNamed: name, forPath: endpoint.path, method: endpoint.method)
        }
    }

    func reset() {
        objectWillChange.send()
        mocker.reset()
    }
}
