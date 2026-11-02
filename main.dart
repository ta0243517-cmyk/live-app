import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() => runApp(MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true),
      home: const Root(),
    ));

class Root extends StatefulWidget {
  const Root({super.key});
  @override
  State<Root> createState() => _RootState();
}

class _RootState extends State<Root> {
  String? url, pass;
  bool loaded = false;

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((p) {
      setState(() {
        url = p.getString('url');
        pass = p.getString('pass');
        loaded = true;
      });
    });
  }

  Future<void> saveSettings(String u, String p) async {
    final sp = await SharedPreferences.getInstance();
    if (!u.startsWith('http')) u = 'http://$u';
    await sp.setString('url', u);
    await sp.setString('pass', p);
    setState(() {
      url = u;
      pass = p;
    });
  }

  Future<void> reset() async {
    final sp = await SharedPreferences.getInstance();
    await sp.clear();
    setState(() {
      url = null;
      pass = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!loaded) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (url == null) return Setup(onSave: saveSettings);
    return Panel(url: url!, pass: pass ?? '', onReset: reset);
  }
}

class Setup extends StatelessWidget {
  final Future<void> Function(String, String) onSave;
  const Setup({super.key, required this.onSave});

  @override
  Widget build(BuildContext context) {
    final u = TextEditingController();
    final p = TextEditingController();
    return Scaffold(
      appBar: AppBar(title: const Text('Server Setup')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          TextField(controller: u, decoration: const InputDecoration(labelText: 'Server (jaise 1.2.3.4:8080)')),
          const SizedBox(height: 12),
          TextField(controller: p, obscureText: true, decoration: const InputDecoration(labelText: 'Panel Password')),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () => onSave(u.text.trim(), p.text),
            child: const Text('Connect'),
          ),
        ]),
      ),
    );
  }
}

class Panel extends StatefulWidget {
  final String url, pass;
  final VoidCallback onReset;
  const Panel({super.key, required this.url, required this.pass, required this.onReset});
  @override
  State<Panel> createState() => _PanelState();
}

class _PanelState extends State<Panel> {
  late final WebViewController c;

  @override
  void initState() {
    super.initState();
    c = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onHttpAuthRequest: (req) => req.onProceed(
            WebViewCredential(user: 'admin', password: widget.pass)),
      ))
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📡 Live Streamer'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: () => c.reload()),
          IconButton(icon: const Icon(Icons.settings), onPressed: widget.onReset),
        ],
      ),
      body: SafeArea(child: WebViewWidget(controller: c)),
    );
  }
}
