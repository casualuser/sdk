// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/src/services/search/search_engine.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/dart/analysis/search.dart';
import 'package:analyzer/src/generated/source.dart' show Source, SourceRange;

/**
 * A [SearchEngine] implementation.
 */
class SearchEngineImpl implements SearchEngine {
  final Iterable<AnalysisDriver> _drivers;

  SearchEngineImpl(this._drivers);

  @override
  Future<Set<String>> membersOfSubtypes(ClassElement type) async {
    // TODO(brianwilkerson) Determine whether this await is necessary.
    await null;
    List<AnalysisDriver> drivers = _drivers.toList();
    SearchedFiles searchedFiles = _createSearchedFiles(drivers);

    String libraryUriStr = type.librarySource.uri.toString();
    bool hasSubtypes = false;
    Set<String> visitedIds = <String>{};
    Set<String> members = <String>{};

    Future<void> addMembers(ClassElement type, SubtypeResult subtype) async {
      // TODO(brianwilkerson) Determine whether this await is necessary.
      await null;
      if (subtype != null && !visitedIds.add(subtype.id)) {
        return;
      }
      for (AnalysisDriver driver in drivers) {
        List<SubtypeResult> subtypes = await driver.search
            .subtypes(searchedFiles, type: type, subtype: subtype);
        for (SubtypeResult subtype in subtypes) {
          hasSubtypes = true;
          members.addAll(subtype.libraryUri == libraryUriStr
              ? subtype.members
              : subtype.members.where((name) => !name.startsWith('_')));
          await addMembers(null, subtype);
        }
      }
    }

    await addMembers(type, null);

    if (!hasSubtypes) {
      return null;
    }
    return members;
  }

  @override
  Future<Set<ClassElement>> searchAllSubtypes(ClassElement type) async {
    // TODO(brianwilkerson) Determine whether this await is necessary.
    await null;
    Set<ClassElement> allSubtypes = <ClassElement>{};

    Future<void> addSubtypes(ClassElement type) async {
      // TODO(brianwilkerson) Determine whether this await is necessary.
      await null;
      List<SearchResult> directResults = await _searchDirectSubtypes(type);
      for (SearchResult directResult in directResults) {
        var directSubtype = directResult.enclosingElement as ClassElement;
        if (allSubtypes.add(directSubtype)) {
          await addSubtypes(directSubtype);
        }
      }
    }

    await addSubtypes(type);
    return allSubtypes;
  }

  @override
  Future<List<SearchMatch>> searchMemberDeclarations(String name) async {
    // TODO(brianwilkerson) Determine whether this await is necessary.
    await null;
    List<SearchMatch> allDeclarations = [];
    List<AnalysisDriver> drivers = _drivers.toList();
    for (AnalysisDriver driver in drivers) {
      List<Element> elements = await driver.search.classMembers(name);
      allDeclarations.addAll(elements.map(SearchMatchImpl.forElement));
    }
    return allDeclarations;
  }

  @override
  Future<List<SearchMatch>> searchMemberReferences(String name) async {
    // TODO(brianwilkerson) Determine whether this await is necessary.
    await null;
    List<SearchResult> allResults = [];
    List<AnalysisDriver> drivers = _drivers.toList();
    SearchedFiles searchedFiles = _createSearchedFiles(drivers);
    for (AnalysisDriver driver in drivers) {
      List<SearchResult> results =
          await driver.search.unresolvedMemberReferences(name, searchedFiles);
      allResults.addAll(results);
    }
    return allResults.map(SearchMatchImpl.forSearchResult).toList();
  }

  @override
  Future<List<SearchMatch>> searchReferences(Element element) async {
    // TODO(brianwilkerson) Determine whether this await is necessary.
    await null;
    List<SearchResult> allResults = [];
    List<AnalysisDriver> drivers = _drivers.toList();
    SearchedFiles searchedFiles = _createSearchedFiles(drivers);
    for (AnalysisDriver driver in drivers) {
      List<SearchResult> results =
          await driver.search.references(element, searchedFiles);
      allResults.addAll(results);
    }
    return allResults.map(SearchMatchImpl.forSearchResult).toList();
  }

