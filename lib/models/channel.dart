class Channel {
  final String name;
  final String url;
  final String logo;
  final String group;
  final String country;
  final String userAgent;
  final String referrer;

  const Channel({
    required this.name,
    required this.url,
    this.logo = '',
    this.group = '',
    this.country = '',
    this.userAgent = '',
    this.referrer = '',
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'url': url,
      'logo': logo,
      'group': group,
      'country': country,
      'userAgent': userAgent,
      'referrer': referrer,
    };
  }

  factory Channel.fromJson(Map<String, dynamic> json) {
    return Channel(
      name: _asString(json['name']),
      url: _asString(json['url']),
      logo: _asString(json['logo']),
      group: _asString(json['group']),
      country: _asString(json['country']),
      userAgent: _asString(json['userAgent']),
      referrer: _asString(json['referrer']),
    );
  }

  Channel copyWith({
    String? name,
    String? url,
    String? logo,
    String? group,
    String? country,
    String? userAgent,
    String? referrer,
  }) {
    return Channel(
      name: name ?? this.name,
      url: url ?? this.url,
      logo: logo ?? this.logo,
      group: group ?? this.group,
      country: country ?? this.country,
      userAgent: userAgent ?? this.userAgent,
      referrer: referrer ?? this.referrer,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is Channel && other.url == url;
  }

  @override
  int get hashCode => url.hashCode;
}

String _asString(dynamic value) {
  if (value == null) return '';
  return value.toString();
}
