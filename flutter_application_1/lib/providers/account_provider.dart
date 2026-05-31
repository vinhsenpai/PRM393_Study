import 'package:flutter/material.dart';
import '../models/account.dart';

class AccountProvider with ChangeNotifier {
  final List<GameAccount> _accounts = GameAccount.dummyAccounts;
  String _searchQuery = '';
  String? _selectedGame;
  double? _minPrice;
  double? _maxPrice;
  AccountStatus _statusFilter = AccountStatus.available;

  List<GameAccount> get accounts => _accounts;

  List<GameAccount> get filteredAccounts {
    return _accounts.where((account) {
      final matchesSearch =
          account.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          account.gameName.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesGame =
          _selectedGame == null || account.gameName == _selectedGame;
      final matchesMinPrice = _minPrice == null || account.price >= _minPrice!;
      final matchesMaxPrice = _maxPrice == null || account.price <= _maxPrice!;
      final matchesStatus = account.status == _statusFilter;

      return matchesSearch &&
          matchesGame &&
          matchesMinPrice &&
          matchesMaxPrice &&
          matchesStatus;
    }).toList();
  }

  void updateSearch(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void updateFilters({
    String? game,
    double? minPrice,
    double? maxPrice,
    AccountStatus? status,
  }) {
    if (game != null) _selectedGame = game == 'All' ? null : game;
    if (minPrice != null) _minPrice = minPrice;
    if (maxPrice != null) _maxPrice = maxPrice;
    if (status != null) _statusFilter = status;
    notifyListeners();
  }

  List<String> get availableGames {
    return ['All', ..._accounts.map((a) => a.gameName).toSet()];
  }
}
