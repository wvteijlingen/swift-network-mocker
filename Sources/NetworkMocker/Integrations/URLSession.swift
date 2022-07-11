import Foundation

open class MockingURLProtocol: URLProtocol {
    override public func startLoading() {
        guard let url = request.url,
              let method = request.httpMethod,
              let mock = Mocker.shared.activeMock(for: url, method: method)
        else {
            fatalError("Could not get active mock for request \(request)")
        }

        if Mocker.shared.delay > 0 {
            DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + Mocker.shared.delay) {
                self.finishRequest(for: mock, url: url)
            }
        } else {
            finishRequest(for: mock, url: url)
        }
    }

    override public func stopLoading() {
        //
    }

    override public class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override public class func canInit(with request: URLRequest) -> Bool {
        guard let url = request.url, let method = request.httpMethod else { return false }
        return Mocker.shared.activeMock(for: url, method: method) != nil
    }


    private func finishRequest(for mock: Mock, url: URL) {
        switch mock.response {
        case .networkResponse(let data, let statusCode):
            guard let response = HTTPURLResponse(
                url: url,
                statusCode: statusCode,
                httpVersion: nil,
                headerFields: nil
            ) else {
                fatalError("Could not create mock HTTPURLResponse for URL \(url.absoluteString)")
            }

            self.client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            self.client?.urlProtocol(self, didLoad: data)
            self.client?.urlProtocolDidFinishLoading(self)

        case .networkError(let error):
            self.client?.urlProtocol(self, didFailWithError: error)
        }
    }
}
