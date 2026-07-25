// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exam_result.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetExamResultCollection on Isar {
  IsarCollection<ExamResult> get examResults => this.collection();
}

const ExamResultSchema = CollectionSchema(
  name: r'ExamResult',
  id: -7285210680264624,
  properties: {
    r'answers': PropertySchema(
      id: 0,
      name: r'answers',
      type: IsarType.objectList,
      target: r'QuestionAnswer',
    ),
    r'autoSubmitted': PropertySchema(
      id: 1,
      name: r'autoSubmitted',
      type: IsarType.bool,
    ),
    r'chapter': PropertySchema(
      id: 2,
      name: r'chapter',
      type: IsarType.string,
    ),
    r'correctCount': PropertySchema(
      id: 3,
      name: r'correctCount',
      type: IsarType.long,
    ),
    r'createdAt': PropertySchema(
      id: 4,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'examId': PropertySchema(
      id: 5,
      name: r'examId',
      type: IsarType.string,
    ),
    r'examTitle': PropertySchema(
      id: 6,
      name: r'examTitle',
      type: IsarType.string,
    ),
    r'grade': PropertySchema(
      id: 7,
      name: r'grade',
      type: IsarType.string,
    ),
    r'passed': PropertySchema(
      id: 8,
      name: r'passed',
      type: IsarType.bool,
    ),
    r'percentage': PropertySchema(
      id: 9,
      name: r'percentage',
      type: IsarType.double,
    ),
    r'score': PropertySchema(
      id: 10,
      name: r'score',
      type: IsarType.long,
    ),
    r'subject': PropertySchema(
      id: 11,
      name: r'subject',
      type: IsarType.string,
    ),
    r'timeTaken': PropertySchema(
      id: 12,
      name: r'timeTaken',
      type: IsarType.long,
    ),
    r'totalQuestions': PropertySchema(
      id: 13,
      name: r'totalQuestions',
      type: IsarType.long,
    ),
    r'unansweredCount': PropertySchema(
      id: 14,
      name: r'unansweredCount',
      type: IsarType.long,
    ),
    r'userId': PropertySchema(
      id: 15,
      name: r'userId',
      type: IsarType.string,
    ),
    r'wrongCount': PropertySchema(
      id: 16,
      name: r'wrongCount',
      type: IsarType.long,
    )
  },
  estimateSize: _examResultEstimateSize,
  serialize: _examResultSerialize,
  deserialize: _examResultDeserialize,
  deserializeProp: _examResultDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {r'QuestionAnswer': QuestionAnswerSchema},
  getId: _examResultGetId,
  getLinks: _examResultGetLinks,
  attach: _examResultAttach,
  version: '3.1.0+1',
);

int _examResultEstimateSize(
  ExamResult object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.answers.length * 3;
  {
    final offsets = allOffsets[QuestionAnswer]!;
    for (var i = 0; i < object.answers.length; i++) {
      final value = object.answers[i];
      bytesCount +=
          QuestionAnswerSchema.estimateSize(value, offsets, allOffsets);
    }
  }
  {
    final value = object.chapter;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.examId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.examTitle;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.grade;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
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

void _examResultSerialize(
  ExamResult object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeObjectList<QuestionAnswer>(
    offsets[0],
    allOffsets,
    QuestionAnswerSchema.serialize,
    object.answers,
  );
  writer.writeBool(offsets[1], object.autoSubmitted);
  writer.writeString(offsets[2], object.chapter);
  writer.writeLong(offsets[3], object.correctCount);
  writer.writeDateTime(offsets[4], object.createdAt);
  writer.writeString(offsets[5], object.examId);
  writer.writeString(offsets[6], object.examTitle);
  writer.writeString(offsets[7], object.grade);
  writer.writeBool(offsets[8], object.passed);
  writer.writeDouble(offsets[9], object.percentage);
  writer.writeLong(offsets[10], object.score);
  writer.writeString(offsets[11], object.subject);
  writer.writeLong(offsets[12], object.timeTaken);
  writer.writeLong(offsets[13], object.totalQuestions);
  writer.writeLong(offsets[14], object.unansweredCount);
  writer.writeString(offsets[15], object.userId);
  writer.writeLong(offsets[16], object.wrongCount);
}

ExamResult _examResultDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = ExamResult();
  object.answers = reader.readObjectList<QuestionAnswer>(
        offsets[0],
        QuestionAnswerSchema.deserialize,
        allOffsets,
        QuestionAnswer(),
      ) ??
      [];
  object.autoSubmitted = reader.readBool(offsets[1]);
  object.chapter = reader.readStringOrNull(offsets[2]);
  object.correctCount = reader.readLong(offsets[3]);
  object.createdAt = reader.readDateTimeOrNull(offsets[4]);
  object.examId = reader.readStringOrNull(offsets[5]);
  object.examTitle = reader.readStringOrNull(offsets[6]);
  object.grade = reader.readStringOrNull(offsets[7]);
  object.id = id;
  object.passed = reader.readBool(offsets[8]);
  object.percentage = reader.readDouble(offsets[9]);
  object.score = reader.readLong(offsets[10]);
  object.subject = reader.readStringOrNull(offsets[11]);
  object.timeTaken = reader.readLong(offsets[12]);
  object.totalQuestions = reader.readLong(offsets[13]);
  object.unansweredCount = reader.readLong(offsets[14]);
  object.userId = reader.readStringOrNull(offsets[15]);
  object.wrongCount = reader.readLong(offsets[16]);
  return object;
}

P _examResultDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readObjectList<QuestionAnswer>(
            offset,
            QuestionAnswerSchema.deserialize,
            allOffsets,
            QuestionAnswer(),
          ) ??
          []) as P;
    case 1:
      return (reader.readBool(offset)) as P;
    case 2:
      return (reader.readStringOrNull(offset)) as P;
    case 3:
      return (reader.readLong(offset)) as P;
    case 4:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 5:
      return (reader.readStringOrNull(offset)) as P;
    case 6:
      return (reader.readStringOrNull(offset)) as P;
    case 7:
      return (reader.readStringOrNull(offset)) as P;
    case 8:
      return (reader.readBool(offset)) as P;
    case 9:
      return (reader.readDouble(offset)) as P;
    case 10:
      return (reader.readLong(offset)) as P;
    case 11:
      return (reader.readStringOrNull(offset)) as P;
    case 12:
      return (reader.readLong(offset)) as P;
    case 13:
      return (reader.readLong(offset)) as P;
    case 14:
      return (reader.readLong(offset)) as P;
    case 15:
      return (reader.readStringOrNull(offset)) as P;
    case 16:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _examResultGetId(ExamResult object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _examResultGetLinks(ExamResult object) {
  return [];
}

void _examResultAttach(IsarCollection<dynamic> col, Id id, ExamResult object) {
  object.id = id;
}

extension ExamResultQueryWhereSort
    on QueryBuilder<ExamResult, ExamResult, QWhere> {
  QueryBuilder<ExamResult, ExamResult, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension ExamResultQueryWhere
    on QueryBuilder<ExamResult, ExamResult, QWhereClause> {
  QueryBuilder<ExamResult, ExamResult, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<ExamResult, ExamResult, QAfterWhereClause> idNotEqualTo(Id id) {
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

  QueryBuilder<ExamResult, ExamResult, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<ExamResult, ExamResult, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<ExamResult, ExamResult, QAfterWhereClause> idBetween(
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

extension ExamResultQueryFilter
    on QueryBuilder<ExamResult, ExamResult, QFilterCondition> {
  QueryBuilder<ExamResult, ExamResult, QAfterFilterCondition>
      answersLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'answers',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<ExamResult, ExamResult, QAfterFilterCondition> answersIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'answers',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<ExamResult, ExamResult, QAfterFilterCondition>
      answersIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'answers',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<ExamResult, ExamResult, QAfterFilterCondition>
      answersLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'answers',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<ExamResult, ExamResult, QAfterFilterCondition>
      answersLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'answers',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<ExamResult, ExamResult, QAfterFilterCondition>
      answersLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'answers',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<ExamResult, ExamResult, QAfterFilterCondition>
      autoSubmittedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'autoSubmitted',
        value: value,
      ));
    });
  }

  QueryBuilder<ExamResult, ExamResult, QAfterFilterCondition> chapterIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'chapter',
      ));
    });
  }

  QueryBuilder<ExamResult, ExamResult, QAfterFilterCondition>
      chapterIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'chapter',
      ));
    });
  }

  QueryBuilder<ExamResult, ExamResult, QAfterFilterCondition> chapterEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'chapter',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExamResult, ExamResult, QAfterFilterCondition>
      chapterGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'chapter',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExamResult, ExamResult, QAfterFilterCondition> chapterLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'chapter',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExamResult, ExamResult, QAfterFilterCondition> chapterBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'chapter',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExamResult, ExamResult, QAfterFilterCondition> chapterStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'chapter',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExamResult, ExamResult, QAfterFilterCondition> chapterEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'chapter',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExamResult, ExamResult, QAfterFilterCondition> chapterContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'chapter',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExamResult, ExamResult, QAfterFilterCondition> chapterMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'chapter',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExamResult, ExamResult, QAfterFilterCondition> chapterIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'chapter',
        value: '',
      ));
    });
  }

  QueryBuilder<ExamResult, ExamResult, QAfterFilterCondition>
      chapterIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'chapter',
        value: '',
      ));
    });
  }

  QueryBuilder<ExamResult, ExamResult, QAfterFilterCondition>
      correctCountEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'correctCount',
        value: value,
      ));
    });
  }

  QueryBuilder<ExamResult, ExamResult, QAfterFilterCondition>
      correctCountGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'correctCount',
        value: value,
      ));
    });
  }

  QueryBuilder<ExamResult, ExamResult, QAfterFilterCondition>
      correctCountLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'correctCount',
        value: value,
      ));
    });
  }

  QueryBuilder<ExamResult, ExamResult, QAfterFilterCondition>
      correctCountBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'correctCount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ExamResult, ExamResult, QAfterFilterCondition>
      createdAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'createdAt',
      ));
    });
  }

  QueryBuilder<ExamResult, ExamResult, QAfterFilterCondition>
      createdAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'createdAt',
      ));
    });
  }

  QueryBuilder<ExamResult, ExamResult, QAfterFilterCondition> createdAtEqualTo(
      DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<ExamResult, ExamResult, QAfterFilterCondition>
      createdAtGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<ExamResult, ExamResult, QAfterFilterCondition> createdAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<ExamResult, ExamResult, QAfterFilterCondition> createdAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'createdAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ExamResult, ExamResult, QAfterFilterCondition> examIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'examId',
      ));
    });
  }

  QueryBuilder<ExamResult, ExamResult, QAfterFilterCondition>
      examIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'examId',
      ));
    });
  }

  QueryBuilder<ExamResult, ExamResult, QAfterFilterCondition> examIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'examId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExamResult, ExamResult, QAfterFilterCondition> examIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'examId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExamResult, ExamResult, QAfterFilterCondition> examIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'examId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExamResult, ExamResult, QAfterFilterCondition> examIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'examId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExamResult, ExamResult, QAfterFilterCondition> examIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'examId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExamResult, ExamResult, QAfterFilterCondition> examIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'examId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExamResult, ExamResult, QAfterFilterCondition> examIdContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'examId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExamResult, ExamResult, QAfterFilterCondition> examIdMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'examId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExamResult, ExamResult, QAfterFilterCondition> examIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'examId',
        value: '',
      ));
    });
  }

  QueryBuilder<ExamResult, ExamResult, QAfterFilterCondition>
      examIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'examId',
        value: '',
      ));
    });
  }

  QueryBuilder<ExamResult, ExamResult, QAfterFilterCondition>
      examTitleIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'examTitle',
      ));
    });
  }

  QueryBuilder<ExamResult, ExamResult, QAfterFilterCondition>
      examTitleIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'examTitle',
      ));
    });
  }

  QueryBuilder<ExamResult, ExamResult, QAfterFilterCondition> examTitleEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'examTitle',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExamResult, ExamResult, QAfterFilterCondition>
      examTitleGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'examTitle',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExamResult, ExamResult, QAfterFilterCondition> examTitleLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'examTitle',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExamResult, ExamResult, QAfterFilterCondition> examTitleBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'examTitle',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExamResult, ExamResult, QAfterFilterCondition>
      examTitleStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'examTitle',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExamResult, ExamResult, QAfterFilterCondition> examTitleEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'examTitle',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExamResult, ExamResult, QAfterFilterCondition> examTitleContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'examTitle',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExamResult, ExamResult, QAfterFilterCondition> examTitleMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'examTitle',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExamResult, ExamResult, QAfterFilterCondition>
      examTitleIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'examTitle',
        value: '',
      ));
    });
  }

  QueryBuilder<ExamResult, ExamResult, QAfterFilterCondition>
      examTitleIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'examTitle',
        value: '',
      ));
    });
  }

  QueryBuilder<ExamResult, ExamResult, QAfterFilterCondition> gradeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'grade',
      ));
    });
  }

  QueryBuilder<ExamResult, ExamResult, QAfterFilterCondition> gradeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'grade',
      ));
    });
  }

  QueryBuilder<ExamResult, ExamResult, QAfterFilterCondition> gradeEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'grade',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExamResult, ExamResult, QAfterFilterCondition> gradeGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'grade',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExamResult, ExamResult, QAfterFilterCondition> gradeLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'grade',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExamResult, ExamResult, QAfterFilterCondition> gradeBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'grade',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExamResult, ExamResult, QAfterFilterCondition> gradeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'grade',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExamResult, ExamResult, QAfterFilterCondition> gradeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'grade',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExamResult, ExamResult, QAfterFilterCondition> gradeContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'grade',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExamResult, ExamResult, QAfterFilterCondition> gradeMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'grade',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExamResult, ExamResult, QAfterFilterCondition> gradeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'grade',
        value: '',
      ));
    });
  }

  QueryBuilder<ExamResult, ExamResult, QAfterFilterCondition>
      gradeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'grade',
        value: '',
      ));
    });
  }

  QueryBuilder<ExamResult, ExamResult, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<ExamResult, ExamResult, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<ExamResult, ExamResult, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<ExamResult, ExamResult, QAfterFilterCondition> idBetween(
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

  QueryBuilder<ExamResult, ExamResult, QAfterFilterCondition> passedEqualTo(
      bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'passed',
        value: value,
      ));
    });
  }

  QueryBuilder<ExamResult, ExamResult, QAfterFilterCondition> percentageEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'percentage',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ExamResult, ExamResult, QAfterFilterCondition>
      percentageGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'percentage',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ExamResult, ExamResult, QAfterFilterCondition>
      percentageLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'percentage',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ExamResult, ExamResult, QAfterFilterCondition> percentageBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'percentage',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ExamResult, ExamResult, QAfterFilterCondition> scoreEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'score',
        value: value,
      ));
    });
  }

  QueryBuilder<ExamResult, ExamResult, QAfterFilterCondition> scoreGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'score',
        value: value,
      ));
    });
  }

  QueryBuilder<ExamResult, ExamResult, QAfterFilterCondition> scoreLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'score',
        value: value,
      ));
    });
  }

  QueryBuilder<ExamResult, ExamResult, QAfterFilterCondition> scoreBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'score',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ExamResult, ExamResult, QAfterFilterCondition> subjectIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'subject',
      ));
    });
  }

  QueryBuilder<ExamResult, ExamResult, QAfterFilterCondition>
      subjectIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'subject',
      ));
    });
  }

  QueryBuilder<ExamResult, ExamResult, QAfterFilterCondition> subjectEqualTo(
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

  QueryBuilder<ExamResult, ExamResult, QAfterFilterCondition>
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

  QueryBuilder<ExamResult, ExamResult, QAfterFilterCondition> subjectLessThan(
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

  QueryBuilder<ExamResult, ExamResult, QAfterFilterCondition> subjectBetween(
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

  QueryBuilder<ExamResult, ExamResult, QAfterFilterCondition> subjectStartsWith(
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

  QueryBuilder<ExamResult, ExamResult, QAfterFilterCondition> subjectEndsWith(
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

  QueryBuilder<ExamResult, ExamResult, QAfterFilterCondition> subjectContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'subject',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExamResult, ExamResult, QAfterFilterCondition> subjectMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'subject',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExamResult, ExamResult, QAfterFilterCondition> subjectIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'subject',
        value: '',
      ));
    });
  }

  QueryBuilder<ExamResult, ExamResult, QAfterFilterCondition>
      subjectIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'subject',
        value: '',
      ));
    });
  }

  QueryBuilder<ExamResult, ExamResult, QAfterFilterCondition> timeTakenEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'timeTaken',
        value: value,
      ));
    });
  }

  QueryBuilder<ExamResult, ExamResult, QAfterFilterCondition>
      timeTakenGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'timeTaken',
        value: value,
      ));
    });
  }

  QueryBuilder<ExamResult, ExamResult, QAfterFilterCondition> timeTakenLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'timeTaken',
        value: value,
      ));
    });
  }

  QueryBuilder<ExamResult, ExamResult, QAfterFilterCondition> timeTakenBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'timeTaken',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ExamResult, ExamResult, QAfterFilterCondition>
      totalQuestionsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'totalQuestions',
        value: value,
      ));
    });
  }

  QueryBuilder<ExamResult, ExamResult, QAfterFilterCondition>
      totalQuestionsGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'totalQuestions',
        value: value,
      ));
    });
  }

  QueryBuilder<ExamResult, ExamResult, QAfterFilterCondition>
      totalQuestionsLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'totalQuestions',
        value: value,
      ));
    });
  }

  QueryBuilder<ExamResult, ExamResult, QAfterFilterCondition>
      totalQuestionsBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'totalQuestions',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ExamResult, ExamResult, QAfterFilterCondition>
      unansweredCountEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'unansweredCount',
        value: value,
      ));
    });
  }

  QueryBuilder<ExamResult, ExamResult, QAfterFilterCondition>
      unansweredCountGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'unansweredCount',
        value: value,
      ));
    });
  }

  QueryBuilder<ExamResult, ExamResult, QAfterFilterCondition>
      unansweredCountLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'unansweredCount',
        value: value,
      ));
    });
  }

  QueryBuilder<ExamResult, ExamResult, QAfterFilterCondition>
      unansweredCountBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'unansweredCount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ExamResult, ExamResult, QAfterFilterCondition> userIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'userId',
      ));
    });
  }

  QueryBuilder<ExamResult, ExamResult, QAfterFilterCondition>
      userIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'userId',
      ));
    });
  }

  QueryBuilder<ExamResult, ExamResult, QAfterFilterCondition> userIdEqualTo(
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

  QueryBuilder<ExamResult, ExamResult, QAfterFilterCondition> userIdGreaterThan(
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

  QueryBuilder<ExamResult, ExamResult, QAfterFilterCondition> userIdLessThan(
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

  QueryBuilder<ExamResult, ExamResult, QAfterFilterCondition> userIdBetween(
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

  QueryBuilder<ExamResult, ExamResult, QAfterFilterCondition> userIdStartsWith(
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

  QueryBuilder<ExamResult, ExamResult, QAfterFilterCondition> userIdEndsWith(
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

  QueryBuilder<ExamResult, ExamResult, QAfterFilterCondition> userIdContains(
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

  QueryBuilder<ExamResult, ExamResult, QAfterFilterCondition> userIdMatches(
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

  QueryBuilder<ExamResult, ExamResult, QAfterFilterCondition> userIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'userId',
        value: '',
      ));
    });
  }

  QueryBuilder<ExamResult, ExamResult, QAfterFilterCondition>
      userIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'userId',
        value: '',
      ));
    });
  }

  QueryBuilder<ExamResult, ExamResult, QAfterFilterCondition> wrongCountEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'wrongCount',
        value: value,
      ));
    });
  }

  QueryBuilder<ExamResult, ExamResult, QAfterFilterCondition>
      wrongCountGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'wrongCount',
        value: value,
      ));
    });
  }

  QueryBuilder<ExamResult, ExamResult, QAfterFilterCondition>
      wrongCountLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'wrongCount',
        value: value,
      ));
    });
  }

  QueryBuilder<ExamResult, ExamResult, QAfterFilterCondition> wrongCountBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'wrongCount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension ExamResultQueryObject
    on QueryBuilder<ExamResult, ExamResult, QFilterCondition> {
  QueryBuilder<ExamResult, ExamResult, QAfterFilterCondition> answersElement(
      FilterQuery<QuestionAnswer> q) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'answers');
    });
  }
}

