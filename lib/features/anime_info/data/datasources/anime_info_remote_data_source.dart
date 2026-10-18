import 'package:anime_flow/core/network/api/flow_api.dart';
import 'package:anime_flow/shared/models/bangumi/producers_item.dart';
import 'package:anime_flow/shared/models/bangumi/related_subjects_item.dart';
import 'package:anime_flow/shared/models/bangumi/subject_comments_item.dart';
import 'package:anime_flow/shared/models/bangumi/subjects_info_item.dart';
import 'package:dio/dio.dart';

class AnimeInfoRemoteDataSource {
  Future<SubjectsInfoItem> getSubject(int subjectId,
          {CancelToken? cancelToken}) =>
      FlowApi.getSubjectByIdService(subjectId, cancelToken: cancelToken);

  Future<List<String>> getStills(int subjectId, {CancelToken? cancelToken}) =>
      FlowApi.getSubjectStillsService(subjectId, cancelToken: cancelToken);

  Future<SubjectCommentItem> getComments(
    int subjectId, {
    required int limit,
    required int offset,
    CancelToken? cancelToken,
  }) =>
      FlowApi.getSubjectCommentsByIdService(
        subjectId: subjectId,
        limit: limit,
        offset: offset,
        cancelToken: cancelToken,
      );

  Future<SubjectRelationItem> getRelated(
    int subjectId, {
    required int limit,
    required int offset,
    int? type = 2,
    CancelToken? cancelToken,
  }) =>
      FlowApi.relatedSubjectsService(subjectId,
          limit: limit, offset: offset, type: type, cancelToken: cancelToken);

  Future<ProducersItem> getProducers(
    int subjectId, {
    required int limit,
    required int offset,
    CancelToken? cancelToken,
  }) =>
      FlowApi.getProducersService(subjectId,
          limit: limit, offset: offset, cancelToken: cancelToken);
}
