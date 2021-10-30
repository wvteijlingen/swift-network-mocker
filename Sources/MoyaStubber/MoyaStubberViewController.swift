#if canImport(UIKit)

import UIKit

public class MoyaStubberViewController: UITableViewController {
    private let stubber: MoyaStubber

    public init(stubber: MoyaStubber) {
        self.stubber = stubber
        super.init(style: .grouped)
        self.title = "Network Stubbing"
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        tableView.register(DetailLabelCell.self, forCellReuseIdentifier: "DetailLabelCell")

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Reset",
            style: .plain,
            target: self,
            action: #selector(didTapReset)
        )
    }

    @objc func didTapReset() {
        stubber.reset()
        tableView.reloadData()
    }

    private func showStubPicker(forEndpointName endpointName: String, availableStubs: [Stub]) {
        let alert = UIAlertController(title: endpointName, message: nil, preferredStyle: .actionSheet)

        for stub in availableStubs {
            let action = UIAlertAction(title: stub.displayName, style: .default) { _ in
                self.stubber.activate(stub: stub, forEndpoint: endpointName)
                self.tableView.reloadData()
            }

            alert.addAction(action)
        }

        alert.addAction(UIAlertAction(title: "No stubbing", style: .default) { _ in
            self.stubber.activate(stub: nil, forEndpoint: endpointName)
            self.tableView.reloadData()
        })

        present(alert, animated: true)
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

extension MoyaStubberViewController {
    public override func numberOfSections(in tableView: UITableView) -> Int {
        2
    }

    public override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        section == 0 ? nil : "Stubs"
    }

    public override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        section == 0 ? 1 : stubber.stubbableEndpoints.count
    }

    public override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "DetailLabelCell") as? DetailLabelCell else {
            fatalError("Could not dequeue cell")
        }

        if indexPath.section == 0 {
            cell.configure(forDelay: stubber.delay)
        } else {
            let endpointName = stubber.stubbableEndpoints[indexPath.row].name
            let stub = stubber.activeStub(forEndpointName: endpointName)
            cell.configure(forStub: stub, endpointName: endpointName )
        }

        return cell
    }
}

// MARK: - UITableViewDelegate

extension MoyaStubberViewController {
    public override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            showDelayPicker()
        } else {
            let item = stubber.stubbableEndpoints[indexPath.row]
            showStubPicker(forEndpointName: item.name, availableStubs: item.availableStubs)
        }
    }
}

// MARK: - Cells

private class DetailLabelCell: UITableViewCell {
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .value1, reuseIdentifier: reuseIdentifier)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        backgroundColor = .white
    }

    func configure(forStub stub: Stub?, endpointName: String) {
        textLabel?.text = endpointName
        detailTextLabel?.text = stub?.displayName

        if stub != nil {
            backgroundColor = UIColor.systemBlue.withAlphaComponent(0.1)
        }
    }

    func configure(forDelay delay: TimeInterval) {
        textLabel?.text = "Stub response delay"
        detailTextLabel?.text = "\(delay) seconds"
    }
}

#endif