extension ExamResultQueryLinks
    on QueryBuilder<ExamResult, ExamResult, QFilterCondition> {}

extension ExamResultQuerySortBy
    on QueryBuilder<ExamResult, ExamResult, QSortBy> {
  QueryBuilder<ExamResult, ExamResult, QAfterSortBy> sortByAutoSubmitted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'autoSubmitted', Sort.asc);
    });
  }

  QueryBuilder<ExamResult, ExamResult, QAfterSortBy> sortByAutoSubmittedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'autoSubmitted', Sort.desc);
    });
  }

  QueryBuilder<ExamResult, ExamResult, QAfterSortBy> sortByChapter() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'chapter', Sort.asc);
    });
  }

  QueryBuilder<ExamResult, ExamResult, QAfterSortBy> sortByChapterDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'chapter', Sort.desc);
    });
  }

  QueryBuilder<ExamResult, ExamResult, QAfterSortBy> sortByCorrectCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'correctCount', Sort.asc);
    });
  }

  QueryBuilder<ExamResult, ExamResult, QAfterSortBy> sortByCorrectCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'correctCount', Sort.desc);
    });
  }

  QueryBuilder<ExamResult, ExamResult, QAfterSortBy> sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<ExamResult, ExamResult, QAfterSortBy> sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<ExamResult, ExamResult, QAfterSortBy> sortByExamId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'examId', Sort.asc);
    });
  }

  QueryBuilder<ExamResult, ExamResult, QAfterSortBy> sortByExamIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'examId', Sort.desc);
    });
  }

  QueryBuilder<ExamResult, ExamResult, QAfterSortBy> sortByExamTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'examTitle', Sort.asc);
    });
  }

  QueryBuilder<ExamResult, ExamResult, QAfterSortBy> sortByExamTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'examTitle', Sort.desc);
    });
  }

  QueryBuilder<ExamResult, ExamResult, QAfterSortBy> sortByGrade() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'grade', Sort.asc);
    });
  }

  QueryBuilder<ExamResult, ExamResult, QAfterSortBy> sortByGradeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'grade', Sort.desc);
    });
  }

  QueryBuilder<ExamResult, ExamResult, QAfterSortBy> sortByPassed() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'passed', Sort.asc);
    });
  }

  QueryBuilder<ExamResult, ExamResult, QAfterSortBy> sortByPassedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'passed', Sort.desc);
    });
  }

  QueryBuilder<ExamResult, ExamResult, QAfterSortBy> sortByPercentage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'percentage', Sort.asc);
    });
  }

  QueryBuilder<ExamResult, ExamResult, QAfterSortBy> sortByPercentageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'percentage', Sort.desc);
    });
  }

  QueryBuilder<ExamResult, ExamResult, QAfterSortBy> sortByScore() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'score', Sort.asc);
    });
  }

  QueryBuilder<ExamResult, ExamResult, QAfterSortBy> sortByScoreDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'score', Sort.desc);
    });
  }

  QueryBuilder<ExamResult, ExamResult, QAfterSortBy> sortBySubject() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subject', Sort.asc);
    });
  }

  QueryBuilder<ExamResult, ExamResult, QAfterSortBy> sortBySubjectDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subject', Sort.desc);
    });
  }

  QueryBuilder<ExamResult, ExamResult, QAfterSortBy> sortByTimeTaken() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timeTaken', Sort.asc);
    });
  }

  QueryBuilder<ExamResult, ExamResult, QAfterSortBy> sortByTimeTakenDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timeTaken', Sort.desc);
    });
  }

  QueryBuilder<ExamResult, ExamResult, QAfterSortBy> sortByTotalQuestions() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalQuestions', Sort.asc);
    });
  }

  QueryBuilder<ExamResult, ExamResult, QAfterSortBy>
      sortByTotalQuestionsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalQuestions', Sort.desc);
    });
  }

  QueryBuilder<ExamResult, ExamResult, QAfterSortBy> sortByUnansweredCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'unansweredCount', Sort.asc);
    });
  }

  QueryBuilder<ExamResult, ExamResult, QAfterSortBy>
      sortByUnansweredCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'unansweredCount', Sort.desc);
    });
  }

  QueryBuilder<ExamResult, ExamResult, QAfterSortBy> sortByUserId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userId', Sort.asc);
    });
  }

  QueryBuilder<ExamResult, ExamResult, QAfterSortBy> sortByUserIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userId', Sort.desc);
    });
  }

  QueryBuilder<ExamResult, ExamResult, QAfterSortBy> sortByWrongCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'wrongCount', Sort.asc);
    });
  }

  QueryBuilder<ExamResult, ExamResult, QAfterSortBy> sortByWrongCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'wrongCount', Sort.desc);
    });
  }
}

