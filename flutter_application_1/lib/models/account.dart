enum AccountStatus { available, reserved, sold, hidden }

class GameAccount {
  final String id;
  final String title;
  final String gameName;
  final double price;
  final AccountStatus status;
  final String description;
  final String sellerName;
  final List<String> imageUrls;
  final Map<String, String> specs;
  final DateTime createdAt;

  GameAccount({
    required this.id,
    required this.title,
    required this.gameName,
    required this.price,
    required this.status,
    required this.description,
    required this.sellerName,
    required this.imageUrls,
    required this.specs,
    required this.createdAt,
  });

  // Dummy data for testing
  static List<GameAccount> dummyAccounts = [
    GameAccount(
      id: '1',
      title: 'Vip Account Level 100 - Full Skins',
      gameName: 'League of Legends',
      price: 1500000,
      status: AccountStatus.available,
      description:
          'Account with all champions and 200+ skins. High rank last season.',
      sellerName: 'ProGamer99',
      imageUrls: [
        'https://picsum.photos/id/1/800/600',
        'https://picsum.photos/id/2/800/600',
      ],
      specs: {
        'Level': '100',
        'Rank': 'Diamond',
        'Skins': '200+',
        'Champions': 'All',
      },
      createdAt: DateTime.now(),
    ),
    GameAccount(
      id: '2',
      title: 'Genshin Impact AR 55 - 5 Star Heroes',
      gameName: 'Genshin Impact',
      price: 2500000,
      status: AccountStatus.available,
      description:
          'AR 55 account with C2 Raiden Shogun and other 5 star heroes.',
      sellerName: 'TravelerX',
      imageUrls: [
        'https://picsum.photos/id/10/800/600',
        'https://picsum.photos/id/11/800/600',
      ],
      specs: {'AR': '55', 'Heroes': '15 (5-star)', 'Region': 'Asia'},
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    GameAccount(
      id: '3',
      title: 'PUBG Mobile Account - Conqueror Frame',
      gameName: 'PUBG Mobile',
      price: 800000,
      status: AccountStatus.sold,
      description: 'Conqueror frame account with many weapon skins.',
      sellerName: 'SniperKing',
      imageUrls: ['https://picsum.photos/id/20/800/600'],
      specs: {'Level': '75', 'Tier': 'Conqueror', 'Skins': '50+'},
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
    GameAccount(
      id: '4',
      title: 'Valorant Account - Immortal Rank',
      gameName: 'Valorant',
      price: 1200000,
      status: AccountStatus.reserved, // Pending
      description: 'Immortal rank account with many premium skins.',
      sellerName: 'ViperMain',
      imageUrls: ['https://picsum.photos/id/30/800/600'],
      specs: {'Level': '120', 'Rank': 'Immortal', 'Skins': '30+'},
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
    ),
  ];
}
