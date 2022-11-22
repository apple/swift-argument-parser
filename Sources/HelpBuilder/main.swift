//
//  File.swift
//  
//
//  Created by Rauhul Varma on 11/22/22.
//

var e = [1, 2, 3, 4]

let x = Help(
  abstract: "Generate a manual for the provided tool.",
  discussion: """
  The generate-manual tool powers the generate-manual plugin and typically should not be directly invoked. Instead manuals should be generated using the plugin which can be invoked via `swift package generate-manual`.
  """,
  usage: """
  generate-manual <tool> [--multi-page] [--date <date>] [--section <section>] [--authors <authors> ...] --output-directory <output-directory
  """)

print(x.rendered)
