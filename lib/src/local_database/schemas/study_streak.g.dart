// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'study_streak.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetStudyStreakCollection on Isar {
  IsarCollection<StudyStreak> get studyStreaks => this.collection();
}

const StudyStreakSchema = CollectionSchema(
  name: r'StudyStreak',
  id: 5051820796139719,
  properties: {
    r'currentStreak': PropertySchema(
      id: 0,
      name: r'currentStreak',
      type: IsarType.long,
    ),
    r'lastStudyDate': PropertySchema(
      id: 1,
      name: r'lastStudyDate',
      type: IsarType.dateTime,
    ),
    r'longestStreak': PropertySchema(
      id: 2,
      name: r'longestStreak',
      type: IsarType.long,
    ),
    r'studyHistory': PropertySchema(
      id: 3,
      name: r'studyHistory',
      type: IsarType.dateTimeList,
    ),
    r'totalStudyDays': PropertySchema(
      id: 4,
      name: r'totalStudyDays',
      type: IsarType.long,
    ),
    r'userId': PropertySchema(
      id: 5,
      name: r'userId',
      type: IsarType.string,
    )
  },
  estimateSize: _studyStreakEstimateSize,
  serialize: _studyStreakSerialize,
  deserialize: _studyStreakDeserialize,
  deserializeProp: _studyStreakDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},
  getId: _studyStreakGetId,
  getLinks: _studyStreakGetLinks,
  attach: _studyStreakAttach,
  version: '3.1.0+1',
);

int _studyStreakEstimateSize(
  StudyStreak object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.studyHistory.length * 8;
  {
    final value = object.userId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _studyStreakSerialize(
  StudyStreak object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.currentStreak);
  writer.writeDateTime(offsets[1], object.lastStudyDate);
  writer.writeLong(offsets[2], object.longestStreak);
  writer.writeDateTimeList(offsets[3], object.studyHistory);
  writer.writeLong(offsets[4], object.totalStudyDays);
  writer.writeString(offsets[5], object.userId);
}

StudyStreak _studyStreakDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = StudyStreak();
  object.currentStreak = reader.readLong(offsets[0]);
  object.id = id;
  object.lastStudyDate = reader.readDateTimeOrNull(offsets[1]);
  object.longestStreak = reader.readLong(offsets[2]);
  object.studyHistory = reader.readDateTimeList(offsets[3]) ?? [];
  object.totalStudyDays = reader.readLong(offsets[4]);
  object.userId = reader.readStringOrNull(offsets[5]);
  return object;
}

