import Foundation
import SwiftData

/// ルーティン（事前定義のトレーニングメニュー）の書き込み操作。
///
/// 単純なリスト読み取りは SwiftUI 側で `@Query` を直接使う方が早い。
/// ここでは create / edit / delete / 利用記録の更新を提供する。
@MainActor
public final class RoutineRepository {

    private let context: ModelContext

    public init(context: ModelContext) {
        self.context = context
    }

    /// 新規ルーティンを作成する。
    ///
    /// `exercises` の順で `RoutineExercise` を生成し、`order` は配列の index を採用する。
    /// Free プランで上限 (`ProGate.freeRoutineLimit`) に達していると `ProGateError` を投げる。
    @discardableResult
    public func createRoutine(name: String, exercises: [Exercise] = []) throws -> Routine {
        if !ProGate.canCreateUnlimitedRoutines {
            let existing = try context.fetchCount(FetchDescriptor<Routine>())
            if existing >= ProGate.freeRoutineLimit {
                throw ProGateError.routineLimitReached(current: existing, limit: ProGate.freeRoutineLimit)
            }
        }
        let routine = Routine(name: name)
        context.insert(routine)
        for (index, exercise) in exercises.enumerated() {
            let entry = RoutineExercise(
                routine: routine,
                exercise: exercise,
                order: index,
                plannedSets: 3,
                plannedReps: 8,
                plannedWeight: nil
            )
            context.insert(entry)
        }
        try context.save()
        WCSyncBridge.shared.sendRoutineUpsert(routine)
        return routine
    }

    /// ルーティンに種目を追加する。末尾に並ぶ。
    @discardableResult
    public func addExercise(
        to routine: Routine,
        exercise: Exercise,
        plannedSets: Int = 3,
        plannedReps: Int = 8,
        plannedWeight: Double? = nil,
        plannedRestSeconds: Int? = nil
    ) throws -> RoutineExercise {
        let nextOrder = (routine.exercises ?? []).map(\.order).max().map { $0 + 1 } ?? 0
        let entry = RoutineExercise(
            routine: routine,
            exercise: exercise,
            order: nextOrder,
            plannedSets: plannedSets,
            plannedReps: plannedReps,
            plannedWeight: plannedWeight,
            plannedRestSeconds: plannedRestSeconds
        )
        context.insert(entry)
        try context.save()
        WCSyncBridge.shared.sendRoutineUpsert(routine)
        return entry
    }

    /// 指定の `RoutineExercise` を削除する。残りの order を詰める。
    public func removeExercise(_ routineExercise: RoutineExercise) throws {
        guard let routine = routineExercise.routine else {
            context.delete(routineExercise)
            try context.save()
            return
        }
        let removedOrder = routineExercise.order
        context.delete(routineExercise)
        // 同一ルーティン内で、削除した位置より後ろの要素を1つずつ詰める
        for entry in (routine.exercises ?? []) where entry.order > removedOrder {
            entry.order -= 1
        }
        try context.save()
        WCSyncBridge.shared.sendRoutineUpsert(routine)
    }

    /// ルーティン内の種目を任意順に並べ替える。
    ///
    /// - Parameter orderedIds: `RoutineExercise.id` を希望の順序で並べた配列
    public func reorderExercises(in routine: Routine, orderedIds: [UUID]) throws {
        let entries = routine.exercises ?? []
        let byId = Dictionary(uniqueKeysWithValues: entries.map { ($0.id, $0) })
        for (newIndex, id) in orderedIds.enumerated() {
            byId[id]?.order = newIndex
        }
        try context.save()
        WCSyncBridge.shared.sendRoutineUpsert(routine)
    }

    /// ルーティンの名前を変更する。
    public func renameRoutine(_ routine: Routine, to newName: String) throws {
        routine.name = newName
        try context.save()
        WCSyncBridge.shared.sendRoutineUpsert(routine)
    }

    /// ルーティンを削除する。関連する `RoutineExercise` は cascade で削除される。
    public func deleteRoutine(_ routine: Routine) throws {
        let id = routine.id
        context.delete(routine)
        try context.save()
        WCSyncBridge.shared.sendRoutineDeleted(id)
    }

    /// セッション開始時に呼び出して、ルーティンの最終利用日時を更新する。
    public func markUsed(_ routine: Routine, at date: Date = Date()) throws {
        routine.lastUsedAt = date
        try context.save()
        WCSyncBridge.shared.sendRoutineUpsert(routine)
    }

    /// 指定曜日 (`Calendar.Component.weekday` の 1=日 ... 7=土) に予定されているルーティンを返す。
    /// `scheduledWeekdays` が空のルーティン (任意日) は含めない。
    public func routines(forWeekday weekday: Int) throws -> [Routine] {
        let all = try context.fetch(FetchDescriptor<Routine>())
        return all.filter { $0.scheduledWeekdays.contains(weekday) }
    }

    /// `Routine.scheduledWeekdays` を差し替えて保存する。
    public func setScheduledWeekdays(_ weekdays: [Int], for routine: Routine) throws {
        routine.scheduledWeekdays = weekdays.sorted().filter { (1...7).contains($0) }
        try context.save()
        WCSyncBridge.shared.sendRoutineUpsert(routine)
    }
}
