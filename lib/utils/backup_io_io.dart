import 'dart:io';
import 'package:path_provider/path_provider.dart';

Future<String> saveBackupFile(String filename, String contents) async {
  Directory dir;
  try {
    dir = await getApplicationDocumentsDirectory();
  } catch (_) {
    dir = Directory.systemTemp;
  }
  final file = File('${dir.path}${Platform.pathSeparator}$filename');
  await file.writeAsString(contents);
  return file.path;
}

Future<void> openDirectory(String path) async {
  try {
    if (Platform.isWindows) {
      await Process.run('explorer', [path]);
    } else if (Platform.isMacOS) {
      await Process.run('open', [path]);
    } else if (Platform.isLinux) {
      await Process.run('xdg-open', [path]);
    }
  } catch (_) {
    // ignore
  }
}

bool get canOpenDirectory =>
    Platform.isWindows || Platform.isMacOS || Platform.isLinux;