P _studyStreakDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLong(offset)) as P;
    case 1:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 2:
      return (reader.readLong(offset)) as P;
    case 3:
      return (reader.readDateTimeList(offset) ?? []) as P;
    case 4:
      return (reader.readLong(offset)) as P;
    case 5:
      return (reader.readStringOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _studyStreakGetId(StudyStreak object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _studyStreakGetLinks(StudyStreak object) {
  return [];
}

void _studyStreakAttach(
    IsarCollection<dynamic> col, Id id, StudyStreak object) {
  object.id = id;
}

extension StudyStreakQueryWhereSort
    on QueryBuilder<StudyStreak, StudyStreak, QWhere> {
  QueryBuilder<StudyStreak, StudyStreak, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension StudyStreakQueryWhere
    on QueryBuilder<StudyStreak, StudyStreak, QWhereClause> {
  QueryBuilder<StudyStreak, StudyStreak, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<StudyStreak, StudyStreak, QAfterWhereClause> idNotEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<StudyStreak, StudyStreak, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<StudyStreak, StudyStreak, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<StudyStreak, StudyStreak, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension StudyStreakQueryFilter
    on QueryBuilder<StudyStreak, StudyStreak, QFilterCondition> {
  QueryBuilder<StudyStreak, StudyStreak, QAfterFilterCondition>
      currentStreakEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'currentStreak',
        value: value,
      ));
    });
  }

  QueryBuilder<StudyStreak, StudyStreak, QAfterFilterCondition>
      currentStreakGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'currentStreak',
        value: value,
      ));
    });
  }

  QueryBuilder<StudyStreak, StudyStreak, QAfterFilterCondition>
      currentStreakLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'currentStreak',
        value: value,
      ));
    });
  }

  QueryBuilder<StudyStreak, StudyStreak, QAfterFilterCondition>
      currentStreakBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'currentStreak',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<StudyStreak, StudyStreak, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<StudyStreak, StudyStreak, QAfterFilterCondition> idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<StudyStreak, StudyStreak, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<StudyStreak, StudyStreak, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<StudyStreak, StudyStreak, QAfterFilterCondition>
      lastStudyDateIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'lastStudyDate',
      ));
    });
  }

  QueryBuilder<StudyStreak, StudyStreak, QAfterFilterCondition>
      lastStudyDateIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'lastStudyDate',
      ));
    });
  }

  QueryBuilder<StudyStreak, StudyStreak, QAfterFilterCondition>
      lastStudyDateEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastStudyDate',
        value: value,
      ));
    });
  }

  QueryBuilder<StudyStreak, StudyStreak, QAfterFilterCondition>
      lastStudyDateGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lastStudyDate',
        value: value,
      ));
    });
  }

  QueryBuilder<StudyStreak, StudyStreak, QAfterFilterCondition>
      lastStudyDateLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lastStudyDate',
        value: value,
      ));
    });
  }

  QueryBuilder<StudyStreak, StudyStreak, QAfterFilterCondition>
      lastStudyDateBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lastStudyDate',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<StudyStreak, StudyStreak, QAfterFilterCondition>
      longestStreakEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'longestStreak',
        value: value,
      ));
    });
  }

  QueryBuilder<StudyStreak, StudyStreak, QAfterFilterCondition>
      longestStreakGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'longestStreak',
        value: value,
      ));
    });
  }

  QueryBuilder<StudyStreak, StudyStreak, QAfterFilterCondition>
      longestStreakLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'longestStreak',
        value: value,
      ));
    });
  }

  QueryBuilder<StudyStreak, StudyStreak, QAfterFilterCondition>
      longestStreakBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'longestStreak',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<StudyStreak, StudyStreak, QAfterFilterCondition>
      studyHistoryElementEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'studyHistory',
        value: value,
      ));
    });
  }

  QueryBuilder<StudyStreak, StudyStreak, QAfterFilterCondition>
      studyHistoryElementGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'studyHistory',
        value: value,
      ));
    });
  }

  QueryBuilder<StudyStreak, StudyStreak, QAfterFilterCondition>
      studyHistoryElementLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'studyHistory',
        value: value,
      ));
    });
  }

  QueryBuilder<StudyStreak, StudyStreak, QAfterFilterCondition>
      studyHistoryElementBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'studyHistory',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<StudyStreak, StudyStreak, QAfterFilterCondition>
      studyHistoryLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'studyHistory',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<StudyStreak, StudyStreak, QAfterFilterCondition>
      studyHistoryIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'studyHistory',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<StudyStreak, StudyStreak, QAfterFilterCondition>
      studyHistoryIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'studyHistory',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<StudyStreak, StudyStreak, QAfterFilterCondition>
      studyHistoryLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'studyHistory',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<StudyStreak, StudyStreak, QAfterFilterCondition>
      studyHistoryLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'studyHistory',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<StudyStreak, StudyStreak, QAfterFilterCondition>
      studyHistoryLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'studyHistory',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<StudyStreak, StudyStreak, QAfterFilterCondition>
      totalStudyDaysEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'totalStudyDays',
        value: value,
      ));
    });
  }

  QueryBuilder<StudyStreak, StudyStreak, QAfterFilterCondition>
      totalStudyDaysGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'totalStudyDays',
        value: value,
      ));
    });
  }

  QueryBuilder<StudyStreak, StudyStreak, QAfterFilterCondition>
      totalStudyDaysLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'totalStudyDays',
        value: value,
      ));
    });
  }

  QueryBuilder<StudyStreak, StudyStreak, QAfterFilterCondition>
      totalStudyDaysBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'totalStudyDays',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<StudyStreak, StudyStreak, QAfterFilterCondition> userIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'userId',
      ));
    });
  }

  QueryBuilder<StudyStreak, StudyStreak, QAfterFilterCondition>
      userIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'userId',
      ));
    });
  }

  QueryBuilder<StudyStreak, StudyStreak, QAfterFilterCondition> userIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'userId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<StudyStreak, StudyStreak, QAfterFilterCondition>
      userIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'userId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<StudyStreak, StudyStreak, QAfterFilterCondition> userIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'userId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<StudyStreak, StudyStreak, QAfterFilterCondition> userIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'userId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<StudyStreak, StudyStreak, QAfterFilterCondition>
      userIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'userId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<StudyStreak, StudyStreak, QAfterFilterCondition> userIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'userId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<StudyStreak, StudyStreak, QAfterFilterCondition> userIdContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'userId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<StudyStreak, StudyStreak, QAfterFilterCondition> userIdMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'userId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<StudyStreak, StudyStreak, QAfterFilterCondition>
      userIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'userId',
        value: '',
      ));
    });
  }

  QueryBuilder<StudyStreak, StudyStreak, QAfterFilterCondition>
      userIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'userId',
        value: '',
      ));
    });
  }
}

extension StudyStreakQueryObject
    on QueryBuilder<StudyStreak, StudyStreak, QFilterCondition> {}

extension StudyStreakQueryLinks
    on QueryBuilder<StudyStreak, StudyStreak, QFilterCondition> {}

