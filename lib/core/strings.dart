class L {
  final String lang;
  L(this.lang);

  String t(String key) {
    return _localizedValues[lang]?[key] ??
        _localizedValues['en']![key] ??
        key;
  }
}

final Map<String, Map<String, String>> _localizedValues = {
  'en': {
    'home': 'Home',
    'my_profile': 'My Profile',
    'ticket': 'My Tickets',
    'nav_camera': 'Navigation (Camera)',
    'navigation': 'Navigation',
    'see_all': 'See all',
    'matches': 'Matches',
    'camera_not_available': 'Camera not available',
    'close': 'Close',

    // Camera screen translations
    'save_car_location': 'Save Car Location',
    'where_to_go': 'Where do you want to go?',
    'saved_car_success': 'Car location saved: ',
    'choose_destination': 'Choose your destination',

    // Destinations
    'north_gate': 'North Gate',
    'south_gate': 'South Gate',
    'east_gate': 'East Gate',
    'west_gate': 'West Gate',
    'first_class': 'First Class',
    'second_class': 'Second Class',
    'food_court': 'Food Court',
    'vip_parking': 'VIP Parking',
    'restrooms': 'Restrooms',
    'saved_locations': 'Saved Location',

    // Match details
    'seats': 'Available Seats',
    'stadium_info': 'Stadium Information',
    'ticket_purchased': 'Ticket Purchased!',
    'buy_ticket': 'Buy Ticket',

    // Tickets
    'my_tickets_title': 'My Tickets',
    'seat_label': 'Seat',

    // Additional screens
    'notifications': 'Notifications',
    'create_account': 'Create Account',
    'my_ticket': 'My Ticket',
    'matches_title': 'Matches',
    'checkout': 'Checkout',
    'broadcast': 'Broadcast Message',
    'transfer_ticket': 'Transfer Ticket',
    'navigation_steps': 'Navigation Steps',
    'logout': 'Logout',
    'logout_confirm': 'Are you sure you want to logout?',
    'cancel': 'Cancel',
    'select_section': 'Select a Section',
    'payment_method': 'Payment Method',
    'language': 'Language',
    'match_details': 'Match Details',
    'stadium_map': 'Stadium Map',
    'ai_recommendations': 'AI Recommendations',

    // GPS Navigation
    'nearest_to_me': 'Nearest to Me',
    'nearest_food': 'Nearest Food',
    'nearest_wc': 'Nearest WC',
    'finding_location': 'Finding your location...',
    'location_error': 'Could not get your location',
    'far_from_stadium': 'You are far from the stadium',
    'crowd_level': 'Crowd Level',
    'low': 'Low',
    'medium': 'Medium',
    'high': 'High',
  },

  'ar': {
    'home': 'الرئيسية',
    'my_profile': 'ملفي الشخصي',
    'ticket': 'تذاكري',
    'nav_camera': 'التنقل (الكاميرا)',
    'navigation': 'التنقل',
    'see_all': 'عرض الكل',
    'matches': 'المباريات',
    'camera_not_available': 'الكاميرا غير متوفرة',
    'close': 'إغلاق',

    // Camera screen
    'save_car_location': 'حفظ موقع السيارة',
    'where_to_go': 'إلى أين تريد الذهاب؟',
    'saved_car_success': 'تم حفظ موقع سيارتك: ',
    'choose_destination': 'اختر وجهتك',

    // Destinations
    'north_gate': 'البوابة الشمالية',
    'south_gate': 'البوابة الجنوبية',
    'east_gate': 'البوابة الشرقية',
    'west_gate': 'البوابة الغربية',
    'first_class': 'الدرجة الأولى',
    'second_class': 'الدرجة الثانية',
    'food_court': 'منطقة الطعام',
    'vip_parking': 'مواقف كبار الشخصيات',
    'restrooms': 'دورات المياه',
    'saved_locations': 'موقع محفوظ',

    // Match details
    'seats': 'المقاعد المتاحة',
    'stadium_info': 'معلومات الاستاد',
    'ticket_purchased': 'تم شراء التذكرة!',
    'buy_ticket': 'شراء التذكرة',

    // Tickets
    'my_tickets_title': 'تذاكري',
    'seat_label': 'المقعد',

    // Additional screens
    'notifications': 'الإشعارات',
    'create_account': 'إنشاء حساب',
    'my_ticket': 'تذكرتي',
    'matches_title': 'المباريات',
    'checkout': 'إتمام الدفع',
    'broadcast': 'بث رسالة للمشجعين',
    'transfer_ticket': 'تحويل التذكرة',
    'navigation_steps': 'خطوات التنقل',
    'logout': 'تسجيل الخروج',
    'logout_confirm': 'هل أنت متأكد من تسجيل الخروج؟',
    'cancel': 'إلغاء',
    'select_section': 'اختر القسم',
    'payment_method': 'طريقة الدفع',
    'language': 'اللغة',
    'match_details': 'تفاصيل المباراة',
    'stadium_map': 'خريطة الملعب',
    'ai_recommendations': 'توصيات الذكاء الاصطناعي',

    // GPS Navigation
    'nearest_to_me': 'الأقرب إلي',
    'nearest_food': 'أقرب مطعم',
    'nearest_wc': 'أقرب دورة مياه',
    'finding_location': 'جاري تحديد موقعك...',
    'location_error': 'تعذر تحديد موقعك',
    'far_from_stadium': 'أنت بعيد عن الملعب',
    'crowd_level': 'مستوى الازدحام',
    'low': 'منخفض',
    'medium': 'متوسط',
    'high': 'مرتفع',
  },

  'fr': {
    'home': 'Accueil',
    'my_profile': 'Mon Profil',
    'ticket': 'Mes Billets',
    'nav_camera': 'Navigation (Caméra)',
    'navigation': 'Navigation',
    'see_all': 'Voir tout',
    'matches': 'Matchs',
    'camera_not_available': 'Caméra non disponible',
    'close': 'Fermer',

    // Camera screen
    'save_car_location': 'Enregistrer emplacement voiture',
    'where_to_go': 'Où voulez-vous aller ?',
    'saved_car_success': 'Emplacement enregistré : ',
    'choose_destination': 'Choisissez votre destination',

    // Destinations
    'north_gate': 'Porte Nord',
    'south_gate': 'Porte Sud',
    'east_gate': 'Porte Est',
    'west_gate': 'Porte Ouest',
    'first_class': '1ère Classe',
    'second_class': '2ème Classe',
    'food_court': 'Zone de restauration',
    'vip_parking': 'Parking VIP',
    'restrooms': 'Toilettes',
    'saved_locations': 'Emplacement Sauvegardé',

    // Match details
    'seats': 'Sièges disponibles',
    'stadium_info': 'Informations du stade',
    'ticket_purchased': 'Billet acheté !',
    'buy_ticket': 'Acheter le billet',

    // Tickets
    'my_tickets_title': 'Mes Billets',
    'seat_label': 'Siège',

    // Additional screens
    'notifications': 'Notifications',
    'create_account': 'Créer un compte',
    'my_ticket': 'Mon billet',
    'matches_title': 'Matchs',
    'checkout': 'Paiement',
    'broadcast': 'Message diffusé',
    'transfer_ticket': 'Transférer le billet',
    'navigation_steps': 'Étapes de navigation',
    'logout': 'Déconnexion',
    'logout_confirm': 'Voulez-vous vraiment vous déconnecter ?',
    'cancel': 'Annuler',
    'select_section': 'Choisir une section',
    'payment_method': 'Mode de paiement',
    'language': 'Langue',
    'match_details': 'Détails du match',
    'stadium_map': 'Carte du stade',
    'ai_recommendations': 'Recommandations IA',

    // GPS Navigation
    'nearest_to_me': 'Le plus proche de moi',
    'nearest_food': 'Restaurant le plus proche',
    'nearest_wc': 'Toilettes les plus proches',
    'finding_location': 'Recherche de votre position...',
    'location_error': 'Impossible de localiser votre position',
    'far_from_stadium': 'Vous êtes loin du stade',
    'crowd_level': 'Niveau de foule',
    'low': 'Faible',
    'medium': 'Moyen',
    'high': 'Élevé',
  },
};