extension ExamResultQuerySortThenBy
    on QueryBuilder<ExamResult, ExamResult, QSortThenBy> {
  QueryBuilder<ExamResult, ExamResult, QAfterSortBy> thenByAutoSubmitted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'autoSubmitted', Sort.asc);
    });
  }

  QueryBuilder<ExamResult, ExamResult, QAfterSortBy> thenByAutoSubmittedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'autoSubmitted', Sort.desc);
    });
  }

  QueryBuilder<ExamResult, ExamResult, QAfterSortBy> thenByChapter() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'chapter', Sort.asc);
    });
  }

  QueryBuilder<ExamResult, ExamResult, QAfterSortBy> thenByChapterDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'chapter', Sort.desc);
    });
  }

  QueryBuilder<ExamResult, ExamResult, QAfterSortBy> thenByCorrectCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'correctCount', Sort.asc);
    });
  }

  QueryBuilder<ExamResult, ExamResult, QAfterSortBy> thenByCorrectCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'correctCount', Sort.desc);
    });
  }

  QueryBuilder<ExamResult, ExamResult, QAfterSortBy> thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<ExamResult, ExamResult, QAfterSortBy> thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<ExamResult, ExamResult, QAfterSortBy> thenByExamId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'examId', Sort.asc);
    });
  }

  QueryBuilder<ExamResult, ExamResult, QAfterSortBy> thenByExamIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'examId', Sort.desc);
    });
  }

  QueryBuilder<ExamResult, ExamResult, QAfterSortBy> thenByExamTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'examTitle', Sort.asc);
    });
  }

  QueryBuilder<ExamResult, ExamResult, QAfterSortBy> thenByExamTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'examTitle', Sort.desc);
    });
  }

  QueryBuilder<ExamResult, ExamResult, QAfterSortBy> thenByGrade() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'grade', Sort.asc);
    });
  }

  QueryBuilder<ExamResult, ExamResult, QAfterSortBy> thenByGradeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'grade', Sort.desc);
    });
  }

  QueryBuilder<ExamResult, ExamResult, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<ExamResult, ExamResult, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<ExamResult, ExamResult, QAfterSortBy> thenByPassed() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'passed', Sort.asc);
    });
  }

  QueryBuilder<ExamResult, ExamResult, QAfterSortBy> thenByPassedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'passed', Sort.desc);
    });
  }

  QueryBuilder<ExamResult, ExamResult, QAfterSortBy> thenByPercentage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'percentage', Sort.asc);
    });
  }

  QueryBuilder<ExamResult, ExamResult, QAfterSortBy> thenByPercentageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'percentage', Sort.desc);
    });
  }

  QueryBuilder<ExamResult, ExamResult, QAfterSortBy> thenByScore() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'score', Sort.asc);
    });
  }

  QueryBuilder<ExamResult, ExamResult, QAfterSortBy> thenByScoreDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'score', Sort.desc);
    });
  }

  QueryBuilder<ExamResult, ExamResult, QAfterSortBy> thenBySubject() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subject', Sort.asc);
    });
  }

  QueryBuilder<ExamResult, ExamResult, QAfterSortBy> thenBySubjectDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subject', Sort.desc);
    });
  }

  QueryBuilder<ExamResult, ExamResult, QAfterSortBy> thenByTimeTaken() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timeTaken', Sort.asc);
    });
  }

  QueryBuilder<ExamResult, ExamResult, QAfterSortBy> thenByTimeTakenDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timeTaken', Sort.desc);
    });
  }

  QueryBuilder<ExamResult, ExamResult, QAfterSortBy> thenByTotalQuestions() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalQuestions', Sort.asc);
    });
  }

  QueryBuilder<ExamResult, ExamResult, QAfterSortBy>
      thenByTotalQuestionsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalQuestions', Sort.desc);
    });
  }

  QueryBuilder<ExamResult, ExamResult, QAfterSortBy> thenByUnansweredCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'unansweredCount', Sort.asc);
    });
  }

  QueryBuilder<ExamResult, ExamResult, QAfterSortBy>
      thenByUnansweredCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'unansweredCount', Sort.desc);
    });
  }

  QueryBuilder<ExamResult, ExamResult, QAfterSortBy> thenByUserId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userId', Sort.asc);
    });
  }

  QueryBuilder<ExamResult, ExamResult, QAfterSortBy> thenByUserIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userId', Sort.desc);
    });
  }

  QueryBuilder<ExamResult, ExamResult, QAfterSortBy> thenByWrongCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'wrongCount', Sort.asc);
    });
  }

  QueryBuilder<ExamResult, ExamResult, QAfterSortBy> thenByWrongCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'wrongCount', Sort.desc);
    });
  }
}

