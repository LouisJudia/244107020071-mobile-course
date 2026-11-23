import 'package:flutter/material.dart';

import '../../domain/entities/chat_message.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const ChatBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUser = message.isUser;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: message.isError
                  ? theme.colorScheme.errorContainer
                  : (message.isFallback
                        ? theme.colorScheme.tertiaryContainer
                        : theme.colorScheme.primaryContainer),
              child: Icon(
                message.isError
                    ? Icons.warning_amber_rounded
                    : Icons.auto_awesome,
                size: 18,
                color: message.isError
                    ? theme.colorScheme.error
                    : (message.isFallback
                          ? theme.colorScheme.onTertiaryContainer
                          : theme.colorScheme.onPrimaryContainer),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isUser
                    ? theme.colorScheme.primary
                    : (message.isError
                          ? theme.colorScheme.errorContainer.withValues(
                              alpha: 0.6,
                            )
                          : theme.colorScheme.surfaceContainerHighest),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: isUser
                      ? const Radius.circular(16)
                      : const Radius.circular(4),
                  bottomRight: isUser
                      ? const Radius.circular(4)
                      : const Radius.circular(16),
                ),
              ),
              child: Column(
                crossAxisAlignment: isUser
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  if (!isUser && message.isFallback)
                    Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.tertiaryContainer,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.offline_bolt_rounded,
                            size: 12,
                            color: theme.colorScheme.onTertiaryContainer,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Respon Fallback Lokal',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onTertiaryContainer,
                            ),
                          ),
                        ],
                      ),
                    ),
                  SelectableText(
                    message.text,
                    style: TextStyle(
                      fontSize: 14,
                      color: isUser
                          ? theme.colorScheme.onPrimary
                          : (message.isError
                                ? theme.colorScheme.onErrorContainer
                                : theme.colorScheme.onSurfaceVariant),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${message.timestamp.hour.toString().padLeft(2, '0')}:${message.timestamp.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      fontSize: 10,
                      color:
                          (isUser
                                  ? theme.colorScheme.onPrimary
                                  : theme.colorScheme.onSurfaceVariant)
                              .withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Icon(
                Icons.person,
                size: 18,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
