// lib/models/notification.dart
import 'package:flutter/material.dart';

class NotificationModel {
  final int id;
  final int userId;
  final String userType;
  final String title;
  final String message;
  final String type;
  bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.userType,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: _parseInt(json['id']),
      userId: _parseInt(json['user_id']),
      userType: json['user_type']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      type: json['type']?.toString() ?? 'info',
      isRead: json['is_read'] == 1 || json['is_read'] == '1' || json['is_read'] == true,
      createdAt: _parseDateTime(json['created_at']),
    );
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'user_type': userType,
      'title': title,
      'message': message,
      'type': type,
      'is_read': isRead ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  String get formattedDate {
    final now = DateTime.now();
    final diff = now.difference(createdAt);
    
    if (diff.inDays > 7) {
      return '${createdAt.day.toString().padLeft(2, '0')}/${createdAt.month.toString().padLeft(2, '0')}/${createdAt.year}';
    } else if (diff.inDays > 0) {
      return 'il y a ${diff.inDays} jour${diff.inDays > 1 ? 's' : ''}';
    } else if (diff.inHours > 0) {
      return 'il y a ${diff.inHours} heure${diff.inHours > 1 ? 's' : ''}';
    } else if (diff.inMinutes > 0) {
      return 'il y a ${diff.inMinutes} minute${diff.inMinutes > 1 ? 's' : ''}';
    } else {
      return 'à l\'instant';
    }
  }

  IconData get icon {
    switch (type) {
      case 'absence':
        return Icons.warning_amber_rounded;
      case 'justifie':
        return Icons.check_circle_outline;
      case 'info':
        return Icons.info_outline;
      case 'success':
        return Icons.check_circle_outline;
      default:
        return Icons.notifications_none;
    }
  }

  Color get iconColor {
    switch (type) {
      case 'absence':
        return Colors.red;
      case 'justifie':
        return Colors.orange;
      case 'info':
        return Colors.blue;
      case 'success':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}

class NotificationStats {
  final int total;
  final int unread;
  final Map<String, int> byType;

  NotificationStats({
    required this.total,
    required this.unread,
    required this.byType,
  });

  factory NotificationStats.fromJson(Map<String, dynamic> json) {
    final byType = <String, int>{};
    if (json['by_type'] != null) {
      (json['by_type'] as Map).forEach((key, value) {
        byType[key.toString()] = value is int ? value : int.tryParse(value.toString()) ?? 0;
      });
    }
    
    return NotificationStats(
      total: json['total'] is int ? json['total'] : int.tryParse(json['total'].toString()) ?? 0,
      unread: json['unread'] is int ? json['unread'] : int.tryParse(json['unread'].toString()) ?? 0,
      byType: byType,
    );
  }
}