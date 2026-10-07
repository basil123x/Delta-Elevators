import 'package:flutter/foundation.dart';

class AppProvider with ChangeNotifier {
  int _currentTab = 0;
  int _currentTab1 = 0;
  String _currentAdd = "";
  String _signId = "";
  bool _isAppManager = false;
  int _quoteCartRevision = 0;
  final List _allImagesList = [];

  int get currentTab => _currentTab;
  int get currentTab1 => _currentTab1;
  String get currentAdd => _currentAdd;
  String get signId => _signId;
  bool get isAppManager => _isAppManager;
  int get quoteCartRevision => _quoteCartRevision;
  List get allImagesList => _allImagesList;

  void bumpQuoteCart() {
    _quoteCartRevision++;
    notifyListeners();
  }

  void setAppManager(bool value) {
    if (_isAppManager == value) return;
    _isAppManager = value;
    notifyListeners();
  }

  void jumpToPagex(intcur) {
    if (_currentTab == intcur) return;
    _currentTab = intcur;
    notifyListeners();
  }

  void jumpToTabx(intcur) {
    if (_currentTab1 == intcur) return;
    _currentTab1 = intcur;
    notifyListeners();
  }

  void getCurrentAddress(curadd) {
    _currentAdd = curadd?.toString() ?? "";
    notifyListeners();
  }
  void getSignId(signId) {
    _signId = signId;
    notifyListeners();
  }

  void getMyImages(imagePath) {
    _allImagesList.add(imagePath);
    notifyListeners();
  }

  void removeMyImageAt(int index) {
    if (index < 0 || index >= _allImagesList.length) return;
    _allImagesList.removeAt(index);
    notifyListeners();
  }

  void clearMyImages() {
    if (_allImagesList.isEmpty) return;
    _allImagesList.clear();
    notifyListeners();
  }
}
