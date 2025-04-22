import Foundation
import StructuredQueriesSQLite
import StructuredQueriesTagged
import StructuredQueriesTestSupport
import Testing

@Suite("Tagged+StructuredQueries tests")
struct TaggedStructuredQueriesTests {
  private let database = try! Database.default()
  
  @Test("Select Reminders")
  func selectReminders() {
    self.assertQuery(Reminder.select { ($0.id, $0.title) }) {
      """
      SELECT "reminders"."id", "reminders"."title"
      FROM "reminders"
      """
    } results: {
      """
      ┌──────────────────────────────────────────────────────────────┬────────────────────────────┐
      │ Tagged(rawValue: UUID(00000000-0000-0000-0000-000000000000)) │ "Groceries"                │
      │ Tagged(rawValue: UUID(00000000-0000-0000-0000-000000000001)) │ "Haircut"                  │
      │ Tagged(rawValue: UUID(00000000-0000-0000-0000-000000000002)) │ "Doctor appointment"       │
      │ Tagged(rawValue: UUID(00000000-0000-0000-0000-000000000003)) │ "Take a walk"              │
      │ Tagged(rawValue: UUID(00000000-0000-0000-0000-000000000004)) │ "Buy concert tickets"      │
      │ Tagged(rawValue: UUID(00000000-0000-0000-0000-000000000005)) │ "Pick up kids from school" │
      │ Tagged(rawValue: UUID(00000000-0000-0000-0000-000000000006)) │ "Get laundry"              │
      │ Tagged(rawValue: UUID(00000000-0000-0000-0000-000000000007)) │ "Take out trash"           │
      │ Tagged(rawValue: UUID(00000000-0000-0000-0000-000000000008)) │ "Call accountant"          │
      │ Tagged(rawValue: UUID(00000000-0000-0000-0000-000000000009)) │ "Send weekly emails"       │
      └──────────────────────────────────────────────────────────────┴────────────────────────────┘
      """
    }
  }
  
  @Test("Left Join")
  func leftJoin() {
    self.assertQuery(
      Reminder
        .order { $0.dueDate.desc() }
        .join(User.all) { $0.assignedUserID.eq($1.id) }
        .select { ($0.title, $1.name) }
    ) {
      """
      SELECT "reminders"."title", "users"."name"
      FROM "reminders"
      JOIN "users" ON ("reminders"."assignedUserID" = "users"."id")
      ORDER BY "reminders"."dueDate" DESC
      """
    } results: {
      """
      ┌────────────────────────────┬───────────┐
      │ "Pick up kids from school" │ "Blob Jr" │
      │ "Call accountant"          │ "Blob Sr" │
      │ "Groceries"                │ "Blob"    │
      │ "Send weekly emails"       │ "Blob Sr" │
      └────────────────────────────┴───────────┘
      """
    }
  }
  