extension ExamResultQueryWhereDistinct
    on QueryBuilder<ExamResult, ExamResult, QDistinct> {
  QueryBuilder<ExamResult, ExamResult, QDistinct> distinctByAutoSubmitted() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'autoSubmitted');
    });
  }

  QueryBuilder<ExamResult, ExamResult, QDistinct> distinctByChapter(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'chapter', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ExamResult, ExamResult, QDistinct> distinctByCorrectCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'correctCount');
    });
  }

  QueryBuilder<ExamResult, ExamResult, QDistinct> distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<ExamResult, ExamResult, QDistinct> distinctByExamId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'examId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ExamResult, ExamResult, QDistinct> distinctByExamTitle(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'examTitle', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ExamResult, ExamResult, QDistinct> distinctByGrade(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'grade', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ExamResult, ExamResult, QDistinct> distinctByPassed() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'passed');
    });
  }

  QueryBuilder<ExamResult, ExamResult, QDistinct> distinctByPercentage() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'percentage');
    });
  }

  QueryBuilder<ExamResult, ExamResult, QDistinct> distinctByScore() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'score');
    });
  }

  QueryBuilder<ExamResult, ExamResult, QDistinct> distinctBySubject(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'subject', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ExamResult, ExamResult, QDistinct> distinctByTimeTaken() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'timeTaken');
    });
  }

  QueryBuilder<ExamResult, ExamResult, QDistinct> distinctByTotalQuestions() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'totalQuestions');
    });
  }

  QueryBuilder<ExamResult, ExamResult, QDistinct> distinctByUnansweredCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'unansweredCount');
    });
  }

  QueryBuilder<ExamResult, ExamResult, QDistinct> distinctByUserId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'userId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ExamResult, ExamResult, QDistinct> distinctByWrongCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'wrongCount');
    });
  }
}

