// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_progress.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetUserProgressCollection on Isar {
  IsarCollection<UserProgress> get userProgress => this.collection();
}

const UserProgressSchema = CollectionSchema(
  name: r'UserProgress',
  id: 5547942932469550,
  properties: {
    r'averageScore': PropertySchema(
      id: 0,
      name: r'averageScore',
      type: IsarType.double,
    ),
    r'currentStreak': PropertySchema(
      id: 1,
      name: r'currentStreak',
      type: IsarType.long,
    ),
    r'lastStudyDate': PropertySchema(
      id: 2,
      name: r'lastStudyDate',
      type: IsarType.dateTime,
    ),
    r'lessonsCompleted': PropertySchema(
      id: 3,
      name: r'lessonsCompleted',
      type: IsarType.long,
    ),
    r'longestStreak': PropertySchema(
      id: 4,
      name: r'longestStreak',
      type: IsarType.long,
    ),
    r'quizzesPassed': PropertySchema(
      id: 5,
      name: r'quizzesPassed',
      type: IsarType.long,
    ),
    r'totalStudyTime': PropertySchema(
      id: 6,
      name: r'totalStudyTime',
      type: IsarType.long,
    ),
    r'userId': PropertySchema(
      id: 7,
      name: r'userId',
      type: IsarType.string,
    )
  },
  estimateSize: _userProgressEstimateSize,
  serialize: _userProgressSerialize,
  deserialize: _userProgressDeserialize,
  deserializeProp: _userProgressDeserializeProp,
  idName: r'id',
  indexes: {
    r'userId': IndexSchema(
      id: -2778856404866178,
      name: r'userId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'userId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _userProgressGetId,
  getLinks: _userProgressGetLinks,
  attach: _userProgressAttach,
  version: '3.1.0+1',
);

int _userProgressEstimateSize(
  UserProgress object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.userId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _userProgressSerialize(
  UserProgress object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDouble(offsets[0], object.averageScore);
  writer.writeLong(offsets[1], object.currentStreak);
  writer.writeDateTime(offsets[2], object.lastStudyDate);
  writer.writeLong(offsets[3], object.lessonsCompleted);
  writer.writeLong(offsets[4], object.longestStreak);
  writer.writeLong(offsets[5], object.quizzesPassed);
  writer.writeLong(offsets[6], object.totalStudyTime);
  writer.writeString(offsets[7], object.userId);
}

UserProgress _userProgressDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = UserProgress();
  object.averageScore = reader.readDouble(offsets[0]);
  object.currentStreak = reader.readLong(offsets[1]);
  object.id = id;
  object.lastStudyDate = reader.readDateTimeOrNull(offsets[2]);
  object.lessonsCompleted = reader.readLong(offsets[3]);
  object.longestStreak = reader.readLong(offsets[4]);
  object.quizzesPassed = reader.readLong(offsets[5]);
  object.totalStudyTime = reader.readLong(offsets[6]);
  object.userId = reader.readStringOrNull(offsets[7]);
  return object;
}

P _userProgressDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDouble(offset)) as P;
    case 1:
      return (reader.readLong(offset)) as P;
    case 2:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 3:
      return (reader.readLong(offset)) as P;
    case 4:
      return (reader.readLong(offset)) as P;
    case 5:
      return (reader.readLong(offset)) as P;
    case 6:
      return (reader.readLong(offset)) as P;
    case 7:
      return (reader.readStringOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _userProgressGetId(UserProgress object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _userProgressGetLinks(UserProgress object) {
  return [];
}

void _userProgressAttach(
    IsarCollection<dynamic> col, Id id, UserProgress object) {
  object.id = id;
}

extension UserProgressQueryWhereSort
    on QueryBuilder<UserProgress, UserProgress, QWhere> {
  QueryBuilder<UserProgress, UserProgress, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension UserProgressQueryWhere
    on QueryBuilder<UserProgress, UserProgress, QWhereClause> {
  QueryBuilder<UserProgress, UserProgress, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<UserProgress, UserProgress, QAfterWhereClause> idNotEqualTo(
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

  QueryBuilder<UserProgress, UserProgress, QAfterWhereClause> idGreaterThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<UserProgress, UserProgress, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<UserProgress, UserProgress, QAfterWhereClause> idBetween(
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

  QueryBuilder<UserProgress, UserProgress, QAfterWhereClause> userIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'userId',
        value: [null],
      ));
    });
  }

  QueryBuilder<UserProgress, UserProgress, QAfterWhereClause>
      userIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'userId',
        lower: [null],
        includeLower: false,
        upper: [],
      ));
    });
  }

  QueryBuilder<UserProgress, UserProgress, QAfterWhereClause> userIdEqualTo(
      String? userId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'userId',
        value: [userId],
      ));
    });
  }

  QueryBuilder<UserProgress, UserProgress, QAfterWhereClause> userIdNotEqualTo(
      String? userId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'userId',
              lower: [],
              upper: [userId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'userId',
              lower: [userId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'userId',
              lower: [userId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'userId',
              lower: [],
              upper: [userId],
              includeUpper: false,
            ));
      }
    });
  }
}

