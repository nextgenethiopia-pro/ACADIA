// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subject_progress.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetSubjectProgressCollection on Isar {
  IsarCollection<SubjectProgress> get subjectProgress => this.collection();
}

const SubjectProgressSchema = CollectionSchema(
  name: r'SubjectProgress',
  id: 7478109582456005,
  properties: {
    r'completionPercentage': PropertySchema(
      id: 0,
      name: r'completionPercentage',
      type: IsarType.double,
    ),
    r'lessonsCompleted': PropertySchema(
      id: 1,
      name: r'lessonsCompleted',
      type: IsarType.long,
    ),
    r'subject': PropertySchema(
      id: 2,
      name: r'subject',
      type: IsarType.string,
    ),
    r'totalLessons': PropertySchema(
      id: 3,
      name: r'totalLessons',
      type: IsarType.long,
    ),
    r'userId': PropertySchema(
      id: 4,
      name: r'userId',
      type: IsarType.string,
    )
  },
  estimateSize: _subjectProgressEstimateSize,
  serialize: _subjectProgressSerialize,
  deserialize: _subjectProgressDeserialize,
  deserializeProp: _subjectProgressDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},
  getId: _subjectProgressGetId,
  getLinks: _subjectProgressGetLinks,
  attach: _subjectProgressAttach,
  version: '3.1.0+1',
);

int _subjectProgressEstimateSize(
  SubjectProgress object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.subject;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.userId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _subjectProgressSerialize(
  SubjectProgress object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDouble(offsets[0], object.completionPercentage);
  writer.writeLong(offsets[1], object.lessonsCompleted);
  writer.writeString(offsets[2], object.subject);
  writer.writeLong(offsets[3], object.totalLessons);
  writer.writeString(offsets[4], object.userId);
}

SubjectProgress _subjectProgressDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = SubjectProgress();
  object.completionPercentage = reader.readDoubleOrNull(offsets[0]);
  object.id = id;
  object.lessonsCompleted = reader.readLongOrNull(offsets[1]);
  object.subject = reader.readStringOrNull(offsets[2]);
  object.totalLessons = reader.readLongOrNull(offsets[3]);
  object.userId = reader.readStringOrNull(offsets[4]);
  return object;
}