  @override
  Future<List<SearchMatch>> searchSubtypes(ClassElement type) async {
    // TODO(brianwilkerson) Determine whether this await is necessary.
    await null;
    List<SearchResult> results = await _searchDirectSubtypes(type);
    return results.map(SearchMatchImpl.forSearchResult).toList();
  }

  @override
  Future<List<SearchMatch>> searchTopLevelDeclarations(String pattern) async {
    // TODO(brianwilkerson) Determine whether this await is necessary.
    await null;
    Set<Element> allElements = <Element>{};
    RegExp regExp = RegExp(pattern);
    List<AnalysisDriver> drivers = _drivers.toList();
    for (AnalysisDriver driver in drivers) {
      List<Element> elements = await driver.search.topLevelElements(regExp);
      allElements.addAll(elements);
    }
    return allElements.map(SearchMatchImpl.forElement).toList();
  }

  /**
   * Create a new [SearchedFiles] instance in which added files are owned
   * by the drivers that have them added.
   */
  SearchedFiles _createSearchedFiles(List<AnalysisDriver> drivers) {
    var searchedFiles = SearchedFiles();
    for (AnalysisDriver driver in drivers) {
      searchedFiles.ownAdded(driver.search);
    }
    return searchedFiles;
  }

  Future<List<SearchResult>> _searchDirectSubtypes(ClassElement type) async {
    // TODO(brianwilkerson) Determine whether this await is necessary.
    await null;
    List<SearchResult> allResults = [];
    List<AnalysisDriver> drivers = _drivers.toList();
    SearchedFiles searchedFiles = _createSearchedFiles(drivers);
    for (AnalysisDriver driver in drivers) {
      List<SearchResult> results =
          await driver.search.subTypes(type, searchedFiles);
      allResults.addAll(results);
    }
    return allResults;
  }
}

class SearchMatchImpl implements SearchMatch {
  @override
  final String file;

  @override
  final Source librarySource;

  @override
  final Source unitSource;

  @override
  final LibraryElement libraryElement;

  @override
  final Element element;

  @override
  final bool isResolved;

  @override
  final bool isQualified;

  @override
  final MatchKind kind;

  @override
  final SourceRange sourceRange;

  SearchMatchImpl(
      this.file,
      this.librarySource,
      this.unitSource,
      this.libraryElement,
      this.element,
      this.isResolved,
      this.isQualified,
      this.kind,
      this.sourceRange);

  @override
  String toString() {
    StringBuffer buffer = StringBuffer();
    buffer.write("SearchMatch(kind=");
    buffer.write(kind);
    buffer.write(", libraryUri=");
    buffer.write(librarySource.uri);
    buffer.write(", unitUri=");
    buffer.write(unitSource.uri);
    buffer.write(", range=");
    buffer.write(sourceRange);
    buffer.write(", isResolved=");
    buffer.write(isResolved);
    buffer.write(", isQualified=");
    buffer.write(isQualified);
    buffer.write(")");
    return buffer.toString();
  }

  static SearchMatchImpl forElement(Element element) {
    return SearchMatchImpl(
        element.source.fullName,
        element.librarySource,
        element.source,
        element.library,
        element,
        true,
        true,
        MatchKind.DECLARATION,
        SourceRange(element.nameOffset, element.nameLength));
  }

  static SearchMatchImpl forSearchResult(SearchResult result) {
    Element enclosingElement = result.enclosingElement;
    return SearchMatchImpl(
        enclosingElement.source.fullName,
        enclosingElement.librarySource,
        enclosingElement.source,
        enclosingElement.library,
        enclosingElement,
        result.isResolved,
        result.isQualified,
        toMatchKind(result.kind),
        SourceRange(result.offset, result.length));
  }

  static MatchKind toMatchKind(SearchResultKind kind) {
    if (kind == SearchResultKind.READ) {
      return MatchKind.READ;
    }
    if (kind == SearchResultKind.READ_WRITE) {
      return MatchKind.READ_WRITE;
    }
    if (kind == SearchResultKind.WRITE) {
      return MatchKind.WRITE;
    }
    if (kind == SearchResultKind.INVOCATION) {
      return MatchKind.INVOCATION;
    }
    return MatchKind.REFERENCE;
  }
}
