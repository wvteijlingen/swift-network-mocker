#if canImport(UIKit)

import UIKit

public class MoyaStubberViewController: UINavigationController {
  public init(stubber: MoyaStubber) {
    let endpointsViewController = EndpointsViewController(stubber: stubber)
    super.init(rootViewController: endpointsViewController)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

#endif
