import 'dart:html' as html;

Future<void> triggerBrowserDownload(String url, String fileName) async {
  try {
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', fileName)
      ..target = '_blank';
    html.document.body?.append(anchor);
    anchor.click();
    anchor.remove();
  } catch (e) {
    print('❌ Browser download error: $e');
    rethrow;
  }
}
