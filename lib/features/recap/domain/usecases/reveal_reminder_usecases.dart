import 'package:momen/features/recap/domain/entities/reveal_reminder.dart';
import 'package:momen/features/recap/domain/repositories/memories_repository.dart';

class GetPendingRevealRemindersUseCase {
  const GetPendingRevealRemindersUseCase(this._repository);

  final MemoriesRepository _repository;

  Future<List<RevealReminder>> call() {
    return _repository.getPendingRevealReminders();
  }
}

class ResolveRevealReminderUseCase {
  const ResolveRevealReminderUseCase(this._repository);

  final MemoriesRepository _repository;

  Future<void> call({
    required String reminderId,
    required bool reveal,
  }) {
    return _repository.resolveRevealReminder(
      reminderId: reminderId,
      reveal: reveal,
    );
  }
}
