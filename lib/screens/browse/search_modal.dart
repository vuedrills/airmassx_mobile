import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';
import 'package:go_router/go_router.dart';
import '../../bloc/search/search_bloc.dart';
import '../../bloc/search/search_event.dart';
import '../../bloc/search/search_state.dart';
import '../../bloc/browse/browse_bloc.dart';
import '../../bloc/browse/browse_event.dart';
import '../../config/theme.dart';
import '../../widgets/enhanced_task_card.dart';
import '../../widgets/task/task_card.dart';


/// Full-screen search modal with history and suggestions
class SearchModal extends StatefulWidget {
  const SearchModal({super.key});

  static Future<void> show(BuildContext context, {SearchBloc? searchBloc, BrowseBloc? browseBloc}) {
    final effectiveSearchBloc = searchBloc ?? context.read<SearchBloc>();
    final effectiveBrowseBloc = browseBloc ?? context.read<BrowseBloc>();
    
    return Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (newContext) => MultiBlocProvider(
          providers: [
            BlocProvider.value(value: effectiveSearchBloc),
            BlocProvider.value(value: effectiveBrowseBloc),
          ],
          child: const SearchModal(),
        ),
      ),
    );
  }

  @override
  State<SearchModal> createState() => _SearchModalState();
}

class _SearchModalState extends State<SearchModal> {
  late TextEditingController _searchController;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    if (!_initialized) {
      _initialized = true;
      final searchBloc = context.read<SearchBloc>();
      searchBloc.add(LoadSearchHistory());
      
      _searchController.addListener(() {
        if (_searchController.text.isNotEmpty) {
          searchBloc.add(GetSearchSuggestions(_searchController.text));
        } else {
          searchBloc.add(LoadSearchHistory());
        }
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: AppTheme.neutral900),
          onPressed: () => Navigator.pop(context),
        ),
        title: TextField(
          controller: _searchController,
          autofocus: true,
          style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: 'Search for any task',
            hintStyle: TextStyle(color: AppTheme.neutral400),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            filled: false,
          ),
          onSubmitted: (query) => _performSearch(query),
        ),
        actions: [
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear_rounded, color: AppTheme.neutral500),
              onPressed: () {
                _searchController.clear();
                context.read<SearchBloc>().add(LoadSearchHistory());
              },
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: AppTheme.divider.withOpacity(0.5),
            height: 1,
          ),
        ),
      ),
      body: BlocBuilder<SearchBloc, SearchState>(
        builder: (context, state) {
          if (state is SearchLoading) {
            return _buildSkeleton();
          }
          
          if (state is SearchLoaded) {
            return _buildSearchResults(state);
          }
          
          if (state is SearchSuggestionsLoaded) {
           return _buildSuggestions(state);
          }
          
          if (state is SearchHistoryLoaded) {
            return _buildSearchHistory(state);
          }
          
          return _buildEmptyState();
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppTheme.primarySoft,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search_rounded,
                size: 80,
                color: AppTheme.primary.withOpacity(0.2),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'What are you looking for?',
              style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Try searching for tasks like "cleaning",\n"heavy lifting" or "app development"',
              textAlign: TextAlign.center,
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.neutral500,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchHistory(SearchHistoryLoaded state) {
    if (state.history.isEmpty) {
      return _buildEmptyState();
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'RECENT SEARCHES',
                style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: AppTheme.neutral500,
                ),
              ),
              TextButton(
                onPressed: () => context.read<SearchBloc>().add(ClearSearchHistory()),
                style: TextButton.styleFrom(
                  minimumSize: Size.zero,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Clear all',
                  style: TextStyle(fontSize: 12, color: AppTheme.navy),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: state.history.length,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemBuilder: (context, index) {
              final item = state.history[index];
              return ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                leading: Icon(Icons.history_rounded, size: 20, color: AppTheme.neutral400),
                title: Text(
                  item.query,
                  style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                    color: AppTheme.neutral800,
                  ),
                ),
                trailing: Icon(Icons.north_west_rounded, size: 16, color: AppTheme.neutral300),
                onTap: () => _performSearch(item.query),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSuggestions(SearchSuggestionsLoaded state) {
    if (state.suggestions.isEmpty) {
      return Center(
        child: Text(
          'No suggestions found',
          style: TextStyle(color: AppTheme.neutral500),
        ),
      );
    }
    
    return ListView.builder(
      itemCount: state.suggestions.length,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      itemBuilder: (context, index) {
        final suggestion = state.suggestions[index];
        return ListTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          leading: Icon(Icons.search_rounded, size: 20, color: AppTheme.primary.withOpacity(0.5)),
          title: Text(
            suggestion,
            style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
              color: AppTheme.neutral800,
            ),
          ),
          trailing: Icon(Icons.north_west_rounded, size: 16, color: AppTheme.neutral300),
          onTap: () => _performSearch(suggestion),
        );
      },
    );
  }

  Widget _buildSearchResults(SearchLoaded state) {
    if (state.tasks.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.neutral100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.search_off_rounded,
                  size: 48,
                  color: AppTheme.neutral400,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'No tasks found for "${state.query}"',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.navy,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Try different keywords or browse all tasks',
                style: TextStyle(color: AppTheme.neutral500),
              ),
            ],
          ),
        ),
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${state.tasks.length} task${state.tasks.length != 1 ? 's' : ''} found',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.success,
              ),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 24),
            itemCount: state.tasks.length,
            itemBuilder: (context, index) {
              final task = state.tasks[index];
              return TaskCard(
                task: task,
              );
            },
          ),
        ),
      ],
    );
  }


  Widget _buildSkeleton() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: AppTheme.neutral100,
          highlightColor: AppTheme.white,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                color: AppTheme.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.neutral200),
              ),
            ),
          ),
        );
      },
    );
  }

  void _performSearch(String query) {
    if (query.trim().isEmpty) return;
    context.read<SearchBloc>().add(SearchTasks(query));
  }
}
