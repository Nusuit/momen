import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

class LocalDatabaseService {
  Isar? _instance;

  Future<Isar> open({
    required List<CollectionSchema<dynamic>> schemas,
    String name = Isar.defaultName,
  }) async {
    final current = _instance;
    if (current != null && current.isOpen) {
      return current;
    }

    final directory = await getApplicationDocumentsDirectory();
    final isar = await Isar.open(
      schemas,
      directory: directory.path,
      name: name,
    );

    _instance = isar;
    return isar;
  }

  Future<void> close() async {
    final current = _instance;
    if (current == null || !current.isOpen) {
      return;
    }

    await current.close();
    _instance = null;
  }
}
