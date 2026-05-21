import 'sync_service.dart';

class BackgroundSyncService {
  static Future<void> sincronizarImediato() async {
    await SyncService.sincronizarAgora();
  }
}
