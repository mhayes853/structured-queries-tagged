import Foundation
import StructuredQueries
import StructuredQueriesSQLite
import StructuredQueriesTagged

@Table
struct Reminder: Equatable, Identifiable {
  typealias ID = Tagged<Self, UUID>
  typealias IDRepresentation = Tagged<Self, UUID.BytesRepresentation>

  static let incomplete = Self.where { !$0.isCompleted }

  @Column(as: IDRepresentation.self)
  let id: ID
  var assignedUserID: User.ID?
  @Column(as: Date.ISO8601Representation?.self)
  var dueDate: Date?
  var isCompleted = false
  var isFlagged = false
  var notes = ""
  var priority: Priority?
  var title = ""

  static func searching(_ text: String) -> Where<Reminder> {
    Self.where {
      $0.title.collate(.nocase).contains(text)
        || $0.notes.collate(.nocase).contains(text)
    }
  }
}

@Table
struct User: Equatable, Identifiable {
  typealias ID = Tagged<Self, Int>

  let id: ID
  var name = ""
}

enum Priority: Int, QueryBindable {
  case low = 1
  case medium
  case high
}

extension Reminder.TableColumns {
  var isPastDue: some QueryExpression<Bool> {
    !isCompleted && #sql("coalesce(\(dueDate), date('now')) < date('now')")
  }
}

extension Database {
  static func `default`() throws -> Database {
    let db = try Database()
    try db.migrate()
    try db.createMockData()
    return db
  }

  func migrate() throws {
    try execute(
      """
      CREATE TABLE "reminders" (
        "id" BLOB PRIMARY KEY NOT NULL,
        "assignedUserID" INTEGER,
        "dueDate" DATE,
        "isCompleted" BOOLEAN NOT NULL DEFAULT 0,
        "isFlagged" BOOLEAN NOT NULL DEFAULT 0,
        "notes" TEXT NOT NULL DEFAULT '',
        "priority" INTEGER,
        "title" TEXT NOT NULL DEFAULT ''
      )
      """
    )
    try execute(
      """
      CREATE TABLE "users" (
        "id" INTEGER PRIMARY KEY AUTOINCREMENT,
        "name" TEXT NOT NULL DEFAULT ''
      )
      """
    )
  }

  func createMockData() throws {
    try createDebugUsers()
    try createDebugReminders()
  }

  func createDebugUsers() throws {
    try execute(
      User.insert {
        $0.name
      } values: {
        "Blob"
        "Blob Jr"
        "Blob Sr"
      }
    )
  }

  func createDebugReminders() throws {
    let now = Date(timeIntervalSinceReferenceDate: 0)
    try execute(
      Reminder.insert([
        Reminder(
          id: Reminder.ID(intValue: 0),
          assignedUserID: 1,
          dueDate: now,
          notes: """
            Milk, Eggs, Apples
            """,
          title: "Groceries"
        ),
        Reminder(
          id: Reminder.ID(intValue: 1),
          dueDate: now.addingTimeInterval(-60 * 60 * 24 * 2),
          isFlagged: true,
          title: "Haircut"
        ),
        Reminder(
          id: Reminder.ID(intValue: 2),
          dueDate: now,
          notes: "Ask about diet",
          priority: .high,
          title: "Doctor appointment"
        ),
        Reminder(
          id: Reminder.ID(intValue: 3),
          dueDate: now.addingTimeInterval(-60 * 60 * 24 * 190),
          isCompleted: true,
          title: "Take a walk"
        ),
        Reminder(
          id: Reminder.ID(intValue: 4),
          title: "Buy concert tickets"
        ),
        Reminder(
          id: Reminder.ID(intValue: 5),
          assignedUserID: 2,
          dueDate: now.addingTimeInterval(60 * 60 * 24 * 2),
          isFlagged: true,
          priority: .high,
          title: "Pick up kids from school"
        ),
        Reminder(
          id: Reminder.ID(intValue: 6),
          dueDate: now.addingTimeInterval(-60 * 60 * 24 * 2),
          isCompleted: true,
          priority: .low,
          title: "Get laundry"
        ),
        Reminder(
          id: Reminder.ID(intValue: 7),
          dueDate: now.addingTimeInterval(60 * 60 * 24 * 4),
          isCompleted: false,
          priority: .high,
          title: "Take out trash"
        ),
        Reminder(
          id: Reminder.ID(intValue: 8),
          assignedUserID: 3,
          dueDate: now.addingTimeInterval(60 * 60 * 24 * 2),
          notes: """
            Status of tax return
            Expenses for next year
            Changing payroll company
            """,
          title: "Call accountant"
        ),
        Reminder(
          id: Reminder.ID(intValue: 9),
          assignedUserID: 3,
          dueDate: now.addingTimeInterval(-60 * 60 * 24 * 2),
          isCompleted: true,
          priority: .medium,
          title: "Send weekly emails"
        )
      ])
    )
  }
}

extension Reminder.ID {
  init(intValue: Int) {
    self.init(uuidString: "00000000-0000-0000-0000-\(String(format: "%012x", intValue))")!
  }
}

