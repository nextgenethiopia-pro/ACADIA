// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'achievement.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetAchievementCollection on Isar {
  IsarCollection<Achievement> get achievements => this.collection();
}

const AchievementSchema = CollectionSchema(
  name: r'Achievement',
  id: -1910108531206464,
  properties: {
    r'badgeName': PropertySchema(
      id: 0,
      name: r'badgeName',
      type: IsarType.string,
    ),
    r'isUnlocked': PropertySchema(
      id: 1,
      name: r'isUnlocked',
      type: IsarType.bool,
    ),
    r'unlockedDate': PropertySchema(
      id: 2,
      name: r'unlockedDate',
      type: IsarType.dateTime,
    ),
    r'userId': PropertySchema(
      id: 3,
      name: r'userId',
      type: IsarType.string,
    )
  },
  estimateSize: _achievementEstimateSize,
  serialize: _achievementSerialize,
  deserialize: _achievementDeserialize,
  deserializeProp: _achievementDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},
  getId: _achievementGetId,
  getLinks: _achievementGetLinks,
  attach: _achievementAttach,
  version: '3.1.0+1',
);

int _achievementEstimateSize(
  Achievement object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.badgeName;
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

void _achievementSerialize(
  Achievement object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.badgeName);
  writer.writeBool(offsets[1], object.isUnlocked);
  writer.writeDateTime(offsets[2], object.unlockedDate);
  writer.writeString(offsets[3], object.userId);
}

Achievement _achievementDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = Achievement();
  object.badgeName = reader.readStringOrNull(offsets[0]);
  object.id = id;
  object.isUnlocked = reader.readBoolOrNull(offsets[1]);
  object.unlockedDate = reader.readDateTimeOrNull(offsets[2]);
  object.userId = reader.readStringOrNull(offsets[3]);
  return object;
}

P _achievementDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringOrNull(offset)) as P;
    case 1:
      return (reader.readBoolOrNull(offset)) as P;
    case 2:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 3:
      return (reader.readStringOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _achievementGetId(Achievement object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _achievementGetLinks(Achievement object) {
  return [];
}

void _achievementAttach(
    IsarCollection<dynamic> col, Id id, Achievement object) {
  object.id = id;
}

extension AchievementQueryWhereSort
    on QueryBuilder<Achievement, Achievement, QWhere> {
  QueryBuilder<Achievement, Achievement, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension AchievementQueryWhere
    on QueryBuilder<Achievement, Achievement, QWhereClause> {
  QueryBuilder<Achievement, Achievement, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<Achievement, Achievement, QAfterWhereClause> idNotEqualTo(
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

  QueryBuilder<Achievement, Achievement, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<Achievement, Achievement, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<Achievement, Achievement, QAfterWhereClause> idBetween(
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

extension AchievementQueryFilter
    on QueryBuilder<Achievement, Achievement, QFilterCondition> {
  QueryBuilder<Achievement, Achievement, QAfterFilterCondition>
      badgeNameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'badgeName',
      ));
    });
  }

  QueryBuilder<Achievement, Achievement, QAfterFilterCondition>
      badgeNameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'badgeName',
      ));
    });
  }

  QueryBuilder<Achievement, Achievement, QAfterFilterCondition>
      badgeNameEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'badgeName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Achievement, Achievement, QAfterFilterCondition>
      badgeNameGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'badgeName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Achievement, Achievement, QAfterFilterCondition>
      badgeNameLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'badgeName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Achievement, Achievement, QAfterFilterCondition>
      badgeNameBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'badgeName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Achievement, Achievement, QAfterFilterCondition>
      badgeNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'badgeName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Achievement, Achievement, QAfterFilterCondition>
      badgeNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'badgeName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Achievement, Achievement, QAfterFilterCondition>
      badgeNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'badgeName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Achievement, Achievement, QAfterFilterCondition>
      badgeNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'badgeName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Achievement, Achievement, QAfterFilterCondition>
      badgeNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'badgeName',
        value: '',
      ));
    });
  }

  QueryBuilder<Achievement, Achievement, QAfterFilterCondition>
      badgeNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'badgeName',
        value: '',
      ));
    });
  }

  QueryBuilder<Achievement, Achievement, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<Achievement, Achievement, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<Achievement, Achievement, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<Achievement, Achievement, QAfterFilterCondition> idBetween(
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

  QueryBuilder<Achievement, Achievement, QAfterFilterCondition>
      isUnlockedIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'isUnlocked',
      ));
    });
  }

  QueryBuilder<Achievement, Achievement, QAfterFilterCondition>
      isUnlockedIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'isUnlocked',
      ));
    });
  }

  QueryBuilder<Achievement, Achievement, QAfterFilterCondition>
      isUnlockedEqualTo(bool? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isUnlocked',
        value: value,
      ));
    });
  }

  QueryBuilder<Achievement, Achievement, QAfterFilterCondition>
      unlockedDateIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'unlockedDate',
      ));
    });
  }

  QueryBuilder<Achievement, Achievement, QAfterFilterCondition>
      unlockedDateIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'unlockedDate',
      ));
    });
  }

  QueryBuilder<Achievement, Achievement, QAfterFilterCondition>
      unlockedDateEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'unlockedDate',
        value: value,
      ));
    });
  }

  QueryBuilder<Achievement, Achievement, QAfterFilterCondition>
      unlockedDateGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'unlockedDate',
        value: value,
      ));
    });
  }

  QueryBuilder<Achievement, Achievement, QAfterFilterCondition>
      unlockedDateLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'unlockedDate',
        value: value,
      ));
    });
  }

  QueryBuilder<Achievement, Achievement, QAfterFilterCondition>
      unlockedDateBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'unlockedDate',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Achievement, Achievement, QAfterFilterCondition> userIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'userId',
      ));
    });
  }

  QueryBuilder<Achievement, Achievement, QAfterFilterCondition>
      userIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'userId',
      ));
    });
  }

  QueryBuilder<Achievement, Achievement, QAfterFilterCondition> userIdEqualTo(
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

  QueryBuilder<Achievement, Achievement, QAfterFilterCondition>
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

  QueryBuilder<Achievement, Achievement, QAfterFilterCondition> userIdLessThan(
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

  QueryBuilder<Achievement, Achievement, QAfterFilterCondition> userIdBetween(
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

  QueryBuilder<Achievement, Achievement, QAfterFilterCondition>
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

  QueryBuilder<Achievement, Achievement, QAfterFilterCondition> userIdEndsWith(
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

  QueryBuilder<Achievement, Achievement, QAfterFilterCondition> userIdContains(
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

  QueryBuilder<Achievement, Achievement, QAfterFilterCondition> userIdMatches(
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

  QueryBuilder<Achievement, Achievement, QAfterFilterCondition>
      userIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'userId',
        value: '',
      ));
    });
  }

  QueryBuilder<Achievement, Achievement, QAfterFilterCondition>
      userIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'userId',
        value: '',
      ));
    });
  }
}

