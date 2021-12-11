//
//  File.swift
//  
//
//  Created by Ward van Teijlingen on 11/12/2021.
//

import Foundation
import Moya

/// An endpoint for which stubs exist in the stubs bundle.
struct StubbableEndpoint: Equatable {
  let name: String
  let availableStubs: [Stub]
}

/// A stub that exists in the stubs bundle.
struct Stub {
  let name: String
  let fileName: String?
  let isGeneric: Bool
  let response: EndpointSampleResponse

  /// The response data for this stub. If this stub respresents a network error, the data will be nil.
  var data: Data? {
    switch response {
    case .networkResponse(_, let data):
      return data
    case .response(_, let data):
      return data
    case .networkError:
      return nil
    }
  }

  /// The response status code for this stub. If this stub respresents a network error, the status code will be nil.
  var statusCode: Int? {
    switch response {
    case .networkResponse(let statusCode, _):
      return statusCode
    case .response(let response, _):
      return response.statusCode
    case .networkError:
      return nil
    }
  }

  static let timeoutError = Self(
    name: "Network timeout",
    fileName: nil,
    isGeneric: true,
    response: .networkError(NSError(domain: NSURLErrorDomain, code: NSURLErrorTimedOut, userInfo: nil))
  )
}

extension Stub: Equatable {
  static func == (lhs: Stub, rhs: Stub) -> Bool {
    if lhs.name != rhs.name { return false }
    if lhs.fileName != rhs.fileName { return false }

    switch(lhs.response, rhs.response) {
    case let (.networkResponse(lhsStatusCode, lhsData), .networkResponse(rhsStatusCode, rhsData)):
      return lhsStatusCode == rhsStatusCode && lhsData == rhsData
    case let (.response(lhsResponse, lhsData), .response(rhsResponse, rhsData)):
      return lhsResponse == rhsResponse && lhsData == rhsData
    case (.networkError(let lhsError), .networkError(let rhsError)):
      return lhsError == rhsError
    default:
      return false
    }
  }
}

enum MoyaStubberError: Error, LocalizedError {
  case invalidFileName(url: URL)
  case couldNotEnumerate(url: URL)
  case couldNotLoadFile(url: URL)
  case stubNotFound(stubName: String, endpointName: String)

  var errorDescription: String? {
    switch self {
    case .invalidFileName(let url):
      return "The file \(url) does not match expected filename '[stub].[statusCode].[extension]'"
    case .couldNotEnumerate(let url):
      return "The directory \(url) could not be enumerated."
    case .couldNotLoadFile(let url):
      return "The file \(url) could not be loaded."
    case .stubNotFound(let stubName, let endpointName):
      return "Stub \(stubName) could not be found for endpoint \(endpointName)."
    }
  }
}

