
protocol HelpComponent {
  @HelpBuilder
  var body: HelpComponent { get }
  var rendered: String { get }
}

extension HelpComponent {
  var body: HelpComponent { fatalError() }
  var rendered: String { body.rendered }
}

@resultBuilder
struct HelpBuilder {
  static func buildBlock(_ components: HelpComponent...) -> HelpComponent { Container(children: components) }
  static func buildArray(_ components: [HelpComponent]) -> HelpComponent { Container(children: components) }
  static func buildOptional(_ component: HelpComponent?) -> HelpComponent { component ?? Empty() }
  static func buildEither(first component: HelpComponent) -> HelpComponent { component }
  static func buildEither(second component: HelpComponent) -> HelpComponent { component }
  static func buildExpression(_ expression: HelpComponent) -> HelpComponent { expression }
}

extension Never: HelpComponent { }

struct Empty { }

extension Empty: HelpComponent {
  var rendered: String { "" }
}

struct Container {
  var children: [HelpComponent]
}

extension Container: HelpComponent {
  var rendered: String {
    self
      .children
      .map { $0.rendered }
      .filter { $0 != "" }
      .joined(separator: "")
  }
}

struct ForEach<C> where C: Collection {
  var items: C
  var builder: (C.Element, C.Index) -> HelpComponent

  init(_ items: C, @HelpBuilder builder: @escaping (C.Element, C.Index) -> HelpComponent) {
    self.items = items
    self.builder = builder
  }
}

extension ForEach: HelpComponent {
  var body: HelpComponent {
    guard !items.isEmpty else { return Empty() }
    var currentIndex = items.startIndex
    var components = [HelpComponent]()
    while currentIndex < items.endIndex {
      let item = items[currentIndex]
      components.append(builder(item, currentIndex))
      currentIndex = items.index(after: currentIndex)
    }
    return Container(children: components)
  }
}

struct LineBreak { }

extension LineBreak: HelpComponent {
  var body: HelpComponent { Text("\n") }
}

struct Text {
  var string: String

  init(_ string: String) {
    self.string = string
  }
}

extension Text: HelpComponent {
  var rendered: String { string }
}


struct Section {
  var title: String
  var contents: () -> HelpComponent

  init(title: String, @HelpBuilder contents: @escaping () -> HelpComponent) {
    self.title = title
    self.contents = contents
  }
}

extension Section: HelpComponent {
  var body: HelpComponent {
    Text(title.uppercased() + ":")
    LineBreak()
    contents()
  }
}

struct Help {
  var abstract: String
  var discussion: String
  var usage: String
}

extension Help: HelpComponent {
  var body: HelpComponent {
    Section(title: "Overview") {
      if self.abstract != "" {
        Text(self.abstract)
      }
      if self.abstract != "", self.discussion != "" {
        LineBreak()
        LineBreak()
      }
      if self.discussion != "" {
        Text(self.discussion)
      }
    }

    LineBreak()
    LineBreak()

    Text("USAGE: \(self.usage)")

    LineBreak()
    LineBreak()

    ForEach(["abcd", "foo", "bar"]) { title, _ in
      Section(title: title) {
        Text("Some content")
      }

      LineBreak()
      LineBreak()
    }

    Section(title: "Arguments") {

    }

    LineBreak()
    LineBreak()

    Section(title: "Options") {

    }
  }
}