extension AchievementQueryObject
    on QueryBuilder<Achievement, Achievement, QFilterCondition> {}

extension AchievementQueryLinks
    on QueryBuilder<Achievement, Achievement, QFilterCondition> {}

extension AchievementQuerySortBy
    on QueryBuilder<Achievement, Achievement, QSortBy> {
  QueryBuilder<Achievement, Achievement, QAfterSortBy> sortByBadgeName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'badgeName', Sort.asc);
    });
  }

  QueryBuilder<Achievement, Achievement, QAfterSortBy> sortByBadgeNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'badgeName', Sort.desc);
    });
  }

  QueryBuilder<Achievement, Achievement, QAfterSortBy> sortByIsUnlocked() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isUnlocked', Sort.asc);
    });
  }

  QueryBuilder<Achievement, Achievement, QAfterSortBy> sortByIsUnlockedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isUnlocked', Sort.desc);
    });
  }

  QueryBuilder<Achievement, Achievement, QAfterSortBy> sortByUnlockedDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'unlockedDate', Sort.asc);
    });
  }

  QueryBuilder<Achievement, Achievement, QAfterSortBy>
      sortByUnlockedDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'unlockedDate', Sort.desc);
    });
  }

  QueryBuilder<Achievement, Achievement, QAfterSortBy> sortByUserId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userId', Sort.asc);
    });
  }

  QueryBuilder<Achievement, Achievement, QAfterSortBy> sortByUserIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userId', Sort.desc);
    });
  }
}

extension AchievementQuerySortThenBy
    on QueryBuilder<Achievement, Achievement, QSortThenBy> {
  QueryBuilder<Achievement, Achievement, QAfterSortBy> thenByBadgeName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'badgeName', Sort.asc);
    });
  }

  QueryBuilder<Achievement, Achievement, QAfterSortBy> thenByBadgeNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'badgeName', Sort.desc);
    });
  }

  QueryBuilder<Achievement, Achievement, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<Achievement, Achievement, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<Achievement, Achievement, QAfterSortBy> thenByIsUnlocked() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isUnlocked', Sort.asc);
    });
  }

  QueryBuilder<Achievement, Achievement, QAfterSortBy> thenByIsUnlockedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isUnlocked', Sort.desc);
    });
  }

  QueryBuilder<Achievement, Achievement, QAfterSortBy> thenByUnlockedDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'unlockedDate', Sort.asc);
    });
  }

  QueryBuilder<Achievement, Achievement, QAfterSortBy>
      thenByUnlockedDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'unlockedDate', Sort.desc);
    });
  }

  QueryBuilder<Achievement, Achievement, QAfterSortBy> thenByUserId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userId', Sort.asc);
    });
  }

  QueryBuilder<Achievement, Achievement, QAfterSortBy> thenByUserIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userId', Sort.desc);
    });
  }
}

extension AchievementQueryWhereDistinct
    on QueryBuilder<Achievement, Achievement, QDistinct> {
  QueryBuilder<Achievement, Achievement, QDistinct> distinctByBadgeName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'badgeName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Achievement, Achievement, QDistinct> distinctByIsUnlocked() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isUnlocked');
    });
  }

  QueryBuilder<Achievement, Achievement, QDistinct> distinctByUnlockedDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'unlockedDate');
    });
  }

  QueryBuilder<Achievement, Achievement, QDistinct> distinctByUserId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'userId', caseSensitive: caseSensitive);
    });
  }
}

extension AchievementQueryProperty
    on QueryBuilder<Achievement, Achievement, QQueryProperty> {
  QueryBuilder<Achievement, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<Achievement, String?, QQueryOperations> badgeNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'badgeName');
    });
  }

  QueryBuilder<Achievement, bool?, QQueryOperations> isUnlockedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isUnlocked');
    });
  }

  QueryBuilder<Achievement, DateTime?, QQueryOperations>
      unlockedDateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'unlockedDate');
    });
  }

  QueryBuilder<Achievement, String?, QQueryOperations> userIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'userId');
    });
  }
}
