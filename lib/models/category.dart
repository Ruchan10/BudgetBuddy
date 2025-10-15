class Category {
  final String name;
  final Map<String, dynamic> icon;
  final String color;

  Category({required this.name, required this.icon, required this.color});

  factory Category.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> iconData;
    if (json['icon'] is String) {
      iconData = {
        'data': int.parse(json['icon']),
        'pack': 'material',
      };
    } else {
      iconData = json['icon'];
    }

    return Category(
      name: json['name'],
      icon: iconData,
      color: json['color'],
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'icon': icon,
    'color': color,
  };
}