  @Test("Insert Basics")
  func basics() {
    let id1 = Reminder.ID(uuidString: "5D45F24C-D1AF-4981-B8F4-8BC46DF9F72C")!
    let id2 = Reminder.ID(uuidString: "EA4DF179-90EA-4911-96E3-B465FC2AB76B")!
    assertQuery(
      Reminder.insert {
        ($0.id, $0.title, $0.isCompleted, $0.dueDate, $0.priority)
      } values: {
        (id1, "Groceries", true, Date(timeIntervalSinceReferenceDate: 0), .high)
        (id2, "Haircut", false, Date(timeIntervalSince1970: 0), .low)
      } onConflict: {
        $0.title += " Copy"
      }
        .returning(\.self)
    ) {
      #"""
      INSERT INTO "reminders"
      ("id", "title", "isCompleted", "dueDate", "priority")
      VALUES
      (']E�LѯI����m��,', 'Groceries', 1, '2001-01-01 00:00:00.000', 3), ('�M�y��I\u{11}��e�*�k', 'Haircut', 0, '1970-01-01 00:00:00.000', 1)
      ON CONFLICT DO UPDATE SET "title" = ("reminders"."title" || ' Copy')
      RETURNING "id", "assignedUserID", "dueDate", "isCompleted", "isFlagged", "notes", "priority", "title"
      """#
    } results: {
      """
      ┌─────────────────────────────────────────────────────────────────────┐
      │ Reminder(                                                           │
      │   id: Tagged(rawValue: UUID(5D45F24C-D1AF-4981-B8F4-8BC46DF9F72C)), │
      │   assignedUserID: nil,                                              │
      │   dueDate: Date(2001-01-01T00:00:00.000Z),                          │
      │   isCompleted: true,                                                │
      │   isFlagged: false,                                                 │
      │   notes: "",                                                        │
      │   priority: .high,                                                  │
      │   title: "Groceries"                                                │
      │ )                                                                   │
      ├─────────────────────────────────────────────────────────────────────┤
      │ Reminder(                                                           │
      │   id: Tagged(rawValue: UUID(EA4DF179-90EA-4911-96E3-B465FC2AB76B)), │
      │   assignedUserID: nil,                                              │
      │   dueDate: Date(1970-01-01T00:00:00.000Z),                          │
      │   isCompleted: false,                                               │
      │   isFlagged: false,                                                 │
      │   notes: "",                                                        │
      │   priority: .low,                                                   │
      │   title: "Haircut"                                                  │
      │ )                                                                   │
      └─────────────────────────────────────────────────────────────────────┘
      """
    }
  }
  
  @Test("Basic Update")
  func basicUpdate() {
    self.assertQuery(
      Reminder
        .update { $0.isCompleted.toggle() }
        .returning { ($0.title, $0.priority, $0.isCompleted) }
    ) {
      """
      UPDATE "reminders"
      SET "isCompleted" = NOT ("reminders"."isCompleted")
      RETURNING "title", "priority", "isCompleted"
      """
    } results: {
      """
      ┌────────────────────────────┬─────────┬───────┐
      │ "Groceries"                │ nil     │ true  │
      │ "Haircut"                  │ nil     │ true  │
      │ "Doctor appointment"       │ .high   │ true  │
      │ "Take a walk"              │ nil     │ false │
      │ "Buy concert tickets"      │ nil     │ true  │
      │ "Pick up kids from school" │ .high   │ true  │
      │ "Get laundry"              │ .low    │ false │
      │ "Take out trash"           │ .high   │ true  │
      │ "Call accountant"          │ nil     │ true  │
      │ "Send weekly emails"       │ .medium │ false │
      └────────────────────────────┴─────────┴───────┘
      """
    }
    self.assertQuery(
      Reminder
        .where { $0.priority == nil }
        .update { $0.isCompleted = true }
        .returning { ($0.title, $0.priority, $0.isCompleted) }
    ) {
      """
      UPDATE "reminders"
      SET "isCompleted" = 1
      WHERE ("reminders"."priority" IS NULL)
      RETURNING "title", "priority", "isCompleted"
      """
    } results: {
      """
      ┌───────────────────────┬─────┬──────┐
      │ "Groceries"           │ nil │ true │
      │ "Haircut"             │ nil │ true │
      │ "Take a walk"         │ nil │ true │
      │ "Buy concert tickets" │ nil │ true │
      │ "Call accountant"     │ nil │ true │
      └───────────────────────┴─────┴──────┘
      """
    }
  }
  
  @Test("Primary Key Update")
  func primaryKeyUpdate() throws {
    var reminder = try #require(try self.database.execute(Reminder.all).first)
    reminder.isCompleted.toggle()
    self.assertQuery(
      Reminder
        .update(reminder)
        .returning(\.self)
    ) {
      #"""
      UPDATE "reminders"
      SET "assignedUserID" = 1, "dueDate" = '2001-01-01 00:00:00.000', "isCompleted" = 1, "isFlagged" = 0, "notes" = 'Milk, Eggs, Apples', "priority" = NULL, "title" = 'Groceries'
      WHERE ("reminders"."id" = '\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0')
      RETURNING "id", "assignedUserID", "dueDate", "isCompleted", "isFlagged", "notes", "priority", "title"
      """#
    } results: {
      """
      ┌─────────────────────────────────────────────────────────────────────┐
      │ Reminder(                                                           │
      │   id: Tagged(rawValue: UUID(00000000-0000-0000-0000-000000000000)), │
      │   assignedUserID: Tagged(rawValue: 1),                              │
      │   dueDate: Date(2001-01-01T00:00:00.000Z),                          │
      │   isCompleted: true,                                                │
      │   isFlagged: false,                                                 │
      │   notes: "Milk, Eggs, Apples",                                      │
      │   priority: nil,                                                    │
      │   title: "Groceries"                                                │
      │ )                                                                   │
      └─────────────────────────────────────────────────────────────────────┘
      """
    }
  }
  
  @Test("Delete By ID")
  func deleteById() {
    self.assertQuery(
      Reminder.delete()
        .where { $0.id == #bind(Reminder.ID(intValue: 1)) }
        .returning(\.self)
    ) {
      #"""
      DELETE FROM "reminders"
      WHERE ("reminders"."id" = '\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\u{01}')
      RETURNING "id", "assignedUserID", "dueDate", "isCompleted", "isFlagged", "notes", "priority", "title"
      """#
    } results: {
      """
      ┌─────────────────────────────────────────────────────────────────────┐
      │ Reminder(                                                           │
      │   id: Tagged(rawValue: UUID(00000000-0000-0000-0000-000000000001)), │
      │   assignedUserID: nil,                                              │
      │   dueDate: Date(2000-12-30T00:00:00.000Z),                          │
      │   isCompleted: false,                                               │
      │   isFlagged: true,                                                  │
      │   notes: "",                                                        │
      │   priority: nil,                                                    │
      │   title: "Haircut"                                                  │
      │ )                                                                   │
      └─────────────────────────────────────────────────────────────────────┘
      """
    }
    self.assertQuery(Reminder.count()) {
      """
      SELECT count(*)
      FROM "reminders"
      """
    } results: {
      """
      ┌───┐
      │ 9 │
      └───┘
      """
    }
  }
  
  private func assertQuery<each V: QueryRepresentable>(
    _ query: some Statement<(repeat each V)>,
    sql: (() -> String)? = nil,
    results: (() -> String)? = nil,
    fileID: StaticString = #fileID,
    filePath: StaticString = #filePath,
    function: StaticString = #function,
    line: UInt = #line,
    column: UInt = #column
  ) {
    StructuredQueriesTestSupport.assertQuery(
      query,
      execute: self.database.execute,
      sql: sql,
      results: results,
      snapshotTrailingClosureOffset: 0,
      fileID: fileID,
      filePath: filePath,
      function: function,
      line: line,
      column: column
    )
  }
  
}
