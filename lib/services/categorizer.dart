import 'package:budgget_buddy/models/category.dart';
import 'package:budgget_buddy/models/transaction.dart';

/// On-device auto-categorization. Runs offline and never sends data anywhere.
///
/// 1. Reuses the category of the latest transaction with the same title, so it
///    learns from every category you pick or correct.
/// 2. Money coming in is income.
/// 3. Otherwise keyword rules cover common words and merchants.
class Categorizer {
  Categorizer._();

  static String? suggest(
    String title,
    double amount,
    Iterable<Transaction> history,
  ) {
    final key = normalize(title);
    if (key.isEmpty) return null;

    Transaction? learned;
    for (final t in history) {
      if (t.deleted || t.category == null || normalize(t.title) != key) {
        continue;
      }
      if (learned == null || t.updatedAt.isAfter(learned.updatedAt)) {
        learned = t;
      }
    }
    if (learned != null) return learned.category;

    if (amount > 0) return Categories.income;

    final padded = ' $key ';
    for (final MapEntry(key: category, value: words) in _keywords.entries) {
      for (final word in words) {
        // "grocer*" matches any word starting with "grocer".
        final hit = word.endsWith('*')
            ? padded.contains(' ${word.substring(0, word.length - 1)}')
            : padded.contains(' $word ');
        if (hit) return category;
      }
    }
    return null;
  }

  /// Lowercase words only, so "Lunch #2" and "lunch" count as the same title.
  static String normalize(String title) => title
      .toLowerCase()
      .replaceAll(RegExp(r'[^\p{L}\p{M}\s]', unicode: true), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  // Checked in order, so more specific categories come first
  // ("uber eats" is food before "uber" is transport).
  // dart format off
  static const _keywords = <String, List<String>>{
    'Food & Drinks': [
      'food', 'lunch', 'dinner', 'breakfast', 'brunch', 'snack*', 'meal*',
      'restaurant*', 'cafe', 'café', 'coffee', 'tea', 'chiya', 'chai', 'juice',
      'pizza*', 'burger*', 'momo*', 'khaja', 'biryani', 'sandwich*', 'noodle*',
      'chowmein', 'dal bhat', 'thali', 'samosa*', 'sekuwa', 'pani puri',
      'bakery', 'cake*', 'dessert*', 'ice cream', 'drink*', 'beer*', 'wine',
      'bar', 'pub', 'kfc', 'mcdonald*', 'starbucks', 'domino*', 'swiggy',
      'zomato', 'foodmandu', 'ubereats', 'uber eats', 'doordash', 'grubhub',
      'deliveroo', 'takeaway', 'canteen', 'eat', 'eating', 'dine', 'dining',
    ],
    'Groceries': [
      'grocer*', 'supermarket*', 'mart', 'vegetable*', 'veggie*', 'tarkari',
      'sabji', 'sabzi', 'fruit*', 'milk', 'egg', 'eggs', 'bread', 'rice',
      'meat', 'fish', 'flour', 'atta', 'sugar', 'dairy', 'butter', 'cheese',
      'curd', 'dahi', 'dal', 'lentil*', 'kirana', 'bhatbhateni', 'bigmart',
      'big mart', 'walmart', 'costco', 'aldi', 'lidl', 'tesco', 'kroger',
      'safeway', 'dmart', 'bigbasket', 'blinkit', 'instacart', 'zepto',
    ],
    'Transport': [
      'uber', 'lyft', 'taxi*', 'cab', 'bus', 'metro', 'subway', 'train',
      'tram', 'ferry', 'fuel', 'petrol', 'diesel', 'gas station', 'parking',
      'toll*', 'pathao', 'indrive*', 'ola', 'rapido', 'bolt', 'grab', 'ride',
      'fare', 'transport*', 'rickshaw', 'tempo', 'microbus', 'car', 'bike',
      'scooter', 'mechanic*', 'tyre*', 'commute',
    ],
    'Health': [
      'doctor*', 'hospital*', 'clinic*', 'medic*', 'pharma*', 'drugstore',
      'dentist*', 'dental', 'gym', 'fitness', 'yoga', 'checkup', 'check up',
      'lab test', 'health*', 'therapy', 'physio*', 'vitamin*', 'vaccin*',
    ],
    'Personal Care': [
      'salon', 'haircut', 'hair cut', 'barber*', 'spa', 'massage', 'cosmetic*',
      'makeup', 'skincare', 'shampoo', 'soap', 'toothpaste', 'perfume',
      'grooming', 'manicure', 'pedicure', 'parlour', 'parlor',
    ],
    'Entertainment': [
      'movie*', 'cinema', 'film', 'netflix', 'spotify', 'youtube', 'disney*',
      'hulu', 'prime video', 'hbo', 'game', 'games', 'gaming', 'steam',
      'playstation', 'xbox', 'nintendo', 'concert*', 'party', 'club', 'music',
      'theatre', 'theater', 'bowling', 'karaoke',
    ],
    'Bills & Utilities': [
      'bill', 'bills', 'electricity', 'electric*', 'nea', 'water bill',
      'khanepani', 'wifi', 'internet', 'broadband', 'recharge', 'topup',
      'top up', 'mobile recharge', 'phone bill', 'data pack', 'ntc', 'ncell',
      'worldlink', 'vianet', 'jio', 'airtel', 'lpg', 'cylinder', 'utility',
      'utilities', 'insurance', 'tax', 'taxes', 'emi', 'loan', 'subscription*',
      'icloud', 'dishhome', 'dish home', 'postpaid', 'prepaid',
    ],
    'Rent & Housing': [
      'rent', 'bhada', 'kotha', 'landlord', 'apartment', 'mortgage', 'hostel',
      'repair*', 'plumber', 'electrician', 'maintenance', 'housekeeping',
    ],
    'Education': [
      'school', 'college', 'university', 'tuition', 'course*', 'class',
      'classes', 'book', 'books', 'stationery', 'exam*', 'udemy', 'coursera',
      'training', 'workshop', 'library', 'notebook*', 'admission', 'semester',
    ],
    'Travel': [
      'flight*', 'airline*', 'airport', 'hotel*', 'airbnb', 'trip', 'travel*',
      'vacation', 'holiday*', 'tour', 'tours', 'visa', 'passport', 'booking',
      'resort*', 'trek*', 'luggage',
    ],
    'Shopping': [
      'shop', 'shopping', 'store', 'amazon', 'daraz', 'flipkart', 'ebay',
      'aliexpress', 'temu', 'shein', 'clothes', 'clothing', 'shirt*',
      'tshirt*', 'shoe*', 'jeans', 'dress*', 'jacket*', 'electronics',
      'laptop*', 'headphone*', 'earbuds', 'charger', 'furniture', 'ikea',
      'mall', 'gadget*',
    ],
    'Gifts & Donations': [
      'gift*', 'donation*', 'donate*', 'charity', 'present', 'wedding',
      'birthday', 'temple', 'church', 'mosque', 'offering', 'tip', 'tips',
    ],
  };
  // dart format on
}
