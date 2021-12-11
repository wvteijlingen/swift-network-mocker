import Foundation

extension URL {
  var isDirectory: Bool {
    let attributes = try? FileManager.default.attributesOfItem(atPath: path)
    if let type = attributes?[FileAttributeKey.type] as? FileAttributeType {
      return type == FileAttributeType.typeDirectory
    } else {
      return false
    }
  }

  var isFile: Bool {
    !isDirectory
  }
}

extension FileManager {
  func shallowEnumerator(at url: URL) throws -> AnySequence<URL> {
    guard let enumerator = enumerator(
      at: url,
      includingPropertiesForKeys: nil,
      options: [.skipsHiddenFiles, .skipsSubdirectoryDescendants]
    ) else {
      throw MoyaStubberError.couldNotEnumerate(url: url)
    }

    return AnySequence(enumerator.lazy.compactMap { $0 as? URL })
  }
}

extension Array {
  subscript (safe index: Int) -> Element? {
    indices.contains(index) ? self[index] : nil
  }
}
