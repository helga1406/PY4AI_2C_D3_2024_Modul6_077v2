import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:logbook_app_077/features/logbook/log_controller.dart';
import 'package:logbook_app_077/features/logbook/models/log_model.dart';
import 'package:logbook_app_077/features/widgets/log_item_widget.dart';
import 'package:logbook_app_077/services/access_control_service.dart';
import 'package:logbook_app_077/features/logbook/log_editor_page.dart';

class LogView extends StatefulWidget {
  final String username;
  final String teamId; 
  final String role; 

  const LogView({
    super.key, 
    required this.username, 
    required this.teamId,
    required this.role, 
  });

  @override
  State<LogView> createState() => _LogViewState();
}

class _LogViewState extends State<LogView> {
  late final LogController _controller;
  final Color _primaryPink = const Color.fromARGB(255, 158, 101, 140);

  @override
  void initState() {
    super.initState();

    _controller = LogController(
      username: widget.username,
      teamId: widget.teamId, 
      userRole: widget.role, 
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.loadLogs(widget.teamId);
    });
  }

  Future<void> _refreshData() async {
    await _controller.loadLogs(widget.teamId);
  }

  Future<void> _goToEditor({LogModel? log}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LogEditorPage(log: log, controller: _controller),
      ),
    );

    if (result == true) {
      _refreshData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool canCreate = AccessControlService.canPerform(
      widget.role, 
      AccessControlService.actionCreate,
    );

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          "Logbook: ${widget.username} (${widget.role})", 
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
        backgroundColor: _primaryPink,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () => _confirmAction(
              title: "Konfirmasi Logout",
              content: "Apakah Anda yakin ingin keluar?",
              onConfirm: () async {
                await _controller.clearLocalData();
                if (!context.mounted) return;
                Navigator.of(context).pushReplacementNamed('/');
              },
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBarAndFilter(),
          Expanded(
            child: ValueListenableBuilder<List<LogModel>>(
              valueListenable: _controller.logsNotifier,
              builder: (context, logs, _) {
                final filtered = _filterLogs(logs);

                if (filtered.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: _refreshData,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: SizedBox(
                        height: MediaQuery.of(context).size.height * 0.7,
                        child: _buildEmptyState(),
                      ),
                    ),
                  );
                }

                return _buildLogList(filtered);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: canCreate
          ? FloatingActionButton(
              onPressed: () => _goToEditor(),
              backgroundColor: _primaryPink,
              foregroundColor: Colors.white,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : _primaryPink,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showReadLogDialog(LogModel log) {
    String formattedDate;

    try {
      DateTime dt = DateTime.parse(log.date);
      formattedDate = DateFormat('dd MMMM yyyy, HH:mm', 'id_ID').format(dt);
    } catch (e) {
      formattedDate = log.date;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          log.title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _primaryPink.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  log.category,
                  style: TextStyle(
                    color: _primaryPink,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 15),
              Text(
                log.description,
                style: const TextStyle(fontSize: 16, color: Colors.black87),
              ),
              const Divider(height: 30),
              Text(
                "Dibuat pada: $formattedDate\nAuthor: ${log.authorId}",
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "TUTUP",
              style: TextStyle(
                color: _primaryPink,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmAction({
    required String title,
    required String content,
    required VoidCallback onConfirm,
  }) async {
    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(

        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text("Batal", style: TextStyle(color: _primaryPink)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              onConfirm();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryPink,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: const Text("Ya"),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBarAndFilter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              onChanged: (value) =>
                  setState(() => _controller.searchLog(value)),
              decoration: InputDecoration(
                hintText: "Cari judul...",
                prefixIcon: Icon(Icons.search, color: _primaryPink),
                filled: true,
                fillColor: Colors.white,
                contentPadding: EdgeInsets.zero,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide(
                    color: _primaryPink.withValues(alpha: 0.1),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide(color: _primaryPink, width: 2),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          _buildFilterDropdown(),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _primaryPink.withValues(alpha: 0.1)),
        borderRadius: BorderRadius.circular(25),
      ),
      child: DropdownButtonHideUnderline(
        child: ValueListenableBuilder<String>(
          valueListenable: _controller.selectedFilter,
          builder: (context, currentFilter, _) {
            return DropdownButton<String>(
              value: currentFilter,
              icon: Icon(Icons.filter_list_rounded, color: _primaryPink),
              style: TextStyle(
                color: _primaryPink,
                fontWeight: FontWeight.bold,
              ),
              items:
                  [
                        "Semua",
                        "Pribadi",
                        "Pekerjaan",
                        "Urgent",
                        "Mechanical",
                        "Electronic",
                        "Software",
                      ]
                      .map(
                        (cat) => DropdownMenuItem(value: cat, child: Text(cat)),
                      )
                      .toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() => _controller.setFilterCategory(val));
                }
              },
            );
          },
        ),
      ),
    );
  }

  List<LogModel> _filterLogs(List<LogModel> logs) {
    final search = _controller.searchQuery.value.toLowerCase();
    final filter = _controller.selectedFilter.value;

    final currentUsername = widget.username.trim().toLowerCase();

    return logs.where((log) {
      final bool isOwner = log.authorId.trim().toLowerCase() == currentUsername;

      final bool isVisible = isOwner || (log.isPublic ?? false);
      if (!isVisible) return false;

      final matchesSearch =
          log.title.toLowerCase().contains(search) ||
          log.description.toLowerCase().contains(search);

      final matchesCat = filter == "Semua" || log.category == filter;

      return matchesSearch && matchesCat;
    }).toList();
  }

  Widget _buildEmptyState() {
    final String query = _controller.searchQuery.value;
    final String filter = _controller.selectedFilter.value;

    final bool hasSearch = query.isNotEmpty;
    final bool hasFilter = filter != "Semua";
    final bool isFiltering = hasSearch || hasFilter;

    // --- LOGIKA PESAN DINAMIS ---
    String emptyMessage;
    if (hasSearch && hasFilter) {
      emptyMessage = "Catatan dengan judul '$query' pada kategori '$filter' tidak ditemukan.";
    } else if (hasSearch) {
      emptyMessage = "Kami sudah mencari ke mana-mana, tapi judul '$query' tidak ditemukan.";
    } else if (hasFilter) {
      emptyMessage = "Belum ada catatan untuk kategori '$filter' nih.";
    } else {
      emptyMessage = "Buku catatanmu masih bersih banget nih! Yuk, isi dengan ide dan progres proyek hebatmu hari ini.";
    }

    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset(
              isFiltering 
                  ? 'assets/lottie/search_not_found.json' 
                  : 'assets/lottie/empty_log.json',       
              height: 200, 
              repeat: true,
            ),
      
            Transform.translate(
              offset: const Offset(0, -40), 
              child: Column(
                children: [
                  Text(
                    isFiltering ? "Hasil Tidak Ditemukan" : "Logbook Masih Kosong",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: _primaryPink,
                    ),
                  ),

                  const SizedBox(height: 12),
  
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      emptyMessage, 
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 15,
                        height: 1.5,
                      ),
                    ),
                  ),
                  
                  // TOMBOL BUAT CATATAN
                  if (!isFiltering) ...[
                    const SizedBox(height: 25),
                    ElevatedButton.icon(
                      onPressed: () => _goToEditor(),
                      icon: const Icon(Icons.add),
                      label: const Text("Buat Catatan Pertama"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryPink,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                    ),
                  ],
                ],
              ),
            ), 
          ],
        ),
      ),
    );
  }

  Widget _buildLogList(List<LogModel> filtered) {
    return RefreshIndicator(
      onRefresh: _refreshData,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 80),
        itemCount: filtered.length,
        itemBuilder: (context, index) {
          final log = filtered[index];

          final bool isOwner =
              log.authorId.trim().toLowerCase() ==
              widget.username.trim().toLowerCase();

          final bool canDelete = isOwner;
          final bool canEdit = isOwner;

          return Dismissible(
            key: Key(log.id ?? "${log.date}${log.title}"),
            direction: canDelete
                ? DismissDirection.endToStart
                : DismissDirection.none,
            confirmDismiss: (_) async {
              bool delete = false;

              await _confirmAction(
                title: "Hapus Catatan",
                content: "Yakin ingin menghapus ini?",
                onConfirm: () {
                  delete = true;
                },
              );

              return delete;
            },
            onDismissed: (_) async {
              await _controller.removeLog(log);
              _showSnackBar("Catatan dihapus.");
            },
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              color: Colors.redAccent,
              child: const Icon(
                Icons.delete_forever,
                color: Colors.white,
                size: 30,
              ),
            ),
            child: LogItemWidget(
              log: log,
              canEdit: canEdit,
              canDelete: canDelete,
              onTap: () => _showReadLogDialog(log),
              onEdit: () => _goToEditor(log: log),
              onDelete: () => _confirmAction(
                title: "Hapus Catatan",
                content: "Hapus catatan ini?",
                onConfirm: () async {
                  await _controller.removeLog(log);
                  _showSnackBar("Berhasil dihapus.");
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
