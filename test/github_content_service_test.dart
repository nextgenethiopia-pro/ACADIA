import 'package:flutter_test/flutter_test.dart';
import 'package:acadia/src/core/content/github_content_service.dart';

void main() {
  final service = GithubContentService.instance;

  group('subjectIndexPath', () {
    test('grade 9/10 high-school has no stream segment', () {
      expect(
        service.subjectIndexPath(
          academicPath: 'high-school',
          grade: '10',
          stream: 'natural',
          subject: 'Biology',
        ),
        'high-school/grade_10/biology.json',
      );
    });

    test('grade 11/12 high-school includes stream segment', () {
      expect(
        service.subjectIndexPath(
          academicPath: 'high-school',
          grade: '12',
          stream: 'Social Science',
          subject: 'Geography',
        ),
        'high-school/grade_12/social/geography.json',
      );
    });

    test('subject names are slugified (lowercase, underscores)', () {
      expect(
        service.subjectIndexPath(
          academicPath: 'high-school',
          grade: '9',
          stream: null,
          subject: 'Applied Mathematics',
        ),
        'high-school/grade_9/applied_mathematics.json',
      );
    });

    test('university semester 1 uses stream', () {
      expect(
        service.subjectIndexPath(
          academicPath: 'university',
          grade: '0',
          stream: 'natural',
          subject: 'Mathematics',
          semester: '1',
        ),
        'university/freshman/sem1/natural/mathematics.json',
      );
    });

    test('university semester 2 uses track', () {
      expect(
        service.subjectIndexPath(
          academicPath: 'university',
          grade: '0',
          stream: 'natural',
          subject: 'Physics',
          semester: '2',
          track: 'pre-engineering',
        ),
        'university/freshman/sem2/pre_engineering/physics.json',
      );
    });
  });
}
