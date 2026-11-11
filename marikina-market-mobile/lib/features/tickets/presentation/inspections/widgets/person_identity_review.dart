import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/person_candidate.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/vendor_summary.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/bloc/inspection_bloc.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/bloc/inspection_event.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/bloc/inspection_state.dart';
import 'find_person_sheet.dart';
import 'owner_person_card.dart';
import 'person_history_sheet.dart';
import 'person_result_card.dart';

// Choosing the violator: the owner card first, then anyone else by name.
// After a choice only that person is shown, with Change and History.
class PersonIdentityReview extends StatefulWidget {
  // Null when the vendor is not registered: there is no owner.
  final VendorSummary? vendor;
  final ValueChanged<PersonCandidate?> onChanged;
  const PersonIdentityReview({
    super.key,
    required this.vendor,
    required this.onChanged,
  });
  @override
  State<PersonIdentityReview> createState() => _PersonIdentityReviewState();
}

class _PersonIdentityReviewState extends State<PersonIdentityReview> {
  PersonCandidate? _selected;
  PersonCandidate? _owner;
  bool _ownerLoading = false, _adding = false;
  String? _ownerError, _addError;

  @override
  void initState() {
    super.initState();
    if (widget.vendor != null) {
      _ownerLoading = true;
      _loadOwner();
    }
  }

  void _loadOwner() => context.read<InspectionBloc>().add(
    OwnerPersonRequested(widget.vendor!.id),
  );

  void _addOwner() => context.read<InspectionBloc>().add(
    OwnerPersonAddRequested(widget.vendor!.id),
  );

  void _select(PersonCandidate? person) {
    setState(() => _selected = person);
    widget.onChanged(person);
  }

  Future<void> _findPerson() async {
    final person = await showModalBottomSheet<PersonCandidate>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      useSafeArea: true,
      sheetAnimationStyle: MediaQuery.disableAnimationsOf(context)
          ? AnimationStyle.noAnimation
          : const AnimationStyle(
              duration: AppTheme.pageTransitionDuration,
              reverseDuration: AppTheme.pageReverseTransitionDuration,
            ),
      builder: (_) => BlocProvider.value(
        value: context.read<InspectionBloc>(),
        child: FindPersonSheet(businessId: widget.vendor?.id),
      ),
    );
    if (mounted && person != null) _select(person);
  }

  // Owner replies for another business (one shown earlier) are ignored.
  void _onState(BuildContext context, InspectionState state) {
    final id = widget.vendor?.id;
    if (state is OwnerPersonLoading && state.businessId == id) {
      setState(() {
        _ownerLoading = true;
        _ownerError = null;
      });
    }
    if (state is OwnerPersonLoaded && state.businessId == id) {
      setState(() {
        _ownerLoading = false;
        _owner = state.person;
      });
    }
    if (state is OwnerPersonError && state.businessId == id) {
      setState(() {
        _ownerLoading = false;
        _ownerError = state.message;
      });
    }
    if (state is OwnerPersonAdding && state.businessId == id) {
      setState(() {
        _adding = true;
        _addError = null;
      });
    }
    if (state is OwnerPersonAddError && state.businessId == id) {
      setState(() {
        _adding = false;
        _addError = state.message;
      });
    }
    if (state is OwnerPersonAdded && state.businessId == id) {
      setState(() {
        _adding = false;
        _owner = state.person;
      });
      // Someone chosen meanwhile stays chosen; the owner card just updates.
      if (_selected == null) _select(state.person);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vendor = widget.vendor;
    final selected = _selected;
    return BlocListener<InspectionBloc, InspectionState>(
      listener: _onState,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Violator', style: AppTheme.inspectionHeadingStyle),
          const SizedBox(height: AppTheme.inspectionSmallGap),
          if (selected != null) ...[
            PersonResultCard(
              person: selected,
              isOwner: selected.id == _owner?.id,
              isSelected: true,
              onTap: null,
            ),
            Row(
              children: [
                TextButton(
                  onPressed: () => _select(null),
                  child: const Text('Change'),
                ),
                TextButton(
                  onPressed: () => PersonHistorySheet.show(
                    context,
                    selected.id,
                    selected.fullName,
                  ),
                  child: const Text('History'),
                ),
              ],
            ),
          ] else ...[
            if (vendor != null)
              OwnerPersonCard(
                ownerName: vendor.ownerName,
                owner: _owner,
                isLoading: _ownerLoading,
                error: _ownerError,
                isAdding: _adding,
                addError: _addError,
                onRetry: _loadOwner,
                onAdd: _addOwner,
                onSelect: _select,
              ),
            OutlinedButton.icon(
              onPressed: _findPerson,
              icon: const Icon(Icons.person_search_outlined),
              label: Text(vendor == null ? 'Find violator' : 'Someone else'),
            ),
          ],
          const SizedBox(height: AppTheme.inspectionSmallGap),
        ],
      ),
    );
  }
}