extension StudyStreakQuerySortBy
    on QueryBuilder<StudyStreak, StudyStreak, QSortBy> {
  QueryBuilder<StudyStreak, StudyStreak, QAfterSortBy> sortByCurrentStreak() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currentStreak', Sort.asc);
    });
  }

  QueryBuilder<StudyStreak, StudyStreak, QAfterSortBy>
      sortByCurrentStreakDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currentStreak', Sort.desc);
    });
  }

  QueryBuilder<StudyStreak, StudyStreak, QAfterSortBy> sortByLastStudyDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastStudyDate', Sort.asc);
    });
  }

  QueryBuilder<StudyStreak, StudyStreak, QAfterSortBy>
      sortByLastStudyDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastStudyDate', Sort.desc);
    });
  }

  QueryBuilder<StudyStreak, StudyStreak, QAfterSortBy> sortByLongestStreak() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'longestStreak', Sort.asc);
    });
  }

  QueryBuilder<StudyStreak, StudyStreak, QAfterSortBy>
      sortByLongestStreakDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'longestStreak', Sort.desc);
    });
  }

  QueryBuilder<StudyStreak, StudyStreak, QAfterSortBy> sortByTotalStudyDays() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalStudyDays', Sort.asc);
    });
  }

  QueryBuilder<StudyStreak, StudyStreak, QAfterSortBy>
      sortByTotalStudyDaysDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalStudyDays', Sort.desc);
    });
  }

  QueryBuilder<StudyStreak, StudyStreak, QAfterSortBy> sortByUserId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userId', Sort.asc);
    });
  }

  QueryBuilder<StudyStreak, StudyStreak, QAfterSortBy> sortByUserIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userId', Sort.desc);
    });
  }
}

extension StudyStreakQuerySortThenBy
    on QueryBuilder<StudyStreak, StudyStreak, QSortThenBy> {
  QueryBuilder<StudyStreak, StudyStreak, QAfterSortBy> thenByCurrentStreak() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currentStreak', Sort.asc);
    });
  }

  QueryBuilder<StudyStreak, StudyStreak, QAfterSortBy>
      thenByCurrentStreakDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currentStreak', Sort.desc);
    });
  }

  QueryBuilder<StudyStreak, StudyStreak, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<StudyStreak, StudyStreak, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<StudyStreak, StudyStreak, QAfterSortBy> thenByLastStudyDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastStudyDate', Sort.asc);
    });
  }

  QueryBuilder<StudyStreak, StudyStreak, QAfterSortBy>
      thenByLastStudyDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastStudyDate', Sort.desc);
    });
  }

  QueryBuilder<StudyStreak, StudyStreak, QAfterSortBy> thenByLongestStreak() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'longestStreak', Sort.asc);
    });
  }

  QueryBuilder<StudyStreak, StudyStreak, QAfterSortBy>
      thenByLongestStreakDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'longestStreak', Sort.desc);
    });
  }

  QueryBuilder<StudyStreak, StudyStreak, QAfterSortBy> thenByTotalStudyDays() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalStudyDays', Sort.asc);
    });
  }

  QueryBuilder<StudyStreak, StudyStreak, QAfterSortBy>
      thenByTotalStudyDaysDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalStudyDays', Sort.desc);
    });
  }

  QueryBuilder<StudyStreak, StudyStreak, QAfterSortBy> thenByUserId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userId', Sort.asc);
    });
  }

  QueryBuilder<StudyStreak, StudyStreak, QAfterSortBy> thenByUserIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userId', Sort.desc);
    });
  }
}

extension StudyStreakQueryWhereDistinct
    on QueryBuilder<StudyStreak, StudyStreak, QDistinct> {
  QueryBuilder<StudyStreak, StudyStreak, QDistinct> distinctByCurrentStreak() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'currentStreak');
    });
  }

  QueryBuilder<StudyStreak, StudyStreak, QDistinct> distinctByLastStudyDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastStudyDate');
    });
  }

  QueryBuilder<StudyStreak, StudyStreak, QDistinct> distinctByLongestStreak() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'longestStreak');
    });
  }

  QueryBuilder<StudyStreak, StudyStreak, QDistinct> distinctByStudyHistory() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'studyHistory');
    });
  }

  QueryBuilder<StudyStreak, StudyStreak, QDistinct> distinctByTotalStudyDays() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'totalStudyDays');
    });
  }

  QueryBuilder<StudyStreak, StudyStreak, QDistinct> distinctByUserId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'userId', caseSensitive: caseSensitive);
    });
  }
}

extension StudyStreakQueryProperty
    on QueryBuilder<StudyStreak, StudyStreak, QQueryProperty> {
  QueryBuilder<StudyStreak, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<StudyStreak, int, QQueryOperations> currentStreakProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'currentStreak');
    });
  }

  QueryBuilder<StudyStreak, DateTime?, QQueryOperations>
      lastStudyDateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastStudyDate');
    });
  }

  QueryBuilder<StudyStreak, int, QQueryOperations> longestStreakProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'longestStreak');
    });
  }

  QueryBuilder<StudyStreak, List<DateTime>, QQueryOperations>
      studyHistoryProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'studyHistory');
    });
  }

  QueryBuilder<StudyStreak, int, QQueryOperations> totalStudyDaysProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'totalStudyDays');
    });
  }

  QueryBuilder<StudyStreak, String?, QQueryOperations> userIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'userId');
    });
  }
}
