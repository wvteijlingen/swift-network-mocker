#if canImport(UIKit)

import UIKit

class EndpointsViewController: UITableViewController {
  private let stubber: MoyaStubber

  init(stubber: MoyaStubber) {
    self.stubber = stubber
    super.init(style: .grouped)
    self.title = "Network Stubbing"
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  public override func viewDidLoad() {
    super.viewDidLoad()

    tableView.register(DetailLabelCell.self, forCellReuseIdentifier: "DetailLabelCell")

    let resetButton = UIBarButtonItem(title: "Reset", style: .plain, target: self, action: #selector(didTapReset))
    resetButton.tintColor = .systemRed

    navigationItem.rightBarButtonItem = resetButton
  }

  public override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    tableView.reloadData()
  }

  @objc func didTapReset() {
    stubber.reset()
    tableView.reloadData()
  }

  private func showDelayPicker() {
    let alert = UIAlertController(title: "Response delay", message: nil, preferredStyle: .actionSheet)
    let delays: [TimeInterval] = [10, 5, 2, 0.5, 0]

    for delay in delays {
      let action = UIAlertAction(title: "\(delay) seconds", style: .default) { _ in
        self.stubber.delay = delay
        self.tableView.reloadData()
      }

      alert.addAction(action)
    }

    present(alert, animated: true)
  }
}

// MARK: - UITableViewDataSource

extension EndpointsViewController {
  public override func numberOfSections(in tableView: UITableView) -> Int {
    2
  }

  public override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    section == 0 ? nil : "Endpoints"
  }

  public override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    section == 0 ? 1 : stubber.stubbableEndpoints.count
  }

  public override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "DetailLabelCell") as! DetailLabelCell

    if indexPath.section == 0 {
      cell.textLabel?.text = "Stub response delay"
      cell.detailTextLabel?.text = "\(stubber.delay) seconds"
    } else {
      let endpointName = stubber.stubbableEndpoints[indexPath.row].name
      cell.textLabel?.text = endpointName
      cell.detailTextLabel?.text = stubber.activeStub(forEndpointNamed: endpointName)?.name
      cell.accessoryType = .disclosureIndicator
    }

    return cell
  }
}

// MARK: - UITableViewDelegate

extension EndpointsViewController {
  public override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    if indexPath.section == 0 {
      showDelayPicker()
    } else {
      let endpoint = stubber.stubbableEndpoints[indexPath.row]
      let detailsViewController = EndpointDetailsViewController(stubber: stubber, endpoint: endpoint)
      navigationController?.pushViewController(detailsViewController, animated: true)
    }
  }
}

#endif
