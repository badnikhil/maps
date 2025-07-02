import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../core/bloc/location_bloc.dart';
import '../core/bloc/location_event.dart';
import '../core/bloc/location_state.dart';
import '../core/models/location_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocationSearchWidget extends StatefulWidget {
  final String hintText;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final Color backgroundColor;
  final Color textColor;
  final Function(LocationModel)? onLocationSelected;

  const LocationSearchWidget({
    super.key,
    this.hintText = 'Search for area, street name...',
    this.margin,
    this.borderRadius = 12.0,
    this.backgroundColor = Colors.white,
    this.textColor = Colors.black,
    this.onLocationSelected,
  });

  @override
  State<LocationSearchWidget> createState() => _LocationSearchWidgetState();
}

class _LocationSearchWidgetState extends State<LocationSearchWidget> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  List<String> _recentSearches = [];
  static const String _recentSearchesKey = 'recent_searches';
  static const int _maxRecent = 8;

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
  }

  Future<void> _loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _recentSearches = prefs.getStringList(_recentSearchesKey) ?? [];
    });
  }

  Future<void> _addRecentSearch(String query) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _recentSearches.remove(query);
      _recentSearches.insert(0, query);
      if (_recentSearches.length > _maxRecent) {
        _recentSearches = _recentSearches.sublist(0, _maxRecent);
      }
      prefs.setStringList(_recentSearchesKey, _recentSearches);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildSearchBar(),
        _buildSearchResults(),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: widget.margin ?? const EdgeInsets.all(16.0),
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: TextField(
          controller: _searchController,
          focusNode: _searchFocusNode,
          decoration: InputDecoration(
            hintText: widget.hintText,
            prefixIcon: const Icon(Icons.search, color: Colors.grey),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: widget.backgroundColor,
            contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 8),
          ),
          style: TextStyle(color: widget.textColor),
          onChanged: (value) {
            context.read<LocationBloc>().add(SearchLocation(value));
            setState(() {}); // To update the UI for recent searches
          },
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    return BlocBuilder<LocationBloc, LocationState>(
      builder: (context, state) {
        final query = _searchController.text.trim();
        final showRecent = query.isEmpty && _searchFocusNode.hasFocus;
        if (showRecent) {
          if (_recentSearches.isEmpty) {
            return const SizedBox.shrink();
          }
          return Container(
            margin: widget.margin ?? const EdgeInsets.symmetric(horizontal: 16.0),
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(widget.borderRadius),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 220),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _recentSearches.length,
                  itemBuilder: (context, index) {
                    final recent = _recentSearches[index];
                    return ListTile(
                      leading: const Icon(Icons.history, color: Colors.grey),
                      title: Text(recent, style: TextStyle(color: widget.textColor)),
                      onTap: () {
                        _searchController.text = recent;
                        context.read<LocationBloc>().add(SearchLocation(recent));
                        setState(() {});
                      },
                    );
                  },
                ),
              ),
            ),
          );
        }
        if (!_searchFocusNode.hasFocus) {
          return const SizedBox.shrink();
        }
        if (state.isLoading) {
          return Container(
            margin: widget.margin ?? const EdgeInsets.symmetric(horizontal: 16.0),
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(widget.borderRadius),
              child: const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
          );
        }
        if (state.error != null && state.error!.isNotEmpty) {
          return Container(
            margin: widget.margin ?? const EdgeInsets.symmetric(horizontal: 16.0),
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(widget.borderRadius),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Search failed: ${state.error}',
                  style: TextStyle(color: Colors.red, fontSize: 14),
                ),
              ),
            ),
          );
        }
        if (state.searchResults.isEmpty) {
          return Container(
            margin: widget.margin ?? const EdgeInsets.symmetric(horizontal: 16.0),
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(widget.borderRadius),
              child: const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'No results found',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ),
            ),
          );
        }
        return Container(
          margin: widget.margin ?? const EdgeInsets.symmetric(horizontal: 16.0),
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 220),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: state.searchResults.length,
                itemBuilder: (context, index) {
                  final result = state.searchResults[index];
                  return _buildSearchResultItem(result);
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchResultItem(LocationModel result) {
    return ListTile(
      title: Text(
        result.address,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: widget.textColor),
      ),
      onTap: () {
        _searchFocusNode.unfocus();
        _addRecentSearch(result.address);
        _searchController.clear();
        context.read<LocationBloc>().add(SelectSearchResult(result));
        widget.onLocationSelected?.call(result);
      },
    );
  }
} 