class Category {
  final String name;
  final String icon;
  final String color;

  Category({required this.name, required this.icon, required this.color});

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      name: json['name'],
      icon: json['icon'],
      color: json['color'],
    );
  }
  Map<String, dynamic> toJson() => {
    'name': name,
    'icon': icon,
    'color': color,
  };
}