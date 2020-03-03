public protocol EnumerableFlag: CaseIterable, Equatable {
  static func name(for value: Self) -> NameSpecification
}

extension EnumerableFlag {
  public static func name(for value: Self) -> NameSpecification {
    .long
  }
}
