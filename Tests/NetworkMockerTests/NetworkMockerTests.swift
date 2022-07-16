import XCTest
import Foundation
@testable import NetworkMocker

final class NetworkMockerTests: XCTestCase {
  var mocker: Mocker!

  override func setUpWithError() throws {
    try super.setUpWithError()
    mocker = try Mocker(mocksBundle: bundle(named: "Mocks"))
  }

  // MARK: - endpoints

  func test_endpoints_containsDiscoveredEndpoints() throws {
    let expected = [
      Endpoint(path: "/users", method: "GET", availableMocks: [
        Mock(fileName: "get.success.200.json", method: "GET", name: "success", isGeneric: false, response: .networkResponse(data: mock("endpoints/users/get.success.200.json"), statusCode: 200)),
        Mock(fileName: "any.notFound.404.json", method: "ANY", name: "notFound", isGeneric: true, response: .networkResponse(data: mock("generic/any.notFound.404.json"), statusCode: 404)),
        Mock(fileName: "get.serverError.500.json", method: "GET", name: "serverError", isGeneric: true, response: .networkResponse(data: mock("generic/get.serverError.500.json"), statusCode: 500))
      ]),
      Endpoint(path: "/users", method: "POST", availableMocks: [
        Mock(fileName: "post.success.202.json", method: "POST", name: "success", isGeneric: false, response: .networkResponse(data: mock("endpoints/users/post.success.202.json"), statusCode: 202)),
        Mock(fileName: "any.notFound.404.json", method: "ANY", name: "notFound", isGeneric: true, response: .networkResponse(data: mock("generic/any.notFound.404.json"), statusCode: 404))
      ]),
      Endpoint(path: "/users/0", method: "GET", availableMocks: [
        Mock(fileName: "get.notFound.404.json", method: "GET", name: "notFound", isGeneric: false, response: .networkResponse(data: mock("endpoints/users/0/get.notFound.404.json"), statusCode: 404)),
        Mock(fileName: "any.notFound.404.json", method: "ANY", name: "notFound", isGeneric: true, response: .networkResponse(data: mock("generic/any.notFound.404.json"), statusCode: 404)),
        Mock(fileName: "get.serverError.500.json", method: "GET", name: "serverError", isGeneric: true, response: .networkResponse(data: mock("generic/get.serverError.500.json"), statusCode: 500)),
      ]),
      Endpoint(path: "/users/{id}", method: "GET", availableMocks: [
        Mock(fileName: "get.success.200.json", method: "GET", name: "success", isGeneric: false, response: .networkResponse(data: mock("endpoints/users/{id}/get.success.200.json"), statusCode: 200)),
        Mock(fileName: "any.notFound.404.json", method: "ANY", name: "notFound", isGeneric: true, response: .networkResponse(data: mock("generic/any.notFound.404.json"), statusCode: 404)),
        Mock(fileName: "get.serverError.500.json", method: "GET", name: "serverError", isGeneric: true, response: .networkResponse(data: mock("generic/get.serverError.500.json"), statusCode: 500)),
      ])
    ]

    XCTAssertEqual(mocker.endpoints, expected)
  }

  // MARK: - activateMockNamed

  func test_activateMockNamedForEndpoint_activatesTheStub() throws {
    try mocker.activate(mockNamed: "get.success.200.json", forPath: "/users", method: "GET")

    let url = URL(string: "http://example.com/users")!
    let actual = mocker.activeMock(for: url, method: "GET")
    let expected = mocker.endpoints[0].availableMocks[0]

    XCTAssertEqual(actual, expected)
  }

  // MARK: - deactivateMockForPath

  func test_deactivateMockForPath_whenPassingNil_deactivatesTheStub() throws {
    try mocker.activate(mockNamed: "get.success.200.json", forPath: "/users", method: "GET")
    mocker.deactivateMock(forPath: "/users", method: "GET")

    let url = URL(string: "http://example.com/users")!
    let actual = mocker.activeMock(for: url, method: "GET")

    XCTAssertNil(actual)
  }

  // MARK: - setMocksBundle

  func test_setMocksBundle_clearsActiveStubs() throws {
    try mocker.activate(mockNamed: "get.success.200.json", forPath: "/users", method: "GET")
    try! mocker.setMocksBundle(bundle(named: "EmptyBundle"))

    let url = URL(string: "http://example.com/users")!
    let actual = mocker.activeMock(for: url, method: "GET")

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

  private func mock(_ name: String) -> Data {
    let url = bundle(named: "Mocks").url(forResource: name, withExtension: nil)!
    return try! Data(contentsOf: url)
  }
}
