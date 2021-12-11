import XCTest
import Foundation
import Moya
@testable import MoyaStubber

final class MoyaStubberTests: XCTestCase {
    var stubber: MoyaStubber!

    override func setUpWithError() throws {
        try super.setUpWithError()
        stubber = try MoyaStubber(stubsBundle: bundle(named: "Stubs"))
    }

    // MARK: -

    func test_availableStubs_constainsDiscoveredStubs() throws {
        let expected = [
            StubbableEndpoint(
                name: "getUser",
                availableStubs: [
                    Stub(
                        name: "ServerError",
                        fileName: "serverError.500.json",
                        isGeneric: true,
                        response: .networkResponse(500, stub("serverError.500.json"))
                    ),
                    Stub.timeoutError,
                    Stub(
                        name: "Ok",
                        fileName: "ok.200.json",
                        isGeneric: false,
                        response: .networkResponse(200, stub("getUser/ok.200.json"))
                    )
                ]
            )
        ]

        XCTAssertEqual(stubber.stubbableEndpoints, expected)
    }

    // MARK: -

    func test_activateStubForEndpoint_whenPassingStub_activatesTheStub() {
        let stub = stubber.stubbableEndpoints[0].availableStubs[0]
        stubber.activate(stub: stub, forEndpointNamed: "getUser")

        let actual = stubber.activeStub(forEndpointNamed: "getUser")
        XCTAssertEqual(actual, stub)
    }

    func test_activateStubForEndpoint_whenPassingNil_deactivatesTheStub() {
        let stub = stubber.stubbableEndpoints[0].availableStubs[0]
        stubber.activate(stub: stub, forEndpointNamed: "getUser")
        stubber.activate(stub: nil, forEndpointNamed: "getUser")

        let actual = stubber.activeStub(forEndpointNamed: "getUser")
        XCTAssertNil(actual)
    }

    // MARK: -

    func test_activateStubNamedForEndpoint_activatesTheStub() throws {
        try stubber.activate(stubNamed: "ok.200.json", forEndpoint: "getUser")

        let actual = stubber.activeStub(forEndpointNamed: "getUser")
        let expected = stubber.stubbableEndpoints[0].availableStubs[2]
        XCTAssertEqual(actual, expected)
    }

    // MARK: -

    func test_deactivateStubForEndpoint_whenPassingNil_deactivatesTheStub() {
        let stub = stubber.stubbableEndpoints[0].availableStubs[0]
        stubber.activate(stub: stub, forEndpointNamed: "getUser")
        stubber.deactivateStub(forEndpoint: "getUser")

        let actual = stubber.activeStub(forEndpointNamed: "getUser")
        XCTAssertNil(actual)
    }

    // MARK: -
    
    func test_setStubsBundle_clearsActiveStubs() {
        let stub = stubber.stubbableEndpoints[0].availableStubs[0]
        stubber.activate(stub: stub, forEndpointNamed: "getUser")

        try! stubber.setStubsBundle(bundle(named: "EmptyBundle"))

        let actual = stubber.activeStub(forEndpointNamed: "getUser")
        XCTAssertNil(actual)
    }

    // MARK: -

    func test_activeStubForTarget_forStubbableEndpoint_returnsActiveStub() {
        let stub = stubber.stubbableEndpoints[0].availableStubs[0]
        stubber.activate(stub: stub, forEndpointNamed: "getUser")

        let actual = stubber.activeStub(for: TestMoyaTarget.getUser(id: 1))
        XCTAssertEqual(actual, stub)
    }

    func test_activeStubForTarget_forUnstubbableEndpoint_returnsNil() {
        let actual = stubber.activeStub(for: TestMoyaTarget.notStubbed)
        XCTAssertNil(actual)
    }

    // MARK: - Utilities

    private func bundle(named name: String) -> Bundle {
        if let bundle = Bundle.module
            .url(forResource: name, withExtension: "bundle")
            .flatMap({ Bundle(url: $0) })
        {
            return bundle
        } else {
            fatalError("Could not find bundle named \(name)")
        }
    }

    private func stub(_ name: String) -> Data {
        let url = bundle(named: "Stubs").url(forResource: name, withExtension: nil)!
        return try! Data(contentsOf: url)
    }
}

private enum TestMoyaTarget: TargetType {
    case getUser(id: Int)
    case notStubbed

    var baseURL: URL { fatalError() }
    var path: String { fatalError() }
    var method: Moya.Method { fatalError() }
    var sampleData: Data { fatalError() }
    var task: Task { fatalError() }
    var headers: [String : String]? { fatalError() }
}
