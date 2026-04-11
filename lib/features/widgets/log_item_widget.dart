import 'package:flutter/material.dart';
import 'package:logbook_app_077/features/logbook/models/log_model.dart';
import 'package:intl/intl.dart';

class LogItemWidget extends StatelessWidget {
  final LogModel log;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onTap;
  
  final bool canEdit;
  final bool canDelete;

  const LogItemWidget({
    super.key,
    required this.log,
    required this.onEdit,
    required this.onDelete,
    required this.onTap,
    required this.canEdit,
    required this.canDelete,
  });

  String _formatDateTime(String dateStr) {
    try {
      DateTime logTime = DateTime.parse(dateStr);
      return DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(logTime);
    } catch (e) {
      return dateStr;
    }
  }

  Color _getCategoryBaseColor() {
    switch (log.category) {
      case "Urgent":
        return Colors.red;
      case "Pekerjaan":
        return Colors.blue;
      case "Pribadi":
        return Colors.purple;
      case "Mechanical":
        return Colors.green;
      case "Electronic":
        return Colors.cyan;
      case "Software":
        return Colors.indigo;
      default:
        return const Color.fromARGB(255, 158, 101, 140); 
    }
  }

  IconData _getCategoryIcon() {
    switch (log.category) {
      case "Urgent":
        return Icons.priority_high_rounded;
      case "Pekerjaan":
        return Icons.work_history_rounded;
      case "Pribadi":
        return Icons.lock_person_rounded;
      case "Mechanical":
        return Icons.settings_rounded; 
      case "Electronic":
        return Icons.bolt_rounded; 
      case "Software":
        return Icons.code_rounded; 
      default:
        return Icons.label_important_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = _getCategoryBaseColor();
    final bool isTemp = log.id?.contains('temp') ?? true;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // --- WATERMARK KATEGORI ---
          Positioned(
            right: -15,
            bottom: -15,
            child: Icon(
              _getCategoryIcon(),
              size: 100,
              color: primaryColor.withValues(alpha: 0.08), 
            ),
          ),
          
          // --- KONTEN UTAMA ---
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(15),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // BADGE KATEGORI (ICON + NAMA KATEGORI)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: primaryColor.withValues(alpha: 0.1), 
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(_getCategoryIcon(), size: 14, color: primaryColor),
                                  const SizedBox(width: 6),
                                  Text(
                                    log.category,
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: primaryColor),
                                  ),
                                ],
                              ),
                            ),
                            
                            // TOMBOL EDIT & DELETE
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (canEdit)
                                  _buildCircularActionButton(
                                    icon: Icons.edit_rounded,
                                    iconColor: primaryColor,
                                    onTap: onEdit,
                                  ),
                                  
                                if (canEdit && canDelete) const SizedBox(width: 8),

                                if (canDelete)
                                  _buildCircularActionButton(
                                    icon: Icons.delete_forever_rounded, 
                                    iconColor: Colors.redAccent,
                                    onTap: onDelete,
                                  ),
                              ],
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 12), 
                        
                        // BARIS TANGGAL + AWAN + PUBLIC/PRIVATE
                        Row(
                          children: [
                            Icon(Icons.access_time_filled_rounded, size: 14, color: Colors.grey[400]),
                            const SizedBox(width: 6),
                            Text(
                              _formatDateTime(log.date),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                                fontWeight: FontWeight.w500
                              ),
                            ),
                            const SizedBox(width: 8),
                            // INDIKATOR AWAN
                            Icon(
                              isTemp ? Icons.cloud_off_rounded : Icons.cloud_done_rounded,
                              size: 15,
                              color: isTemp ? Colors.orangeAccent : Colors.blueAccent,
                            ),
                            const SizedBox(width: 8),
                            // INDIKATOR PUBLIC/PRIVATE 
                            Icon(
                              (log.isPublic ?? false) ? Icons.public_rounded : Icons.lock_person_rounded,
                              size: 14,
                              color: (log.isPublic ?? false) ? Colors.blue : Colors.orange,
                            ),
                          ],
                        ),

                        const SizedBox(height: 10), 
                        
                        Text(
                          log.title,
                          maxLines: 1, 
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 19, 
                              fontWeight: FontWeight.w800, 
                              color: Colors.black87),
                        ),
                        
                        const SizedBox(height: 6), 
                        
                        Text(
                          log.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 14,
                              height: 1.4, 
                              color: Colors.black.withValues(alpha: 0.7)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // WIDGET UNTUK TOMBOL AKSI (EDIT & DELETE)
  Widget _buildCircularActionButton({
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(7), 
        decoration: BoxDecoration(
          color: Colors.white, 
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 3,
              offset: const Offset(0, 1),
            )
          ],
        ),
        child: Icon(icon, color: iconColor, size: 18), 
      ),
    );
  }
}