import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:openreads/core/themes/app_theme.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:openreads/logic/cubit/edit_book_cubit.dart';
import 'package:openreads/model/book.dart';

class TagsField extends StatelessWidget {
  const TagsField({
    Key? key,
    this.controller,
    this.hint,
    this.icon,
    required this.keyboardType,
    required this.maxLength,
    this.inputFormatters,
    this.autofocus = false,
    this.maxLines = 1,
    this.hideCounter = true,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.onSubmitted,
    this.onEditingComplete,
    this.unselectTag,
    this.allTags,
  }) : super(key: key);

  final TextEditingController? controller;
  final String? hint;
  final IconData? icon;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final bool autofocus;
  final int maxLines;
  final bool hideCounter;
  final int maxLength;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final Function(String)? onSubmitted;
  final Function()? onEditingComplete;

  final Function(String)? unselectTag;
  final List<String>? allTags;

  Widget _buildTagChip(BuildContext context,
      {required String tag, required bool selected}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: FilterChip(
        side: BorderSide(color: dividerColor, width: 1),
        label: Text(
          tag,
          style: TextStyle(
            color: selected ? Theme.of(context).colorScheme.onSecondary : null,
          ),
        ),
        checkmarkColor:
            selected ? Theme.of(context).colorScheme.onSecondary : null,
        selected: selected,
        selectedColor: Theme.of(context).colorScheme.secondary,
        onSelected: (_) {
          if (unselectTag == null) return;
          unselectTag!(tag);
        },
      ),
    );
  }

  List<Widget> _generateTagChips(
    BuildContext context,
    List<String> tags,
  ) {
    final chips = List<Widget>.empty(growable: true);

    for (var tag in tags) {
      chips.add(_buildTagChip(
        context,
        tag: tag,
        selected: true,
      ));
    }

    return chips;
  }

  @override
  Widget build(BuildContext context) {
    final FocusNode focusNode = FocusNode();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
          borderRadius: BorderRadius.circular(cornerRadius),
          border: Border.all(color: dividerColor),
        ),
        child: Column(
          children: [
            Scrollbar(
                child: TypeAheadField(
              itemBuilder: (context, suggestion) {
                return ListTile(
                  title: Text(suggestion),
                );
              },
              suggestionsCallback: (pattern) {
                if (allTags == null) {
                  return List<String>.empty();
                }
                return allTags!.where((String option) {
                  return option.toLowerCase().contains(pattern.toLowerCase());
                }).toList();
              },
              onSuggestionSelected: (suggestion) {
                controller?.text = suggestion;
                if (onSubmitted != null) {
                  onSubmitted!(suggestion);
                }
              },
              hideOnLoading: true,
              hideOnEmpty: true,
              suggestionsBoxDecoration: SuggestionsBoxDecoration(
                borderRadius: BorderRadius.circular(4.0),
                elevation: 8.0,
              ),
              textFieldConfiguration: TextFieldConfiguration(
                autofocus: autofocus,
                keyboardType: keyboardType,
                inputFormatters: inputFormatters,
                textCapitalization: textCapitalization,
                controller: controller,
                focusNode: focusNode,
                minLines: 1,
                maxLines: maxLines,
                maxLength: maxLength,
                textInputAction: textInputAction,
                style: const TextStyle(fontSize: 14),
                onSubmitted: onSubmitted,
                onEditingComplete: onEditingComplete,
                decoration: InputDecoration(
                  labelText: hint,
                  labelStyle: const TextStyle(fontSize: 14),
                  icon: (icon != null)
                      ? Icon(
                          icon,
                          color: Theme.of(context).colorScheme.primary,
                        )
                      : null,
                  border: InputBorder.none,
                  counterText: hideCounter ? "" : null,
                ),
              ),
            )),
            Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 5,
                      horizontal: 2.5,
                    ),
                    child: BlocBuilder<EditBookCubit, Book>(
                      builder: (context, state) {
                        return state.tags != null
                            ? Wrap(
                                children: _generateTagChips(
                                  context,
                                  state.tags!.split('|||||'),
                                ),
                              )
                            : const SizedBox();
                      },
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
