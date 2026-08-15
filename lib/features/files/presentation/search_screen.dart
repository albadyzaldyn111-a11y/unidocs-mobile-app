import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:unidocs_mobile/core/theme/app_tokens.dart';
import 'package:unidocs_mobile/core/widgets/state_views.dart';
import '../../auth/presentation/auth_controller.dart';
import 'package:unidocs_mobile/features/files/data/files_api.dart';
import 'widgets/file_card.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;
  String _query = '';
  String _sort = 'recent';

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      setState(() => _query = value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = ref.watch(authControllerProvider).user;

    final resultsAsync = user == null
        ? const AsyncValue<List<FileItem>>.data([])
        : ref.watch(_searchResultsProvider((universityId: user.universityId, q: _query, sort: _sort)));

    return Scaffold(
      appBar: AppBar(title: const Text('بحث')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                TextField(
                  controller: _controller,
                  onChanged: _onChanged,
                  decoration: const InputDecoration(
                    hintText: 'ابحث عن ملف...',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    ChoiceChip(
                      label: const Text('الأحدث'),
                      selected: _sort == 'recent',
                      onSelected: (_) => setState(() => _sort = 'recent'),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    ChoiceChip(
                      label: const Text('الأكثر تحميلًا'),
                      selected: _sort == 'popular',
                      onSelected: (_) => setState(() => _sort = 'popular'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: resultsAsync.when(
              data: (files) => files.isEmpty
                  ? const EmptyStateView(message: 'لا توجد نتائج')
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                      itemCount: files.length,
                      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, i) =>
                          FileCard(file: files[i], onTap: () => context.push('/files/${files[i].id}')),
                    ),
              loading: () => const LoadingView(),
              error: (e, st) => const ErrorStateView(message: 'تعذر إتمام البحث'),
            ),
          ),
        ],
      ),
    );
  }
}

typedef _SearchArgs = ({String universityId, String q, String sort});

final _searchResultsProvider =
    FutureProvider.family.autoDispose<List<FileItem>, _SearchArgs>((ref, args) async {
  return ref.watch(filesApiProvider).search(universityId: args.universityId, query: args.q, sort: args.sort);
});
