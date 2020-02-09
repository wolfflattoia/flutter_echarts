library flutter_echarts;

import 'package:flutter/widgets.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/foundation.dart';

import 'package:webview_flutter/webview_flutter.dart';

import './echarts_script.dart' show echartsScript;

/// <!DOCTYPE html><html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, minimum-scale=1.0, user-scalable=0, target-densitydpi=device-dpi" /><style type="text/css">body,html,#chart{height: 100%;width: 100%;margin: 0px;}div {-webkit-tap-highlight-color:rgba(255,255,255,0);}</style></head><body><div id="chart" /></body></html>
/// 'data:text/html;base64,' + base64Encode(const Utf8Encoder().convert( /* STRING ABOVE */ ))
const htmlBase64 = 'data:text/html;base64,PCFET0NUWVBFIGh0bWw+PGh0bWw+PGhlYWQ+PG1ldGEgY2hhcnNldD0idXRmLTgiPjxtZXRhIG5hbWU9InZpZXdwb3J0IiBjb250ZW50PSJ3aWR0aD1kZXZpY2Utd2lkdGgsIGluaXRpYWwtc2NhbGU9MS4wLCBtYXhpbXVtLXNjYWxlPTEuMCwgbWluaW11bS1zY2FsZT0xLjAsIHVzZXItc2NhbGFibGU9MCwgdGFyZ2V0LWRlbnNpdHlkcGk9ZGV2aWNlLWRwaSIgLz48c3R5bGUgdHlwZT0idGV4dC9jc3MiPmJvZHksaHRtbCwjY2hhcnR7aGVpZ2h0OiAxMDAlO3dpZHRoOiAxMDAlO21hcmdpbjogMHB4O31kaXYgey13ZWJraXQtdGFwLWhpZ2hsaWdodC1jb2xvcjpyZ2JhKDI1NSwyNTUsMjU1LDApO308L3N0eWxlPjwvaGVhZD48Ym9keT48ZGl2IGlkPSJjaGFydCIgLz48L2JvZHk+PC9odG1sPg==';

typedef OnMessage = void Function(String);

class Echarts extends StatefulWidget {
  Echarts({
    Key key,
    @required this.option,
    this.extraScript = '',
    this.onMessage,
    this.extensions = const [],
    this.captureAllGestures = false,
  }) : super(key: key);

  final String option;

  final String extraScript;

  final OnMessage onMessage;

  final List<String> extensions;

  final bool captureAllGestures;

  @override
  _EchartsState createState() => _EchartsState();
}

class _EchartsState extends State<Echarts> {
  WebViewController _controller;

  String _currentOption;

  @override
  void initState() {
    super.initState();
    _currentOption = widget.option;
  }

  void init() async {
    final extensionsStr = this.widget.extensions.length > 0
    ? this.widget.extensions.reduce(
        (value, element) => (value ?? '') + '\n' + (element ?? '')
      )
    : '';
    await _controller?.evaluateJavascript('''
      $echartsScript
      $extensionsStr
      var chart = echarts.init(document.getElementById('chart'), null);
      ${this.widget.extraScript}
      chart.setOption($_currentOption, true);
    ''');
  }

  void update(String preOption) async {
    _currentOption = widget.option;
    if (_currentOption != preOption) {
      await _controller?.evaluateJavascript('''
        try {
          chart.setOption($_currentOption, true);
        } catch(e) {
        }
      ''');
    }
  }

  @override
  void didUpdateWidget(Echarts oldWidget) {
    super.didUpdateWidget(oldWidget);
    update(oldWidget.option);
  }

  @override
  Widget build(BuildContext context) {
    return WebView(
      initialUrl: htmlBase64,
      javascriptMode: JavascriptMode.unrestricted,
      onWebViewCreated: (WebViewController webViewController) {
        _controller = webViewController;
      },
      onPageFinished: (String url) {
        init();
      },
      javascriptChannels: <JavascriptChannel>[
        JavascriptChannel(
          name: 'Messager',
          onMessageReceived: (JavascriptMessage javascriptMessage) {
            widget?.onMessage(javascriptMessage.message);
          }
        ),
      ].toSet(),
      gestureRecognizers: widget.captureAllGestures
        ? (Set()
          ..add(Factory<VerticalDragGestureRecognizer>(() {
            return VerticalDragGestureRecognizer()
              ..onStart = (DragStartDetails details) {}
              ..onUpdate = (DragUpdateDetails details) {}
              ..onDown = (DragDownDetails details) {}
              ..onCancel = () {}
              ..onEnd = (DragEndDetails details) {};
          }))
          ..add(Factory<HorizontalDragGestureRecognizer>(() {
            return HorizontalDragGestureRecognizer()
              ..onStart = (DragStartDetails details) {}
              ..onUpdate = (DragUpdateDetails details) {}
              ..onDown = (DragDownDetails details) {}
              ..onCancel = () {}
              ..onEnd = (DragEndDetails details) {};
          })))
        : null,
    );
  }
}
