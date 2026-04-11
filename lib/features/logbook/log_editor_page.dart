import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:logbook_app_077/features/logbook/models/log_model.dart';
import 'package:logbook_app_077/features/logbook/log_controller.dart';

class LogEditorPage extends StatefulWidget {
  final LogModel? log; 
  final LogController controller;

  const LogEditorPage({
    super.key,
    this.log,
    required this.controller,
  });

  @override
  State<LogEditorPage> createState() => _LogEditorPageState();
}

class _LogEditorPageState extends State<LogEditorPage> {
  late TextEditingController _titleController;
  late TextEditingController _descController;
  
  String _selectedCategory = "Mechanical"; 
  final List<String> _categories = [
    "Pribadi", 
    "Pekerjaan", 
    "Urgent", 
    "Mechanical", 
    "Electronic", 
    "Software"
  ];

  bool _isPublic = false; 

@override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.log?.title ?? '');
    _descController = TextEditingController(text: widget.log?.description ?? '');
    
    if (widget.log != null) {
      if (_categories.contains(widget.log!.category)) {
        _selectedCategory = widget.log!.category;
      } else {
        _selectedCategory = "Mechanical"; 
      }
      
      _isPublic = widget.log?.isPublic ?? false; 
    }

    _descController.addListener(() {
      setState(() {});
    });
  }

void _save() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Judul tidak boleh kosong!', style: TextStyle(color: Colors.white)), 
          backgroundColor: Colors.redAccent
        )
      );
      return;
    }

    try {
      if (widget.log == null) {
        // UNTUK CATATAN BARU
        await widget.controller.addLog(
          _titleController.text,
          _descController.text,
          _selectedCategory,
          isPublic: _isPublic, 
        );
        if (mounted) {
          _showSuccessSnackBar('Catatan baru berhasil disimpan! ☁️');
        }
      } else {
        final updatedLog = LogModel(
          id: widget.log!.id,
          title: _titleController.text,
          description: _descController.text,
          date: widget.log!.date, 
          authorId: widget.log!.authorId, 
          teamId: widget.controller.teamId, 
          category: _selectedCategory,
          isPublic: _isPublic, 
        );
        
        await widget.controller.updateLog(updatedLog);
        
        if (mounted) {
          _showSuccessSnackBar('Catatan berhasil diperbarui! ☁️');
        }
      }
      
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal menyimpan data!'), backgroundColor: Colors.redAccent)
        );
      }
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message), 
        backgroundColor: const Color.fromARGB(255, 158, 101, 140)
      )
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryPink = const Color.fromARGB(255, 158, 101, 140);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text(
            widget.log == null ? "Catatan Baru" : "Edit Catatan", 
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)
          ),
          backgroundColor: primaryPink,
          iconTheme: const IconThemeData(color: Colors.white),
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: "Editor"),
              Tab(text: "Pratinjau Markdown"),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.check, size: 28),
              onPressed: _save,
            )
          ],
        ),
        body: TabBarView(
          children: [
            
            // --- TAB 1: AREA EDITOR ---
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    controller: _titleController,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      hintText: "Judul Catatan...",
                      border: InputBorder.none,
                      hintStyle: TextStyle(color: Colors.grey[400])
                    ),
                  ),
                  const Divider(),
                  
                  DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedCategory,
                      isExpanded: true,
                      icon: Icon(Icons.label, color: primaryPink),
                      items: _categories.map((String category) {
                        return DropdownMenuItem(
                          value: category, 
                          child: Text(category, style: TextStyle(color: primaryPink, fontWeight: FontWeight.bold))
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() { _selectedCategory = newValue!; });
                      },
                    ),
                  ),
                  const Divider(),

                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      _isPublic ? "Public (Dilihat Tim)" : "Private (Hanya Saya)",
                      style: TextStyle(
                        fontSize: 14, 
                        fontWeight: FontWeight.w600,
                        color: _isPublic ? Colors.blue : Colors.orange
                      ),
                    ),
                    subtitle: const Text("Catatan private tidak akan muncul di dashboard orang lain."),
                    secondary: Icon(
                      _isPublic ? Icons.public : Icons.lock_person_rounded,
                      color: _isPublic ? Colors.blue : Colors.orange,
                    ),
                    value: _isPublic,
                    onChanged: (bool val) {
                      setState(() { _isPublic = val; });
                    },
                    activeThumbColor: primaryPink,
                    activeTrackColor: primaryPink.withValues(alpha: 0.5),
                  ),
                  const Divider(),

                  Expanded(
                    child: TextField(
                      controller: _descController,
                      maxLines: null,    
                      expands: true,     
                      keyboardType: TextInputType.multiline,
                      decoration: InputDecoration(
                        hintText: "Tulis laporan dengan format Markdown...",
                        border: InputBorder.none,
                        hintStyle: TextStyle(color: Colors.grey[400])
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // --- TAB 2: PRATINJAU MARKDOWN ---
            SingleChildScrollView( 
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: MarkdownBody( 
                  data: _descController.text.isEmpty 
                      ? "_Belum ada teks..._" 
                      : _descController.text,
                  selectable: true,
                  styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                    h1: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
                    p: const TextStyle(fontSize: 16, height: 1.5),
                    listBullet: const TextStyle(fontSize: 16),
                    strong: const TextStyle(fontWeight: FontWeight.bold),
                    em: const TextStyle(fontStyle: FontStyle.italic),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}