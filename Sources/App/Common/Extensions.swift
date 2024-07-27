extension MutableCollection {
    func associateBy<Key>(_ selector: KeyPath<Element, Key>) -> [Key: Element] {
        reduce(into: [Key: Element]()) { dict, value in
            dict[value[keyPath: selector]] = value
        }
    }
}