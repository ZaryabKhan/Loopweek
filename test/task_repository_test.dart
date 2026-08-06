import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loopweek/data/database/database.dart';
import 'package:loopweek/data/repositories/task_repository.dart';
import 'package:loopweek/domain/models/task.dart';

DateTime _d(int y, int m, int d) => DateTime(y, m, d);

Task _task(String id, DateTime date) => Task(id: id, title: id, date: date);

void main() {
  late LoopweekDatabase db;
  late TaskRepository repo;

  setUp(() {
    db = LoopweekDatabase.forTesting(NativeDatabase.memory());
    repo = TaskRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('watchTasksForDate', () {
    test('task at exact midnight appears only on its own day', () async {
      // Aug 8 2026 is a Saturday; a time-less task is stored at Sat 00:00:00.
      await repo.insertTask(_task('sat', _d(2026, 8, 8)));

      final friday = await repo.watchTasksForDate(_d(2026, 8, 7)).first;
      final saturday = await repo.watchTasksForDate(_d(2026, 8, 8)).first;

      expect(friday.map((t) => t.id), isNot(contains('sat')));
      expect(saturday.map((t) => t.id), contains('sat'));
    });

    test('task on Friday does not leak into Saturday', () async {
      await repo.insertTask(_task('fri', _d(2026, 8, 7)));

      final friday = await repo.watchTasksForDate(_d(2026, 8, 7)).first;
      final saturday = await repo.watchTasksForDate(_d(2026, 8, 8)).first;

      expect(friday.map((t) => t.id), contains('fri'));
      expect(saturday.map((t) => t.id), isNot(contains('fri')));
    });

    test('task with a time still stays on its own day', () async {
      final t = _task('sat', _d(2026, 8, 8));
      await repo.insertTask(t);

      final friday = await repo.watchTasksForDate(_d(2026, 8, 7)).first;
      expect(friday, isEmpty);
    });
  });
}
