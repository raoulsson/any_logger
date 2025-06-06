import 'constants.dart';

class LoggerStackTrace {
  const LoggerStackTrace._({
    required this.functionName,
    required this.callerFunctionName,
    required this.fileName,
    required this.lineNumber,
    required this.columnNumber,
  });

  factory LoggerStackTrace.from(StackTrace trace, {int depthOffset = 0}) {
    var callerFrameIndex = kStackDepthOfThis + depthOffset;
    final frames = trace.toString().split('\n');
    //frames.forEach((_) => print(_));
    final functionName = _getFunctionNameFromFrame(frames[callerFrameIndex]);
    final callerFunctionName =
        _getFunctionNameFromFrame(frames[callerFrameIndex + 1]);
    final fileInfo = _getFileInfoFromFrame(frames[callerFrameIndex]);

    return LoggerStackTrace._(
      functionName: functionName,
      callerFunctionName: callerFunctionName,
      fileName: fileInfo.fileName,
      lineNumber: fileInfo.lineNumber,
      columnNumber: fileInfo.column,
    );
  }

  final String functionName;
  final String callerFunctionName;
  final String fileName;
  final String lineNumber;
  final String columnNumber;

  /// Input is a single trace from the stacktrace. Should look like:
  ///
  /// #3      Client.something (file:///<path-to-project>/<project>/test/logger_stack_trace_test.dart:20:5)
  /// or
  /// #3      AppConfig._loadAppPreferences (package:base_template_project/utils/app_config.dart:55:7)
  ///
  /// But could be different, depending on platform. (that's why there is a try catch block).
  static FileInfo _getFileInfoFromFrame(String frame) {
    // root level reached
    if (frame == '<asynchronous suspension>') return FileInfo();
    try {
      final indexOfFileName = frame.indexOf('(');
      if (indexOfFileName < 0) return FileInfo(); // Return empty if format not recognized

      final rightSide = frame.substring(indexOfFileName);
      final splits = rightSide.split(':');
      if (splits.length < 3) return FileInfo(); // Not enough parts

      var fileName = splits[1];
      if (fileName.isEmpty) return FileInfo(); // Empty filename

      if (splits[0].startsWith('(package')) {
        fileName = 'package:' + fileName;
      } else {
        fileName = 'file:' + fileName;
      }

      var lineNumber = splits.length > 2 ? splits[2] : "0";
      var column = splits.length > 3 ? splits[3].replaceFirst(')', '') : "0";

      return FileInfo(fileName: fileName, lineNumber: lineNumber, column: column);
    } catch (e) {
      print('Failed to build FileInfo for frame: \n\t$frame\n');
      print(e);
      return FileInfo();
    }
  }

  static String _getFunctionNameFromFrame(String frame) {
    // root level reached
    if (frame == '<asynchronous suspension>') return '';
    try {
      final indexOfWhiteSpace = frame.indexOf(' ');
      if (indexOfWhiteSpace < 0) return '?'; // No whitespace found

      final subStr = frame.substring(indexOfWhiteSpace);
      final functionMatcher = RegExp('[A-Za-z0-9]');
      final indexOfFunction = subStr.indexOf(functionMatcher);

      if (indexOfFunction < 0) return '?'; // No function name found

      final functionPart = subStr.substring(indexOfFunction);
      final endOfFunctionIndex = functionPart.indexOf(' ');

      if (endOfFunctionIndex < 0) return functionPart; // No space after function

      return functionPart.substring(0, endOfFunctionIndex);
    } catch (e) {
      print('Failed to build FunctionName for frame: \n\t$frame\n');
      print(e);
      return '?';
    }
  }

  @override
  String toString() {
    return 'LoggerStackTrace(\n'
        '\tfunctionName: $functionName,\n'
        '\tcallerFunctionName: $callerFunctionName,\n'
        '\tfileName: $fileName,\n'
        '\tlineNumber: $lineNumber,\n'
        '\tcolumnNumber: $columnNumber)\n';
  }
}

class FileInfo {
  final String fileName;
  final String lineNumber;
  final String column;

  FileInfo({this.fileName = '', this.lineNumber = '', this.column = ''});

  @override
  String toString() {
    return 'FileInfo{fileName: $fileName, lineNumber: $lineNumber, column: $column}';
  }
}