extension UserProgressQueryFilter
    on QueryBuilder<UserProgress, UserProgress, QFilterCondition> {
  QueryBuilder<UserProgress, UserProgress, QAfterFilterCondition>
      averageScoreEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'averageScore',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<UserProgress, UserProgress, QAfterFilterCondition>
      averageScoreGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'averageScore',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<UserProgress, UserProgress, QAfterFilterCondition>
      averageScoreLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'averageScore',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<UserProgress, UserProgress, QAfterFilterCondition>
      averageScoreBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'averageScore',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<UserProgress, UserProgress, QAfterFilterCondition>
      currentStreakEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'currentStreak',
        value: value,
      ));
    });
  }

  QueryBuilder<UserProgress, UserProgress, QAfterFilterCondition>
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

  QueryBuilder<UserProgress, UserProgress, QAfterFilterCondition>
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

  QueryBuilder<UserProgress, UserProgress, QAfterFilterCondition>
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

  QueryBuilder<UserProgress, UserProgress, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<UserProgress, UserProgress, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<UserProgress, UserProgress, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<UserProgress, UserProgress, QAfterFilterCondition> idBetween(
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

  QueryBuilder<UserProgress, UserProgress, QAfterFilterCondition>
      lastStudyDateIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'lastStudyDate',
      ));
    });
  }

  QueryBuilder<UserProgress, UserProgress, QAfterFilterCondition>
      lastStudyDateIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'lastStudyDate',
      ));
    });
  }

  QueryBuilder<UserProgress, UserProgress, QAfterFilterCondition>
      lastStudyDateEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastStudyDate',
        value: value,
      ));
    });
  }

  QueryBuilder<UserProgress, UserProgress, QAfterFilterCondition>
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

  QueryBuilder<UserProgress, UserProgress, QAfterFilterCondition>
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

  QueryBuilder<UserProgress, UserProgress, QAfterFilterCondition>
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

  QueryBuilder<UserProgress, UserProgress, QAfterFilterCondition>
      lessonsCompletedEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lessonsCompleted',
        value: value,
      ));
    });
  }

  QueryBuilder<UserProgress, UserProgress, QAfterFilterCondition>
      lessonsCompletedGreaterThan(
    int value, {
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

  QueryBuilder<UserProgress, UserProgress, QAfterFilterCondition>
      lessonsCompletedLessThan(
    int value, {
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

  QueryBuilder<UserProgress, UserProgress, QAfterFilterCondition>
      lessonsCompletedBetween(
    int lower,
    int upper, {
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

  QueryBuilder<UserProgress, UserProgress, QAfterFilterCondition>
      longestStreakEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'longestStreak',
        value: value,
      ));
    });
  }

  QueryBuilder<UserProgress, UserProgress, QAfterFilterCondition>
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

  QueryBuilder<UserProgress, UserProgress, QAfterFilterCondition>
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

  QueryBuilder<UserProgress, UserProgress, QAfterFilterCondition>
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

  QueryBuilder<UserProgress, UserProgress, QAfterFilterCondition>
      quizzesPassedEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'quizzesPassed',
        value: value,
      ));
    });
  }

  QueryBuilder<UserProgress, UserProgress, QAfterFilterCondition>
      quizzesPassedGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'quizzesPassed',
        value: value,
      ));
    });
  }

  QueryBuilder<UserProgress, UserProgress, QAfterFilterCondition>
      quizzesPassedLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'quizzesPassed',
        value: value,
      ));
    });
  }

  QueryBuilder<UserProgress, UserProgress, QAfterFilterCondition>
      quizzesPassedBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'quizzesPassed',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<UserProgress, UserProgress, QAfterFilterCondition>
      totalStudyTimeEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'totalStudyTime',
        value: value,
      ));
    });
  }

  QueryBuilder<UserProgress, UserProgress, QAfterFilterCondition>
      totalStudyTimeGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'totalStudyTime',
        value: value,
      ));
    });
  }

  QueryBuilder<UserProgress, UserProgress, QAfterFilterCondition>
      totalStudyTimeLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'totalStudyTime',
        value: value,
      ));
    });
  }

  QueryBuilder<UserProgress, UserProgress, QAfterFilterCondition>
      totalStudyTimeBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'totalStudyTime',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<UserProgress, UserProgress, QAfterFilterCondition>
      userIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'userId',
      ));
    });
  }

  QueryBuilder<UserProgress, UserProgress, QAfterFilterCondition>
      userIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'userId',
      ));
    });
  }

  QueryBuilder<UserProgress, UserProgress, QAfterFilterCondition> userIdEqualTo(
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

  QueryBuilder<UserProgress, UserProgress, QAfterFilterCondition>
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

  QueryBuilder<UserProgress, UserProgress, QAfterFilterCondition>
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

  QueryBuilder<UserProgress, UserProgress, QAfterFilterCondition> userIdBetween(
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

  QueryBuilder<UserProgress, UserProgress, QAfterFilterCondition>
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

  QueryBuilder<UserProgress, UserProgress, QAfterFilterCondition>
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

  QueryBuilder<UserProgress, UserProgress, QAfterFilterCondition>
      userIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'userId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserProgress, UserProgress, QAfterFilterCondition> userIdMatches(
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

  QueryBuilder<UserProgress, UserProgress, QAfterFilterCondition>
      userIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'userId',
        value: '',
      ));
    });
  }

  QueryBuilder<UserProgress, UserProgress, QAfterFilterCondition>
      userIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'userId',
        value: '',
      ));
    });
  }
}

