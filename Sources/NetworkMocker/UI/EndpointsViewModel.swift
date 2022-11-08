import Foundation
import Combine

class EndpointsViewModel: ObservableObject {
    @Published var delay: TimeInterval
    var endpoints: [Endpoint] { mocker.endpoints }

    private let mocker: Mocker
    private var cancellables = Set<AnyCancellable>()

    init(mocker: Mocker) {
        self.mocker = mocker
        self.delay = mocker.delay

        self.$delay.sink { delay in
            self.mocker.delay = delay
        }.store(in: &cancellables)
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
