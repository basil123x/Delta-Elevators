import 'package:flutter/foundation.dart';

class AppProvider with ChangeNotifier {
  int _currentTab = 0;
  int _currentTab1 = 0;
  String _currentAdd = "";
  List _allImagesList = [];

  int get currentTab => _currentTab;
  int get currentTab1 => _currentTab1;
  String get currentAdd => _currentAdd;
  List get allImagesList => _allImagesList;

  void jumpToPagex(intcur) {
    _currentTab = intcur;
    notifyListeners();
  }

  void jumpToTabx(intcur) {
    _currentTab1 = intcur;
    notifyListeners();
  }

  void getCurrentAddress(curadd) {
    _currentAdd = curadd;
    notifyListeners();
  }

  void getMyImages(imagePath) {
    _allImagesList.add(imagePath);
    notifyListeners();
  }
}
