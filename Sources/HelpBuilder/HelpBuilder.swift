
extension String {
  var indented: String {
    self.split(separator: "\n").map { "  \($0)" }.joined(separator: "\n")
  }
}

protocol HelpComponent {
  @HelpBuilder
  var body: HelpComponent { get }
  var rendered: String { get }
  var hierarchicalDebugDescription: String { get }
}

extension HelpComponent {
  var body: HelpComponent { self }
  var rendered: String { body.rendered }
  var hierarchicalDebugDescription: String {
    return "\(Self.self).\(body.hierarchicalDebugDescription)"
  }
}

@resultBuilder
struct HelpBuilder {
  static func buildBlock(_ components: HelpComponent...) -> HelpComponent {
    Container(children: components)
      .dynamic(wrapSingleChild: false)
  }

  static func buildArray(_ components: [HelpComponent]) -> HelpComponent {
    Container(children: components)
      .dynamic(wrapSingleChild: false)
  }

  static func buildOptional(_ component: HelpComponent?) -> HelpComponent {
    component ?? Empty()
  }

  static func buildEither(first component: HelpComponent) -> HelpComponent {
    component
  }

  static func buildEither(second component: HelpComponent) -> HelpComponent {
    component
  }

  static func buildExpression(_ expression: HelpComponent) -> HelpComponent {
    expression
  }
}

extension Never: HelpComponent { }

struct Empty { }

extension Empty: HelpComponent {
  var rendered: String { "" }
  var hierarchicalDebugDescription: String {
    return "Empty()"
  }
}

struct Container {
  var children: [HelpComponent]

  init(children: [HelpComponent]) {
//    let allNonEmpty = children.allSatisfy {
//      guard $0 is Empty else { return true }
//      return false
//    }
//    precondition(allNonEmpty)
    // precondition(!children.isEmpty)
    self.children = children
  }

  init(@HelpBuilder _ child: () -> HelpComponent) {
    self.init(children: [child()])
  }
}

extension Container {
  func `dynamic`(wrapSingleChild: Bool) -> HelpComponent {
    let nonEmptyChildren = children
      // .map { $0.body }
      .filter {
        guard $0 is Empty else { return true }
        return false
      }

    switch (nonEmptyChildren.count, wrapSingleChild) {
    case (0, _):
      // print("\(children) -> Empty()")
      return Empty()
    case (1, false):
      // print("\(children) -> \(type(of: nonEmptyChildren[0]))")
      return nonEmptyChildren[0]
    default:
      // print("\(children) -> Container(children: \(nonEmptyChildren))")
      return Container(children: nonEmptyChildren)
    }
  }
}

extension Container: HelpComponent {
  var rendered: String {
    // If two Text or Container elements appear sequentially insert two line
    // breaks between them.
    var previousChild: HelpComponent?
    var rendered = ""
    for child in children {
      let child = child.body
      defer { previousChild = child }
      switch (child, previousChild) {
      case (is Text, is Text):
        rendered += "\n"
      case (is Container, is Container):
        rendered += "\n"
      default:
        break
      }
      rendered += child.rendered
    }
    return rendered
  }
  var hierarchicalDebugDescription: String {
    let childrenDescription = children
      .map(\.hierarchicalDebugDescription)
      .joined(separator: ",\n")
      .indented
    return "Container([\n\(childrenDescription)\n])"
  }
}

struct ForEach<C> where C: Collection {
  var items: C
  var builder: (C.Element) -> HelpComponent

  init(_ items: C, @HelpBuilder builder: @escaping (C.Element) -> HelpComponent) {
    self.items = items
    self.builder = builder
  }
}

extension ForEach: HelpComponent {
  var body: HelpComponent {
    let children = self.items
      .map(self.builder)
      .map(\.body)
    return Container(children: children)
      .dynamic(wrapSingleChild: false)
  }
}

struct Text {
  var string: String
  var terminator: String

  init(_ string: String, terminator: String = "\n") {
    self.string = string
    self.terminator = terminator
  }
}

extension Text: HelpComponent {
  var rendered: String { string + terminator }
  var hierarchicalDebugDescription: String { "Text(\"\(string)\")" }
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
    let contents = Container(children: [contents()])
      .dynamic(wrapSingleChild: true)
    if contents.body is Empty {
      Empty()
    } else {
      Text(title.uppercased() + ":")
      contents
    }
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
      if self.discussion != "" {
        Text(self.discussion)
      }
    }

    Container {
      Text("USAGE: \(self.usage)")
    }

    ForEach(["abcd", "foo", "bar"]) { title in
      Section(title: title) {
        Text("Some content")
      }
    }

    Section(title: "Arguments") {

    }

    Section(title: "Options") {

    }
  }
}
