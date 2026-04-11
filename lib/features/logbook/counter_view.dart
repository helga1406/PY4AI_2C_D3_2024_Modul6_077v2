import 'package:flutter/material.dart';
import 'package:logbook_app_077/features/logbook/counter_controller.dart';
import 'package:logbook_app_077/features/auth/login_view.dart';

class CounterView extends StatefulWidget {
  final String username;
  const CounterView({super.key, required this.username});

  @override
  State<CounterView> createState() => _CounterViewState();
}

class _CounterViewState extends State<CounterView> {
  final CounterController _controller = CounterController();
  double _sliderValue = 1.0;

  @override
  void initState() {
    super.initState();
    _loadStoredData();
  }

  void _loadStoredData() async {
    await _controller.loadData(widget.username);
    if (mounted) setState(() {});
  }
  
  String getGreeting() {
    var hour = DateTime.now().hour;
    if (hour < 11) return "Selamat Pagi";
    if (hour < 15) return "Selamat Siang";
    if (hour < 18) return "Selamat Sore";
    return "Selamat Malam";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Logbook: ${widget.username}", 
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color.fromARGB(255, 158, 101, 140),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _showLogoutDialog, 
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Text(
              "${getGreeting()}, ${widget.username}!", 
              style: const TextStyle(
                fontSize: 22, 
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 158, 101, 140),
              ),
            ),
              const SizedBox(height: 20),

              const Text("Total Hitungan:", style: TextStyle(fontSize: 18)),
              Text('${_controller.value}',
                  style: const TextStyle(fontSize: 60, fontWeight: FontWeight.bold)),

              const SizedBox(height: 30),
              Text(
                "Atur Nilai Step: ${_sliderValue.round()}",
                style: const TextStyle(
                  fontWeight: FontWeight.bold, 
                  fontSize: 16,
                  color: Color.fromARGB(255, 158, 101, 140), 
                ),
              ),
              Slider(
                value: _sliderValue, min: 1, max: 20, divisions: 19,
                label: _sliderValue.round().toString(),
                activeColor: const Color.fromARGB(255, 158, 101, 140),
                onChanged: (val) => setState(() {
                  _sliderValue = val;
                  _controller.setStep(val.toInt());
                }),
              ),

              const SizedBox(height: 30),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  FloatingActionButton(
                    heroTag: "btn_min",
                    backgroundColor: const Color.fromARGB(255, 156, 71, 80),
                    onPressed: () async {
                      await _controller.decrement(widget.username);
                      if (mounted) setState(() {});
                    },
                    child: const Icon(Icons.remove, color: Colors.white),
                  ),
                  FloatingActionButton(
                    heroTag: "btn_reset",
                    backgroundColor: const Color.fromARGB(255, 175, 172, 147),
                    onPressed: _showResetDialog,
                    child: const Icon(Icons.refresh, color: Colors.white),
                  ),
                  FloatingActionButton(
                    heroTag: "btn_add",
                    backgroundColor: const Color.fromARGB(255, 83, 121, 84),
                    onPressed: () async {
                      await _controller.increment(widget.username);
                      if (mounted) setState(() {});
                    },
                    child: const Icon(Icons.add, color: Colors.white),
                  ),
                ],
              ),

              const SizedBox(height: 40),
              HistoryListWidget(historyData: _controller.history),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), 
        title: const Text("Logout", style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text("Yakin ingin keluar dari akun kamu?"),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        actions: [
          // TOMBOL BATAL 
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[300],
              foregroundColor: Colors.black87,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Batal"),
          ),
          
          // TOMBOL KELUAR 
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 158, 101, 140),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              elevation: 2,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              if (!mounted) return;
              
              Navigator.pushAndRemoveUntil(
                context, 
                MaterialPageRoute(builder: (context) => const LoginView()), 
                (route) => false,
              );
            },
            child: const Text("Keluar", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text("Konfirmasi Reset", style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text("Yakin ingin menghapus semua history?"),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[300],
              foregroundColor: Colors.black87,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 158, 101, 140),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              elevation: 2,
            ),
            onPressed: () async {
              final navigator = Navigator.of(ctx); 
              await _controller.reset(widget.username);       
              if (!mounted) return;
              setState(() {});
              navigator.pop(); 
            },
            child: const Text("Ya, Reset", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

// --- Tampilan History---
class HistoryListWidget extends StatelessWidget {
  final List<String> historyData;
  const HistoryListWidget({super.key, required this.historyData});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Riwayat Aktivitas",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text("(${historyData.length}/5)",
                style: TextStyle(color: Colors.grey[600])),
          ],
        ),
        const SizedBox(height: 10),
        historyData.isEmpty
            ? _buildEmptyState()
            : Column(children: historyData.map((data) => _buildCard(data)).toList()),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(30),
      width: double.infinity,
      decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey.shade300)),
      child: const Column(children: [
        Icon(Icons.history_toggle_off, size: 40, color: Colors.grey),
        Text("Belum ada aktivitas", style: TextStyle(color: Colors.grey))
      ]),
    );
  }

  Widget _buildCard(String data) {
    Color color = Colors.blueGrey;
    IconData icon = Icons.refresh_rounded;

    if (data.contains("menambah")) {
      color = Colors.green[800]!;
      icon = Icons.arrow_upward_rounded;
    } else if (data.contains("mengurangi")) {
      color = Colors.red[800]!;
      icon = Icons.arrow_downward_rounded;
    }

    String aksi = data.split(' pada jam')[0];
    String jam = data.contains(' pada jam')
        ? data.split(' pada jam ')[1]
        : '-';

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: color.withValues(alpha:0.1), shape: BoxShape.circle),
          child: Icon(icon, color: color),
        ),
        title: Text(aksi,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Text("Pukul $jam"),
        trailing: Icon(Icons.circle, size: 10, color: color),
      ),
    );
  }
}