extension ExamResultQueryProperty
    on QueryBuilder<ExamResult, ExamResult, QQueryProperty> {
  QueryBuilder<ExamResult, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<ExamResult, List<QuestionAnswer>, QQueryOperations>
      answersProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'answers');
    });
  }

  QueryBuilder<ExamResult, bool, QQueryOperations> autoSubmittedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'autoSubmitted');
    });
  }

  QueryBuilder<ExamResult, String?, QQueryOperations> chapterProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'chapter');
    });
  }

  QueryBuilder<ExamResult, int, QQueryOperations> correctCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'correctCount');
    });
  }

  QueryBuilder<ExamResult, DateTime?, QQueryOperations> createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<ExamResult, String?, QQueryOperations> examIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'examId');
    });
  }

  QueryBuilder<ExamResult, String?, QQueryOperations> examTitleProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'examTitle');
    });
  }

  QueryBuilder<ExamResult, String?, QQueryOperations> gradeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'grade');
    });
  }

  QueryBuilder<ExamResult, bool, QQueryOperations> passedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'passed');
    });
  }

  QueryBuilder<ExamResult, double, QQueryOperations> percentageProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'percentage');
    });
  }

  QueryBuilder<ExamResult, int, QQueryOperations> scoreProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'score');
    });
  }

  QueryBuilder<ExamResult, String?, QQueryOperations> subjectProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'subject');
    });
  }

  QueryBuilder<ExamResult, int, QQueryOperations> timeTakenProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'timeTaken');
    });
  }

  QueryBuilder<ExamResult, int, QQueryOperations> totalQuestionsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'totalQuestions');
    });
  }

  QueryBuilder<ExamResult, int, QQueryOperations> unansweredCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'unansweredCount');
    });
  }

  QueryBuilder<ExamResult, String?, QQueryOperations> userIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'userId');
    });
  }

  QueryBuilder<ExamResult, int, QQueryOperations> wrongCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'wrongCount');
    });
  }
}
