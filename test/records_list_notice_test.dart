import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/features/records/domain/enums/records_filter.dart';
import 'package:marikina_market_mobile/features/records/domain/use_cases/load_records_use_case.dart';
import 'package:marikina_market_mobile/features/records/presentation/bloc/records/records_bloc.dart';
import 'package:marikina_market_mobile/features/records/presentation/bloc/records/load_records.dart';
import 'package:marikina_market_mobile/features/records/presentation/widgets/records_header.dart';
import 'package:marikina_market_mobile/features/records/presentation/widgets/records_list_section.dart';
import 'package:marikina_market_mobile/features/records/presentation/widgets/records_list_notice.dart';
import 'features/auth/data/login_mobile_contract_test.dart' show reply;
import 'records_feature_test.dart'
    show recordsRepository, recordResponse, fetch;

void main() {
  testWidgets('record count follows loaded pages rather than server total', (
    tester,
  ) async {
    FlutterSecureStorage.setMockInitialValues({});
    late RecordsBloc bloc;
    await tester.runAsync(() async {
      final repository = recordsRepository((options) async {
        final offset = options.queryParameters['offset'] as int;
        return reply(options, {
          'items': [
            {...recordResponse, 'ticket_id': 101 + offset},
          ],
          'has_more': offset == 0,
          'total': 2,
        });
      });
      bloc = RecordsBloc(LoadRecordsUseCase(repository));
      await fetch(bloc, const LoadRecords());
    });
    addTearDown(bloc.close);
    await tester.pumpWidget(
      BlocProvider.value(
        value: bloc,
        child: MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: CustomScrollView(
              slivers: [RecordsListSection(onRetry: () {}, onLoadMore: () {})],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Records • 1'), findsOneWidget);
    expect(find.text('Records • 2'), findsNothing);
    await tester.runAsync(() => fetch(bloc, const LoadRecords(offset: 1)));
    await tester.pumpAndSettle();
    expect(find.text('Records • 2'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Records search submits and clears at narrow widths', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(280, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final search = TextEditingController();
    addTearDown(search.dispose);
    var submissions = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: SingleChildScrollView(
            padding: AppTheme.inspectionHeaderPadding,
            child: RecordsHeader(
              searchController: search,
              filter: RecordsFilter.all,
              onFilterChanged: (_) {},
              onSearchChanged: (_) {},
              onSearchSubmitted: () => submissions++,
              onClear: () {
                search.clear();
                submissions++;
              },
            ),
          ),
        ),
      ),
    );
    expect(find.byTooltip('Clear search'), findsNothing);
    await tester.enterText(find.byType(TextField), '101');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    expect(submissions, 1);
    await tester.pump();
    await tester.tap(find.byTooltip('Clear search'));
    await tester.pump();
    expect(search.text, isEmpty);
    expect(submissions, 2);
    expect(find.byTooltip('Clear search'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('empty and error cards wrap at narrow widths and retry errors', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(280, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var retries = 0;
    Future<void> showNotice({VoidCallback? onRetry}) => tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: SingleChildScrollView(
            padding: AppTheme.inspectionListPadding,
            child: RecordsListNotice(
              title: onRetry == null
                  ? 'No records found'
                  : 'Unable to load records',
              message: onRetry == null
                  ? 'Try changing your search or record type. New records will appear here.'
                  : 'Unavailable right now.',
              icon: onRetry == null
                  ? Icons.assignment_outlined
                  : Icons.cloud_off_outlined,
              onRetry: onRetry,
            ),
          ),
        ),
      ),
    );
    await showNotice();
    expect(find.text('No records found'), findsOneWidget);
    expect(find.text('Try again'), findsNothing);
    expect(tester.takeException(), isNull);
    await showNotice(onRetry: () => retries++);
    expect(find.text('Unavailable right now.'), findsOneWidget);
    await tester.tap(find.text('Try again'));
    expect(retries, 1);
    expect(tester.takeException(), isNull);
  });
}