extension UserProgressQueryObject
    on QueryBuilder<UserProgress, UserProgress, QFilterCondition> {}

extension UserProgressQueryLinks
    on QueryBuilder<UserProgress, UserProgress, QFilterCondition> {}

extension UserProgressQuerySortBy
    on QueryBuilder<UserProgress, UserProgress, QSortBy> {
  QueryBuilder<UserProgress, UserProgress, QAfterSortBy> sortByAverageScore() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'averageScore', Sort.asc);
    });
  }

  QueryBuilder<UserProgress, UserProgress, QAfterSortBy>
      sortByAverageScoreDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'averageScore', Sort.desc);
    });
  }

  QueryBuilder<UserProgress, UserProgress, QAfterSortBy> sortByCurrentStreak() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currentStreak', Sort.asc);
    });
  }

  QueryBuilder<UserProgress, UserProgress, QAfterSortBy>
      sortByCurrentStreakDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currentStreak', Sort.desc);
    });
  }

  QueryBuilder<UserProgress, UserProgress, QAfterSortBy> sortByLastStudyDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastStudyDate', Sort.asc);
    });
  }

  QueryBuilder<UserProgress, UserProgress, QAfterSortBy>
      sortByLastStudyDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastStudyDate', Sort.desc);
    });
  }

  QueryBuilder<UserProgress, UserProgress, QAfterSortBy>
      sortByLessonsCompleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lessonsCompleted', Sort.asc);
    });
  }

  QueryBuilder<UserProgress, UserProgress, QAfterSortBy>
      sortByLessonsCompletedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lessonsCompleted', Sort.desc);
    });
  }

  QueryBuilder<UserProgress, UserProgress, QAfterSortBy> sortByLongestStreak() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'longestStreak', Sort.asc);
    });
  }

  QueryBuilder<UserProgress, UserProgress, QAfterSortBy>
      sortByLongestStreakDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'longestStreak', Sort.desc);
    });
  }

  QueryBuilder<UserProgress, UserProgress, QAfterSortBy> sortByQuizzesPassed() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'quizzesPassed', Sort.asc);
    });
  }

  QueryBuilder<UserProgress, UserProgress, QAfterSortBy>
      sortByQuizzesPassedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'quizzesPassed', Sort.desc);
    });
  }

  QueryBuilder<UserProgress, UserProgress, QAfterSortBy>
      sortByTotalStudyTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalStudyTime', Sort.asc);
    });
  }

  QueryBuilder<UserProgress, UserProgress, QAfterSortBy>
      sortByTotalStudyTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalStudyTime', Sort.desc);
    });
  }

  QueryBuilder<UserProgress, UserProgress, QAfterSortBy> sortByUserId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userId', Sort.asc);
    });
  }

  QueryBuilder<UserProgress, UserProgress, QAfterSortBy> sortByUserIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userId', Sort.desc);
    });
  }
}

