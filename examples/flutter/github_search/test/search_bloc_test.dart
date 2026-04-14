import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:github_search/github_api.dart';
import 'package:github_search/search_bloc.dart';
import 'package:github_search/search_state.dart';

void main() {
  group('SearchBloc', () {
    test('starts with an initial no term state', () {
      final api = StubGithubApi();
      final bloc = SearchBloc(api);

      expect(
        bloc.state,
        emitsInOrder([noTerm]),
      );
    });

    test('emits a loading state then result state when api call succeeds', () {
      final api = StubGithubApi(
        onSearch: (_) async => SearchResult(
          [SearchResultItem('A', 'B', 'C')],
        ),
      );
      final bloc = SearchBloc(api);

      scheduleMicrotask(() {
        bloc.onTextChanged.add('T');
      });

      expect(
        bloc.state,
        emitsInOrder([noTerm, loading, populated]),
      );
    });

    test('emits a no term state when user provides an empty search term', () {
      final api = StubGithubApi();
      final bloc = SearchBloc(api);

      scheduleMicrotask(() {
        bloc.onTextChanged.add('');
      });

      expect(
        bloc.state,
        emitsInOrder([noTerm, noTerm]),
      );
    });

    test('emits an empty state when no results are returned', () {
      final api = StubGithubApi(
        onSearch: (_) async => SearchResult([]),
      );
      final bloc = SearchBloc(api);

      scheduleMicrotask(() {
        bloc.onTextChanged.add('T');
      });

      expect(
        bloc.state,
        emitsInOrder([noTerm, loading, empty]),
      );
    });

    test('throws an error when the backend errors', () {
      final api = StubGithubApi(
        onSearch: (_) => Future<SearchResult>.error(Exception()),
      );
      final bloc = SearchBloc(api);

      scheduleMicrotask(() {
        bloc.onTextChanged.add('T');
      });

      expect(
        bloc.state,
        emitsInOrder([noTerm, loading, error]),
      );
    });

    test('closes the stream on dispose', () {
      final api = StubGithubApi();
      final bloc = SearchBloc(api);

      scheduleMicrotask(() {
        bloc.dispose();
      });

      expect(
        bloc.state,
        emitsInOrder([noTerm, emitsDone]),
      );
    });
  });
}

class StubGithubApi extends GithubApi {
  StubGithubApi({this.onSearch});

  final Future<SearchResult> Function(String term)? onSearch;

  @override
  Future<SearchResult> search(String term) {
    final onSearch = this.onSearch;
    if (onSearch == null) {
      throw UnimplementedError('search was not stubbed');
    }

    return onSearch(term);
  }
}

final noTerm = isA<SearchNoTerm>();

final loading = isA<SearchLoading>();

final empty = isA<SearchEmpty>();

final populated = isA<SearchPopulated>();

final error = isA<SearchError>();
