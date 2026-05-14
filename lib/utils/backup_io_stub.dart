Future<String> saveBackupFile(String filename, String contents) async {
  throw UnsupportedError('Backup not supported on this platform.');
}

Future<void> openDirectory(String path) async {}

bool get canOpenDirectory => false;
