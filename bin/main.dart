import 'dart:io';
import 'dart:convert';

void main(List<String> args) async {
  if (args.length == 1 && args[0] == "upload") {
    print("upload command needs an file <argument>");
  } else if (args.length >= 2 && args[0] == "upload" && args[1].isNotEmpty) {
    final file = File(args[1]);
    if (await file.exists()) {
      await uploadFile(file);
    } else {
      print("- Error: Chose a valid file.");
    }
  } else if (args.isEmpty) {
    File('lib/help.txt').readAsString().then((String contents) {
      print(contents);
    });
  } else if (args.length == 1 && args[0] != "upoload") {
    print("\n- Error chose a valid command. \n");
    File('lib/help.txt').readAsString().then((String contents) {
      print(contents);
    });
  }
}

Future<void> uploadFile(File file) async {
  try {
    final boundary = '--${DateTime.now().millisecondsSinceEpoch}';

    final request =
        await HttpClient().postUrl(Uri.parse('https://tmpfiles.org/api/v1/upload'));
    request.headers
        .set(HttpHeaders.contentTypeHeader, 'multipart/form-data; boundary=$boundary');

    final buffer = StringBuffer();
    buffer.writeln(
        '--$boundary\r\nContent-Disposition: form-data; name="file"; filename="${file.path}"\r\nContent-Type: application/octet-stream\r\n\r\n');
    buffer.write(await file.readAsString());
    buffer.writeln('\r\n--$boundary--\r\n');

    request.add(utf8.encode(buffer.toString()));
    final response = await request.close();

    if (response.statusCode == 200) {
      final data = await response.transform(utf8.decoder).join();
      final json = JsonDecoder().convert(data);
      print("+ Status: ${json['status']}");
      print("+ Url: ${json['data']['url']}");
      exit(0);
    } else {
      print('Error uploading file: ${response.statusCode}');
      exit(0);
    }
  } catch (e) {
    print(e);
    exit(0);
  }
}
