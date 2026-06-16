class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
    this.plan = UserPlan.free,
    this.tokenUsed = 0,
  });

  final String id;
  final String name;
  final String email;
  final String? avatarUrl;
  final UserPlan plan;
  final int tokenUsed;

  int get tokenTotal => switch (plan) {
    UserPlan.free     => 60,
    UserPlan.pro      => 1000,
    UserPlan.platinum => 3000,
  };

  int get tokenLeft => tokenTotal - tokenUsed;
  double get tokenPercent => tokenUsed / tokenTotal;
  double get tokenRemainingPercent => tokenLeft / tokenTotal;

  AppUser copyWith({
    String? name, String? email, String? avatarUrl,
    UserPlan? plan, int? tokenUsed,
  }) => AppUser(
    id: id,
    name: name ?? this.name, email: email ?? this.email,
    avatarUrl: avatarUrl ?? this.avatarUrl, plan: plan ?? this.plan,
    tokenUsed: tokenUsed ?? this.tokenUsed,
  );

  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
    id: j['id'] as String, name: j['name'] as String, email: j['email'] as String,
    avatarUrl: j['avatar_url'] as String?,
    plan: UserPlan.values.firstWhere(
      (e) => e.name == (j['plan'] ?? 'free'), orElse: () => UserPlan.free),
    tokenUsed: j['token_used'] as int? ?? 0,
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'email': email,
    'avatar_url': avatarUrl, 'plan': plan.name,
    'token_used': tokenUsed,
  };
}

enum UserPlan { free, pro, platinum }
