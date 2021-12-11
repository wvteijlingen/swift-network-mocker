#if canImport(UIKit)

import UIKit

class DetailLabelCell: UITableViewCell {
  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: .value1, reuseIdentifier: reuseIdentifier)
    prepareForReuse()
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func prepareForReuse() {
    super.prepareForReuse()
    textLabel?.text = nil
    detailTextLabel?.text = nil
    accessoryType = .none
  }
}

class DestructiveCell: UITableViewCell {
  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: .default, reuseIdentifier: reuseIdentifier)
    prepareForReuse()
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func prepareForReuse() {
    super.prepareForReuse()
    textLabel?.text = nil
    textLabel?.textColor = .systemRed
    detailTextLabel?.text = nil
    accessoryType = .none
  }
}

#endif