P _subjectProgressDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDoubleOrNull(offset)) as P;
    case 1:
      return (reader.readLongOrNull(offset)) as P;
    case 2:
      return (reader.readStringOrNull(offset)) as P;
    case 3:
      return (reader.readLongOrNull(offset)) as P;
    case 4:
      return (reader.readStringOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _subjectProgressGetId(SubjectProgress object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _subjectProgressGetLinks(SubjectProgress object) {
  return [];
}

void _subjectProgressAttach(
    IsarCollection<dynamic> col, Id id, SubjectProgress object) {
  object.id = id;
}

extension SubjectProgressQueryWhereSort
    on QueryBuilder<SubjectProgress, SubjectProgress, QWhere> {
  QueryBuilder<SubjectProgress, SubjectProgress, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension SubjectProgressQueryWhere
    on QueryBuilder<SubjectProgress, SubjectProgress, QWhereClause> {
  QueryBuilder<SubjectProgress, SubjectProgress, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<SubjectProgress, SubjectProgress, QAfterWhereClause>
      idNotEqualTo(Id id) {
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

  QueryBuilder<SubjectProgress, SubjectProgress, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<SubjectProgress, SubjectProgress, QAfterWhereClause> idLessThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<SubjectProgress, SubjectProgress, QAfterWhereClause> idBetween(
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

extension SubjectProgressQueryFilter
    on QueryBuilder<SubjectProgress, SubjectProgress, QFilterCondition> {
  QueryBuilder<SubjectProgress, SubjectProgress, QAfterFilterCondition>
      completionPercentageIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'completionPercentage',
      ));
    });
  }

  QueryBuilder<SubjectProgress, SubjectProgress, QAfterFilterCondition>
      completionPercentageIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'completionPercentage',
      ));
    });
  }

  QueryBuilder<SubjectProgress, SubjectProgress, QAfterFilterCondition>
      completionPercentageEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'completionPercentage',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<SubjectProgress, SubjectProgress, QAfterFilterCondition>
      completionPercentageGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'completionPercentage',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<SubjectProgress, SubjectProgress, QAfterFilterCondition>
      completionPercentageLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'completionPercentage',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<SubjectProgress, SubjectProgress, QAfterFilterCondition>
      completionPercentageBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'completionPercentage',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<SubjectProgress, SubjectProgress, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<SubjectProgress, SubjectProgress, QAfterFilterCondition>
      idGreaterThan(
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

  QueryBuilder<SubjectProgress, SubjectProgress, QAfterFilterCondition>
      idLessThan(
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

  QueryBuilder<SubjectProgress, SubjectProgress, QAfterFilterCondition>
      idBetween(
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

  QueryBuilder<SubjectProgress, SubjectProgress, QAfterFilterCondition>
      lessonsCompletedIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'lessonsCompleted',
      ));
    });
  }

  QueryBuilder<SubjectProgress, SubjectProgress, QAfterFilterCondition>
      lessonsCompletedIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'lessonsCompleted',
      ));
    });
  }

  QueryBuilder<SubjectProgress, SubjectProgress, QAfterFilterCondition>
      lessonsCompletedEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lessonsCompleted',
        value: value,
      ));
    });
  }

  QueryBuilder<SubjectProgress, SubjectProgress, QAfterFilterCondition>
      lessonsCompletedGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lessonsCompleted',
        value: value,
      ));
    });
  }

  QueryBuilder<SubjectProgress, SubjectProgress, QAfterFilterCondition>
      lessonsCompletedLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lessonsCompleted',
        value: value,
      ));
    });
  }

  QueryBuilder<SubjectProgress, SubjectProgress, QAfterFilterCondition>
      lessonsCompletedBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lessonsCompleted',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<SubjectProgress, SubjectProgress, QAfterFilterCondition>
      subjectIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'subject',
      ));
    });
  }

  QueryBuilder<SubjectProgress, SubjectProgress, QAfterFilterCondition>
      subjectIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'subject',
      ));
    });
  }

  QueryBuilder<SubjectProgress, SubjectProgress, QAfterFilterCondition>
      subjectEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'subject',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SubjectProgress, SubjectProgress, QAfterFilterCondition>
      subjectGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'subject',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SubjectProgress, SubjectProgress, QAfterFilterCondition>
      subjectLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'subject',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SubjectProgress, SubjectProgress, QAfterFilterCondition>
      subjectBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'subject',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SubjectProgress, SubjectProgress, QAfterFilterCondition>
      subjectStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'subject',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SubjectProgress, SubjectProgress, QAfterFilterCondition>
      subjectEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'subject',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SubjectProgress, SubjectProgress, QAfterFilterCondition>
      subjectContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'subject',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SubjectProgress, SubjectProgress, QAfterFilterCondition>
      subjectMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'subject',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SubjectProgress, SubjectProgress, QAfterFilterCondition>
      subjectIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'subject',
        value: '',
      ));
    });
  }

  QueryBuilder<SubjectProgress, SubjectProgress, QAfterFilterCondition>
      subjectIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'subject',
        value: '',
      ));
    });
  }

  QueryBuilder<SubjectProgress, SubjectProgress, QAfterFilterCondition>
      totalLessonsIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'totalLessons',
      ));
    });
  }

  QueryBuilder<SubjectProgress, SubjectProgress, QAfterFilterCondition>
      totalLessonsIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'totalLessons',
      ));
    });
  }

  QueryBuilder<SubjectProgress, SubjectProgress, QAfterFilterCondition>
      totalLessonsEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'totalLessons',
        value: value,
      ));
    });
  }

  QueryBuilder<SubjectProgress, SubjectProgress, QAfterFilterCondition>
      totalLessonsGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'totalLessons',
        value: value,
      ));
    });
  }

  QueryBuilder<SubjectProgress, SubjectProgress, QAfterFilterCondition>
      totalLessonsLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'totalLessons',
        value: value,
      ));
    });
  }

  QueryBuilder<SubjectProgress, SubjectProgress, QAfterFilterCondition>
      totalLessonsBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'totalLessons',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<SubjectProgress, SubjectProgress, QAfterFilterCondition>
      userIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'userId',
      ));
    });
  }

  QueryBuilder<SubjectProgress, SubjectProgress, QAfterFilterCondition>
      userIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'userId',
      ));
    });
  }

  QueryBuilder<SubjectProgress, SubjectProgress, QAfterFilterCondition>
      userIdEqualTo(
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

  QueryBuilder<SubjectProgress, SubjectProgress, QAfterFilterCondition>
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

  QueryBuilder<SubjectProgress, SubjectProgress, QAfterFilterCondition>
      userIdLessThan(
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

  QueryBuilder<SubjectProgress, SubjectProgress, QAfterFilterCondition>
      userIdBetween(
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

  QueryBuilder<SubjectProgress, SubjectProgress, QAfterFilterCondition>
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

  QueryBuilder<SubjectProgress, SubjectProgress, QAfterFilterCondition>
      userIdEndsWith(
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

  QueryBuilder<SubjectProgress, SubjectProgress, QAfterFilterCondition>
      userIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'userId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SubjectProgress, SubjectProgress, QAfterFilterCondition>
      userIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'userId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SubjectProgress, SubjectProgress, QAfterFilterCondition>
      userIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'userId',
        value: '',
      ));
    });
  }

  QueryBuilder<SubjectProgress, SubjectProgress, QAfterFilterCondition>
      userIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'userId',
        value: '',
      ));
    });
  }
}

extension SubjectProgressQueryObject
    on QueryBuilder<SubjectProgress, SubjectProgress, QFilterCondition> {}

extension SubjectProgressQueryLinks
    on QueryBuilder<SubjectProgress, SubjectProgress, QFilterCondition> {}

