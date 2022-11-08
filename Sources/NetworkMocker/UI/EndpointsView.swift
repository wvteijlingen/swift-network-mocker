import SwiftUI

public struct EndpointsView: View {
    @ObservedObject private var viewModel: EndpointsViewModel

    public init(mocker: Mocker = Mocker.shared) {
        viewModel = EndpointsViewModel(mocker: mocker)
    }

    public var body: some View {
        List {
            Section(header: Text("Response Delay")) {
                Stepper(value: $viewModel.delay, step: 0.5) {
                    Text(viewModel.delay.formatted() + " seconds")
                }
            }

            Section(header: Text("Endpoints")) {
                ForEach(viewModel.endpoints)  { endpoint in
                    EndpointRow(viewModel: viewModel, endpoint: endpoint)
                }
            }
        }
        .listStyle(GroupedListStyle())
        .navigationBarTitle("Network Mocking")
        .navigationBarItems(
            trailing: Button("Reset", action: viewModel.reset).foregroundColor(.red)
        )
    }
}

private struct EndpointRow: View {
    @ObservedObject private var viewModel: EndpointsViewModel

    private let endpoint: Endpoint
    private var selectionBinding: Binding<String>

    init(viewModel: EndpointsViewModel, endpoint: Endpoint) {
        self.viewModel = viewModel
        self.endpoint = endpoint

        self.selectionBinding = Binding<String>(
            get: { endpoint.activeMock?.id ?? "nil" },
            set: { viewModel.activate(mockNamed: $0, for: endpoint) }
        )
    }

    var body: some View {
        HStack {
            Text(endpoint.method.uppercased())
                .font(.system(size: 13))
                .foregroundColor(.gray)
                .frame(width: 35, alignment: .leading)

            Text(endpoint.path)
                .font(.system(size: 13))

            Spacer()

            Picker(selection: selectionBinding) {
                Section {
                    Text("none").tag("nil")
                }
                Section("Mocks for endpoint") {
                    ForEach(endpoint.nonGenericMocks) { mock in
                        Text(mock.displayName).tag(mock.id)
                    }
                }
                Section("Generic mocks") {
                    ForEach(endpoint.genericMocks) { mock in
                        Text(mock.displayName).tag(mock.id)
                    }
                }
            } label: {
                Text(endpoint.activeMock?.displayName ?? "None")
            }
        }
        .accentColor(endpoint.activeMock == nil ? .gray : .blue)
        .pickerStyle(.menu)
    }
}

private extension Mock {
    var displayName: String {
        if let statusCode = statusCode {
            return "\(name) (\(statusCode))"
        } else {
            return name
        }
    }
}
