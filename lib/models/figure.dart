/// 角色/达人模型
class Figure {
  final String id;
  final String nickname;
  final String avatar;
  final List<String> travelImages;
  final int followCount;
  final String category;
  final String? travelGuide;

  Figure({
    required this.id,
    required this.nickname,
    required this.avatar,
    required this.travelImages,
    required this.followCount,
    required this.category,
    this.travelGuide,
  });

  factory Figure.fromJson(Map<String, dynamic> json) => Figure(
        id: json['id'] as String,
        nickname: json['nickname'] as String,
        avatar: json['avatar'] as String,
        travelImages: (json['travelImages'] as List).cast<String>(),
        followCount: json['followCount'] as int,
        category: json['category'] as String,
        travelGuide: json['travelGuide'] as String?,
      );
}
