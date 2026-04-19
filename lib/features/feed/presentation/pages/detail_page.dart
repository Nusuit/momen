import 'package:flutter/material.dart';
import 'package:momen/core/models/memory_item.dart';
import 'package:momen/core/constants/app_sizes.dart';

class DetailPage extends StatelessWidget {
  const DetailPage({required this.memory, required this.onBack, super.key});

  final MemoryItem? memory;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    if (memory == null) {
      return Scaffold(
        appBar: AppBar(
            leading:
                IconButton(onPressed: onBack, icon: const Icon(Icons.close))),
        body: const Center(child: Text('No memory selected')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(onPressed: onBack, icon: const Icon(Icons.close)),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.edit)),
          IconButton(onPressed: () {}, icon: const Icon(Icons.share)),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSizes.p16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSizes.r24),
              child: memory!.imageUrl.isEmpty
                  ? Container(
                      height: 300,
                      width: double.infinity,
                      color: Theme.of(context).colorScheme.secondary,
                    )
                  : Image.network(
                      memory!.imageUrl,
                      height: 300,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 300,
                        width: double.infinity,
                        color: Theme.of(context).colorScheme.secondary,
                        child: const Center(child: Icon(Icons.broken_image)),
                      ),
                    ),
            ),
            const SizedBox(height: AppSizes.p16),
            Text(
              memory!.alias.isEmpty ? 'Alias: Unknown' : 'Alias: ${memory!.alias}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSizes.p8),
            Text(
              memory!.caption.isEmpty ? '(No caption)' : memory!.caption,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: AppSizes.p16),
            Text(memory!.amount,
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: AppSizes.p8),
            Text('Category: ${memory!.category} | Day ${memory!.day}'),
          ],
        ),
      ),
    );
  }
}