extension UserProgressQuerySortThenBy
    on QueryBuilder<UserProgress, UserProgress, QSortThenBy> {
  QueryBuilder<UserProgress, UserProgress, QAfterSortBy> thenByAverageScore() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'averageScore', Sort.asc);
    });
  }

  QueryBuilder<UserProgress, UserProgress, QAfterSortBy>
      thenByAverageScoreDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'averageScore', Sort.desc);
    });
  }

  QueryBuilder<UserProgress, UserProgress, QAfterSortBy> thenByCurrentStreak() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currentStreak', Sort.asc);
    });
  }

  QueryBuilder<UserProgress, UserProgress, QAfterSortBy>
      thenByCurrentStreakDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currentStreak', Sort.desc);
    });
  }

  QueryBuilder<UserProgress, UserProgress, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<UserProgress, UserProgress, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<UserProgress, UserProgress, QAfterSortBy> thenByLastStudyDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastStudyDate', Sort.asc);
    });
  }

  QueryBuilder<UserProgress, UserProgress, QAfterSortBy>
      thenByLastStudyDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastStudyDate', Sort.desc);
    });
  }

  QueryBuilder<UserProgress, UserProgress, QAfterSortBy>
      thenByLessonsCompleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lessonsCompleted', Sort.asc);
    });
  }

  QueryBuilder<UserProgress, UserProgress, QAfterSortBy>
      thenByLessonsCompletedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lessonsCompleted', Sort.desc);
    });
  }

  QueryBuilder<UserProgress, UserProgress, QAfterSortBy> thenByLongestStreak() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'longestStreak', Sort.asc);
    });
  }

  QueryBuilder<UserProgress, UserProgress, QAfterSortBy>
      thenByLongestStreakDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'longestStreak', Sort.desc);
    });
  }

  QueryBuilder<UserProgress, UserProgress, QAfterSortBy> thenByQuizzesPassed() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'quizzesPassed', Sort.asc);
    });
  }

  QueryBuilder<UserProgress, UserProgress, QAfterSortBy>
      thenByQuizzesPassedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'quizzesPassed', Sort.desc);
    });
  }

  QueryBuilder<UserProgress, UserProgress, QAfterSortBy>
      thenByTotalStudyTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalStudyTime', Sort.asc);
    });
  }

  QueryBuilder<UserProgress, UserProgress, QAfterSortBy>
      thenByTotalStudyTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalStudyTime', Sort.desc);
    });
  }

  QueryBuilder<UserProgress, UserProgress, QAfterSortBy> thenByUserId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userId', Sort.asc);
    });
  }

  QueryBuilder<UserProgress, UserProgress, QAfterSortBy> thenByUserIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userId', Sort.desc);
    });
  }
}

extension UserProgressQueryWhereDistinct
    on QueryBuilder<UserProgress, UserProgress, QDistinct> {
  QueryBuilder<UserProgress, UserProgress, QDistinct> distinctByAverageScore() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'averageScore');
    });
  }

  QueryBuilder<UserProgress, UserProgress, QDistinct>
      distinctByCurrentStreak() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'currentStreak');
    });
  }

  QueryBuilder<UserProgress, UserProgress, QDistinct>
      distinctByLastStudyDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastStudyDate');
    });
  }

  QueryBuilder<UserProgress, UserProgress, QDistinct>
      distinctByLessonsCompleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lessonsCompleted');
    });
  }

  QueryBuilder<UserProgress, UserProgress, QDistinct>
      distinctByLongestStreak() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'longestStreak');
    });
  }

  QueryBuilder<UserProgress, UserProgress, QDistinct>
      distinctByQuizzesPassed() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'quizzesPassed');
    });
  }

  QueryBuilder<UserProgress, UserProgress, QDistinct>
      distinctByTotalStudyTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'totalStudyTime');
    });
  }

  QueryBuilder<UserProgress, UserProgress, QDistinct> distinctByUserId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'userId', caseSensitive: caseSensitive);
    });
  }
}

extension UserProgressQueryProperty
    on QueryBuilder<UserProgress, UserProgress, QQueryProperty> {
  QueryBuilder<UserProgress, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<UserProgress, double, QQueryOperations> averageScoreProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'averageScore');
    });
  }

  QueryBuilder<UserProgress, int, QQueryOperations> currentStreakProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'currentStreak');
    });
  }

  QueryBuilder<UserProgress, DateTime?, QQueryOperations>
      lastStudyDateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastStudyDate');
    });
  }

  QueryBuilder<UserProgress, int, QQueryOperations> lessonsCompletedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lessonsCompleted');
    });
  }

  QueryBuilder<UserProgress, int, QQueryOperations> longestStreakProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'longestStreak');
    });
  }

  QueryBuilder<UserProgress, int, QQueryOperations> quizzesPassedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'quizzesPassed');
    });
  }

  QueryBuilder<UserProgress, int, QQueryOperations> totalStudyTimeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'totalStudyTime');
    });
  }

  QueryBuilder<UserProgress, String?, QQueryOperations> userIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'userId');
    });
  }
}
