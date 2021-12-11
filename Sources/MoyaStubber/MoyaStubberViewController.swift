#if canImport(UIKit)

import UIKit

public class MoyaStubberViewController: UINavigationController {
  public init(stubber: MoyaStubber) {
    let endpointsViewController = EndpointsViewController(stubber: stubber)

    super.init(rootViewController: endpointsViewController)

    endpointsViewController.navigationItem.leftBarButtonItem = UIBarButtonItem(
      barButtonSystemItem: .done,
      target: self,
      action: #selector(didTapDone)
    )
  }

  @available(*, unavailable)
  required init?(coder aDecoder: NSCoder) {
    fatalError("Use init(stubber:) to initialize a MoyaStubberViewController")
  }

  @available(*, unavailable)
  override init(rootViewController: UIViewController) {
    fatalError("Use init(stubber:) to initialize a MoyaStubberViewController")
  }

  @available(*, unavailable)
  override init(navigationBarClass: AnyClass?, toolbarClass: AnyClass?) {
    fatalError("Use init(stubber:) to initialize a MoyaStubberViewController")
  }

  @objc func didTapDone() {
    dismiss(animated: true)
  }
}

#endif
