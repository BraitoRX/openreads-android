import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:openreads/core/constants/enums.dart';
import 'package:openreads/generated/locale_keys.g.dart';
import 'package:openreads/logic/cubit/edit_book_cubit.dart';
import 'package:openreads/model/book.dart';
import 'package:openreads/model/ol_edition_result.dart';
import 'package:openreads/resources/open_library_service.dart';
import 'package:openreads/ui/add_book_screen/add_book_screen.dart';
import 'package:openreads/ui/search_ol_editions_screen/widgets/widgets.dart';

class SearchOLEditionsScreen extends StatefulWidget {
  const SearchOLEditionsScreen({
    super.key,
    required this.editions,
    required this.title,
    this.subtitle,
    required this.author,
    required this.pagesMedian,
    required this.isbn,
    required this.olid,
    required this.firstPublishYear,
  });

  final List<String> editions;
  final String title;
  final String? subtitle;
  final String author;
  final int? pagesMedian;
  final List<String>? isbn;
  final String? olid;
  final int? firstPublishYear;

  @override
  State<SearchOLEditionsScreen> createState() => _SearchOLEditionsScreenState();
}

class _SearchOLEditionsScreenState extends State<SearchOLEditionsScreen> {
  final sizeOfPage = 3;
  int skippedEditions = 0;
  Uint8List? editionCoverPreview;

  late int filteredResultsLength;

  final _pagingController = PagingController<int, OLEditionResult>(
    firstPageKey: 0,
    invisibleItemsThreshold: 12,
  );

  Future<void> _fetchPage(int pageKey) async {
    try {
      final newResults = await _fetchResults(offset: pageKey);

      if (!mounted) return;

      if (pageKey >= widget.editions.length) {
        _pagingController.appendLastPage(newResults);
      } else {
        final nextPageKey = pageKey + 3;
        _pagingController.appendPage(newResults, nextPageKey);
      }
    } catch (error) {
      if (!mounted) return;
      _pagingController.error = error;
    }
  }

  Future<List<OLEditionResult>> _fetchResults({required int offset}) async {
    final results = List<OLEditionResult>.empty(growable: true);

    for (var i = 0; i < sizeOfPage && i < widget.editions.length; i++) {
      bool hasEditions = true;

      while (hasEditions) {
        if (offset + i + skippedEditions < widget.editions.length) {
          final newResult = await OpenLibraryService()
              .getEdition(widget.editions[offset + i + skippedEditions]);

          results.add(newResult);
          hasEditions = false;
        } else {
          hasEditions = false;
        }
      }
    }

    return results;
  }

  void _saveEdition({
    required OLEditionResult result,
    required int? cover,
    String? work,
  }) {
    final book = Book(
      title: result.title!,
      subtitle: widget.subtitle,
      author: widget.author,
      pages: result.numberOfPages,
      status: 0,
      favourite: false,
      isbn: (result.isbn13 != null && result.isbn13!.isNotEmpty)
          ? result.isbn13![0]
          : (result.isbn10 != null && result.isbn10!.isNotEmpty)
              ? result.isbn10![0]
              : null,
      olid: (result.key != null) ? result.key!.replaceAll('/books/', '') : null,
      publicationYear: widget.firstPublishYear,
      bookFormat: BookFormat.paperback,
    );

    context.read<EditBookCubit>().setBook(book);

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddBookScreen(
          fromOpenLibrary: true,
          fromOpenLibraryEdition: true,
          work: work,
          coverOpenLibraryID: cover,
        ),
      ),
    );
  }

  @override
  void initState() {
    filteredResultsLength = widget.editions.length;

    if (widget.editions.isNotEmpty) {
      _pagingController.addPageRequestListener((pageKey) {
        _fetchPage(pageKey);
      });
    }

    super.initState();
  }

  @override
  void dispose() {
    _pagingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          LocaleKeys.choose_edition.tr(),
          style: const TextStyle(fontSize: 18),
        ),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: Scrollbar(
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: PagedGridView(
                        pagingController: _pagingController,
                        showNewPageProgressIndicatorAsGridChild: false,
                        showNewPageErrorIndicatorAsGridChild: false,
                        showNoMoreItemsIndicatorAsGridChild: false,
                        builderDelegate:
                            PagedChildBuilderDelegate<OLEditionResult>(
                          firstPageProgressIndicatorBuilder: (_) => Center(
                            child: LoadingAnimationWidget.staggeredDotsWave(
                              color: Theme.of(context).colorScheme.primary,
                              size: 50,
                            ),
                          ),
                          newPageProgressIndicatorBuilder: (_) => Center(
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: LoadingAnimationWidget.staggeredDotsWave(
                                color: Theme.of(context).colorScheme.primary,
                                size: 50,
                              ),
                            ),
                          ),
                          itemBuilder: (context, item, index) =>
                              BookCardOLEdition(
                            title: item.title!,
                            cover:
                                item.covers != null && item.covers!.isNotEmpty
                                    ? item.covers![0]
                                    : null,
                            onPressed: () => _saveEdition(
                              result: item,
                              cover:
                                  item.covers != null && item.covers!.isNotEmpty
                                      ? item.covers![0]
                                      : null,
                              work: item.works != null && item.works!.isNotEmpty
                                  ? item.works![0].key
                                  : null,
                            ),
                          ),
                        ),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          childAspectRatio: 5 / 8.0,
                          crossAxisCount: 3,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          mainAxisExtent: 225,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
