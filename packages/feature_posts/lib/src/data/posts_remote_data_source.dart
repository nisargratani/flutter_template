import 'package:core/core.dart';
import 'package:feature_posts/src/domain/post.dart';

/// Where posts come from over the network. Implemented for REST and GraphQL;
/// the repository does not know which transport is used.
abstract interface class PostsRemoteDataSource {
  Future<Result<List<Post>>> fetchPosts();
  Future<Result<Post>> fetchPost(int id);
}
