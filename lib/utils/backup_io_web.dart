import 'dart:html' as html;

Future<String> saveBackupFile(String filename, String contents) async {
  final blob = html.Blob([contents], 'application/json');
  final url = html.Url.createObjectUrlFromBlob(blob);

  // ignore: unused_local_variable
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', filename)
    ..click();

  html.Url.revokeObjectUrl(url);
  return filename;
}

Future<void> openDirectory(String path) async {
  // Not supported on web.
}

bool get canOpenDirectory => false;
