# StructuredQueriesTagged

A library that adds retroactive [Tagged](https://github.com/pointfreeco/swift-tagged) support for [StructuredQueries](https://github.com/pointfreeco/swift-structured-queries).

## Overview

StructuredQueries is a powerful library for writing typesafe SQL queries in pure Swift. However, we can increase the type-safety of that code by adopting Tagged into our schema. Without Tagged, it's possible to write non-sensical queries such as this.

```swift
// 🔴 Without StructuredQueriesTagged
import StructuredQueries

@Table
struct Reminder {
  let id: Int
  let assignedUserID: Int?
  let title: String
  let priority: Priority
}

@Table
struct User {
  let id: Int
  let name: String
}

// 🔴 It's nonsensical to compare User ids to Reminder ids, yet this still compiles.
let query = Reminder
  .join(User.all) { $0.assignedUserID.eq($1.id) }
  .select { ($0.title, $1.name) }
  .where { $0.id == $1.id }
```

However, with Tagged, we can ensure that these nonsensical queries are type-safe, and will not compile.

```swift
// ✅ With StructuredQueriesTagged
import StructuredQueriesTagged

@Table
struct Reminder {
  typealias ID = Tagged<Self, Int>

  let id: ID
  let assignedUserID: User.ID?
  let title: String
  let priority: Priority
}

@Table
struct User {
  typealias ID = Tagged<Self, Int>

  let id: ID
  let name: String
}

// ✅ Will not compile.
let query = Reminder
  .join(User.all) { $0.assignedUserID.eq($1.id) }
  .select { ($0.title, $1.name) }
  .where { $0.id == $1.id }
```

### Using UUID Ids

One may choose to utilize a UUID as the primary key for their table. The following shows how this can be accomplished with Tagged.

```swift
import StructuredQueriesTagged
import Foundation

@Table
struct Reminder {
  typealias ID = Tagged<Self, UUID>
  typealias IDRepresentation = Tagged<Self, UUID.BytesRepresentation>

  @Column(as: IDRepresentation.self)
  let id: ID
  let assignedUserID: User.ID?
  let title: String
  let priority: Priority
}
```

## Installation

You can add StructuredQueriesTagged to an Xcode project by adding it to your project as a package.

> https://github.com/mhayes853/structured-queries-tagged

If you want to use StructuredQueriesTagged in a [SwiftPM](https://swift.org/package-manager/) project,
it's as simple as adding it to your `Package.swift`:

``` swift
dependencies: [
  .package(url: "https://github.com/mhayes853/structured-queries-tagged", from: "0.1.1"),
]
```

And then adding the product to any target that needs access to the library:

```swift
.product(name: "StructuredQueriesTagged", package: "structured-queries-tagged"),
```
