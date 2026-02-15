import 'package:flutter/material.dart';

class LocalizationService {
  static final LocalizationService _instance = LocalizationService._internal();

  factory LocalizationService() {
    return _instance;
  }

  LocalizationService._internal();

  String _currentLanguage = 'English';
  
  String get currentLanguage => _currentLanguage;

  void setLanguage(String lang) {
    if (['English', 'Hindi', 'Telugu', 'Tamil'].contains(lang)) {
      _currentLanguage = lang;
    }
  }

  // Dictionary
  final Map<String, Map<String, String>> _localizedValues = {
    'English': {
      'app_title': 'RainSafe Navigator',
      'welcome': 'Welcome',
      'login': 'LOGIN',
      'signup': 'CREATE ACCOUNT',
      'guest': 'Continue as Guest',
      'email': 'Email Address',
      'password': 'Password',
      'name': 'Full Name',
      'search_hint': 'Where to?',
      'search_btn': 'SEARCH DESTINATION',
      'current_cond': 'CURRENT CONDITIONS',
      'recent_searches': 'RECENT SEARCHES',
      'settings': 'Settings',
      'profile': 'PROFILE',
      'security': 'SECURITY',
      'app_settings': 'APP SETTINGS',
      'change_pass': 'Change Password',
      'language': 'Language',
      'logout': 'Log Out',
      'save': 'Save Changes',
      'delete_account': 'Delete Account',
      'delete_confirm': 'Are you sure you want to delete your account? This action cannot be undone.',
      'cancel': 'Cancel',
      'delete': 'Delete',
      'enter_pass': 'Enter Password',
    },
    'Hindi': {
      'app_title': 'रेनसेफ नेविगेटर',
      'welcome': 'स्वागत है',
      'login': 'लॉग इन करें',
      'signup': 'खाता बनाएं',
      'guest': 'गेस्ट के रूप में जारी रखें',
      'email': 'ईमेल पता',
      'password': 'पासवर्ड',
      'name': 'पूरा नाम',
      'search_hint': 'कहाँ जाना है?',
      'search_btn': 'गंतव्य खोजें',
      'current_cond': 'वर्तमान स्थिति',
      'recent_searches': 'हाल की खोजें',
      'settings': 'सेटिंग्स',
      'profile': 'प्रोफाइल',
      'security': 'सुरक्षा',
      'app_settings': 'ऐप सेटिंग्स',
      'change_pass': 'पासवर्ड बदलें',
      'language': 'भाषा',
      'logout': 'लॉग आउट',
      'save': 'परिवर्तन सहेजें',
      'delete_account': 'खाता हटाएं',
      'delete_confirm': 'क्या आप वाकई अपना खाता हटाना चाहते हैं? यह कार्रवाई पूर्ववत नहीं की जा सकती।',
      'cancel': 'रद्द करें',
      'delete': 'हटाएं',
      'enter_pass': 'पासवर्ड दर्ज करें',
    },
    'Telugu': {
      'app_title': 'రెయిన్‌సేఫ్ నావిగేటర్',
      'welcome': 'స్వాగతం',
      'login': 'లాగిన్',
      'signup': 'ఖాతా సృష్టించండి',
      'guest': 'గెస్ట్‌గా కొనసాగండి',
      'email': 'ఇమెయిల్ చిరునామా',
      'password': 'పాస్‌వర్డ్',
      'name': 'పూర్తి పేరు',
      'search_hint': 'ఎక్కడికి వెళ్ళాలి?',
      'search_btn': 'గమ్యాన్ని వెతకండి',
      'current_cond': 'ప్రస్తుత పరిస్థితులు',
      'recent_searches': 'ఇటీవలి శోధనలు',
      'settings': 'సెట్టింగ్‌లు',
      'profile': 'ప్రొఫైల్',
      'security': 'భద్రత',
      'app_settings': 'యాప్ సెట్టింగ్‌లు',
      'change_pass': 'పాస్‌వర్డ్ మార్చండి',
      'language': 'భాష',
      'logout': 'లాగ్ అవుట్',
      'save': 'మార్పులను సేవ్ చేయండి',
      'delete_account': 'ఖాతాను తొలగించండి',
      'delete_confirm': 'మీరు ఖచ్చితంగా మీ ఖాతాను తొలగించాలనుకుంటున్నారా? ఈ చర్య రద్దు చేయబడదు.',
      'cancel': 'రద్దు చేయండి',
      'delete': 'తొలగించండి',
      'enter_pass': 'పాస్‌వర్డ్ నమోదు చేయండి',
    },
    'Tamil': {
      'app_title': 'ரெயின்சேஃப் நேவிகேட்டர்',
      'welcome': 'வரவேற்கிறோம்',
      'login': 'உள்நுழைய',
      'signup': 'கணக்கை உருவாக்கவும்',
      'guest': 'விருந்தினராக தொடரவும்',
      'email': 'மின்னஞ்சல் முகவரி',
      'password': 'கடவுச்சொல்',
      'name': 'முழு பெயர்',
      'search_hint': 'எங்கே செல்ல வேண்டும்?',
      'search_btn': 'இலக்கைத் தேடுங்கள்',
      'current_cond': 'தற்போதைய நிலை',
      'recent_searches': 'சமீப்பத்திய தேடல்கள்',
      'settings': 'அமைப்புகள்',
      'profile': 'சுயவிவரம்',
      'security': 'பாதுகாப்பு',
      'app_settings': 'செயலி அமைப்புகள்',
      'change_pass': 'கடவுச்சொல்லை மாற்றவும்',
      'language': 'மொழி',
      'logout': 'வெளியேறு',
      'save': 'மாற்றங்களைச் சேமிக்கவும்',
      'delete_account': 'கணக்கை நீக்கவும்',
      'delete_confirm': 'உங்கள் கணக்கை நிச்சயமாக நீக்க விரும்புகிறீர்களா? இந்த செயலை மாற்ற முடியாது.',
      'cancel': 'ரத்து',
      'delete': 'நீக்கவும்',
      'enter_pass': 'கடவுச்சொல்லை உள்ளிடவும்',
    },
  };

  String get(String key) {
    return _localizedValues[_currentLanguage]?[key] ?? key;
  }
}
