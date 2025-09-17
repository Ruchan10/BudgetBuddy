class Config {
  static bool _updateAvaliable = false;
  static bool _isUpdateDialogOpen = false;
  static String _appVersion = '1.0.9';
  static bool _hasInternet = false;
  static String _apkUrl = '';
  static String _newVersion = '';
  static List<String> _description = [];
  static String _cachedLatestVersion = '';
  static String _cachedReleaseNotes = '';
  static Map<String, dynamic> _versionData = {};

  static void setCachedVersionData(Map<String, dynamic> versionData) {
    _versionData = versionData;
  }

  static Map<String, dynamic> getCachedVersionData() {
    return _versionData;
  }

  static void setCachedLatestVersion(String version) {
    _cachedLatestVersion = version;
  }

  static String getCachedLatestVersion() {
    return _cachedLatestVersion;
  }

  static void setCachedReleaseNotes(String notes) {
    _cachedReleaseNotes = notes;
  }

  static String getCachedReleaseNotes() {
    return _cachedReleaseNotes;
  }

  static void setApkUrl(String apkUrl) {
    _apkUrl = apkUrl;
  }

  static String getApkUrl() {
    return _apkUrl;
  }

  static void setNewVersion(String newVersion) {
    _newVersion = newVersion;
  }

  static String getNewVersion() {
    return _newVersion;
  }

  static void setDescription(List<String> description) {
    _description = description;
  }

  static List<String> getDescription() {
    return _description;
  }

  static String getAppVersion() {
    return _appVersion;
  }

  static void setAppVersion(String version) {
    _appVersion = version;
  }

  static void setupdateAvailable(bool update) {
    _updateAvaliable = update;
  }

  static bool getUpdateAvailable() {
    return _updateAvaliable;
  }

  static void setIsUpdateDialogopen(bool update) {
    _isUpdateDialogOpen = update;
  }

  static bool getIsUpdateDialogopen() {
    return _isUpdateDialogOpen;
  }

  static void setHasInternet(bool hasInternet) {
    _hasInternet = hasInternet;
  }

  static bool getHasInternet() {
    return _hasInternet;
  }
}