extension SubjectProgressQuerySortBy
    on QueryBuilder<SubjectProgress, SubjectProgress, QSortBy> {
  QueryBuilder<SubjectProgress, SubjectProgress, QAfterSortBy>
      sortByCompletionPercentage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'completionPercentage', Sort.asc);
    });
  }

  QueryBuilder<SubjectProgress, SubjectProgress, QAfterSortBy>
      sortByCompletionPercentageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'completionPercentage', Sort.desc);
    });
  }

  QueryBuilder<SubjectProgress, SubjectProgress, QAfterSortBy>
      sortByLessonsCompleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lessonsCompleted', Sort.asc);
    });
  }

  QueryBuilder<SubjectProgress, SubjectProgress, QAfterSortBy>
      sortByLessonsCompletedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lessonsCompleted', Sort.desc);
    });
  }

  QueryBuilder<SubjectProgress, SubjectProgress, QAfterSortBy> sortBySubject() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subject', Sort.asc);
    });
  }

  QueryBuilder<SubjectProgress, SubjectProgress, QAfterSortBy>
      sortBySubjectDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subject', Sort.desc);
    });
  }

  QueryBuilder<SubjectProgress, SubjectProgress, QAfterSortBy>
      sortByTotalLessons() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalLessons', Sort.asc);
    });
  }

  QueryBuilder<SubjectProgress, SubjectProgress, QAfterSortBy>
      sortByTotalLessonsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalLessons', Sort.desc);
    });
  }

  QueryBuilder<SubjectProgress, SubjectProgress, QAfterSortBy> sortByUserId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userId', Sort.asc);
    });
  }

  QueryBuilder<SubjectProgress, SubjectProgress, QAfterSortBy>
      sortByUserIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userId', Sort.desc);
    });
  }
}

extension SubjectProgressQuerySortThenBy
    on QueryBuilder<SubjectProgress, SubjectProgress, QSortThenBy> {
  QueryBuilder<SubjectProgress, SubjectProgress, QAfterSortBy>
      thenByCompletionPercentage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'completionPercentage', Sort.asc);
    });
  }

  QueryBuilder<SubjectProgress, SubjectProgress, QAfterSortBy>
      thenByCompletionPercentageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'completionPercentage', Sort.desc);
    });
  }

  QueryBuilder<SubjectProgress, SubjectProgress, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<SubjectProgress, SubjectProgress, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<SubjectProgress, SubjectProgress, QAfterSortBy>
      thenByLessonsCompleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lessonsCompleted', Sort.asc);
    });
  }

  QueryBuilder<SubjectProgress, SubjectProgress, QAfterSortBy>
      thenByLessonsCompletedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lessonsCompleted', Sort.desc);
    });
  }

  QueryBuilder<SubjectProgress, SubjectProgress, QAfterSortBy> thenBySubject() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subject', Sort.asc);
    });
  }

  QueryBuilder<SubjectProgress, SubjectProgress, QAfterSortBy>
      thenBySubjectDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subject', Sort.desc);
    });
  }

  QueryBuilder<SubjectProgress, SubjectProgress, QAfterSortBy>
      thenByTotalLessons() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalLessons', Sort.asc);
    });
  }

  QueryBuilder<SubjectProgress, SubjectProgress, QAfterSortBy>
      thenByTotalLessonsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalLessons', Sort.desc);
    });
  }

  QueryBuilder<SubjectProgress, SubjectProgress, QAfterSortBy> thenByUserId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userId', Sort.asc);
    });
  }

  QueryBuilder<SubjectProgress, SubjectProgress, QAfterSortBy>
      thenByUserIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userId', Sort.desc);
    });
  }
}

extension SubjectProgressQueryWhereDistinct
    on QueryBuilder<SubjectProgress, SubjectProgress, QDistinct> {
  QueryBuilder<SubjectProgress, SubjectProgress, QDistinct>
      distinctByCompletionPercentage() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'completionPercentage');
    });
  }

  QueryBuilder<SubjectProgress, SubjectProgress, QDistinct>
      distinctByLessonsCompleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lessonsCompleted');
    });
  }

  QueryBuilder<SubjectProgress, SubjectProgress, QDistinct> distinctBySubject(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'subject', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SubjectProgress, SubjectProgress, QDistinct>
      distinctByTotalLessons() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'totalLessons');
    });
  }

  QueryBuilder<SubjectProgress, SubjectProgress, QDistinct> distinctByUserId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'userId', caseSensitive: caseSensitive);
    });
  }
}

extension SubjectProgressQueryProperty
    on QueryBuilder<SubjectProgress, SubjectProgress, QQueryProperty> {
  QueryBuilder<SubjectProgress, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<SubjectProgress, double?, QQueryOperations>
      completionPercentageProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'completionPercentage');
    });
  }

  QueryBuilder<SubjectProgress, int?, QQueryOperations>
      lessonsCompletedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lessonsCompleted');
    });
  }

  QueryBuilder<SubjectProgress, String?, QQueryOperations> subjectProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'subject');
    });
  }

  QueryBuilder<SubjectProgress, int?, QQueryOperations> totalLessonsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'totalLessons');
    });
  }

  QueryBuilder<SubjectProgress, String?, QQueryOperations> userIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'userId');
    });
  }
}
