class AppConstants {
  // App Info
  static const String appName = 'Airmass Xpress';
  static const String appVersion = '1.0.0';
  
  // API (for later backend integration)
  static const String baseUrl = 'http://localhost:8080/api';
  
  // Pagination
  static const int tasksPerPage = 20;
  static const int messagesPerPage = 30;

  // Country Codes for phone input
  static const List<Map<String, String>> countryCodes = [
    {'code': '+263', 'name': 'Zimbabwe', 'flag': '🇿🇼'},
    {'code': '+27', 'name': 'South Africa', 'flag': '🇿🇦'},
    {'code': '+260', 'name': 'Zambia', 'flag': '🇿🇲'},
    {'code': '+267', 'name': 'Botswana', 'flag': '🇧🇼'},
    {'code': '+258', 'name': 'Mozambique', 'flag': '🇲🇿'},
    {'code': '+265', 'name': 'Malawi', 'flag': '🇲🇼'},
  ];

  // Zimbabwean Courses/Programs for qualifications
  static const List<String> zimbabweanCourses = [
    // Technical/Vocational
    'Plumbing & Drain Laying',
    'Electrical Power Engineering',
    'Motor Vehicle Mechanics',
    'Carpentry & Joinery',
    'Welding & Fabrication',
    'Brick & Block Laying',
    'Refrigeration & Air Conditioning',
    'Painting & Decoration',
    'Hairdressing & Beauty Therapy',
    'Hotel & Catering Management',
    'Diesel Plant Fitting',
    'Drafting & Design Technology',
    'Machining & Fitting',
    'Chemical Technology',
    'Information Technology',
    // Professional/Degree
    'Civil Engineering',
    'Mechanical Engineering',
    'Electrical Engineering',
    'Architecture',
    'Accountancy',
    'Law',
    'Computer Science',
    'Quantity Surveying',
    'Business Studies',
    'Social Work',
    'Surveying & Geomatics',
    'Agricultural Engineering',
    'Pharmacy',
    'Education',
    'Nursing',
    'Economics',
    'Other',
  ];

  // Zimbabwean Institutions
  static const List<String> zimbabweanInstitutions = [
    'University of Zimbabwe',
    'National University of Science and Technology (NUST)',
    'Harare Polytechnic',
    'Bulawayo Polytechnic',
    'Kwekwe Polytechnic',
    'Mutare Polytechnic',
    'Chinhoyi University of Technology',
    'Midlands State University',
    'Africa University',
    'Great Zimbabwe University',
    'Lupane State University',
    'Zimbabwe Open University',
    'Speciss College',
    'Young Africa Zimbabwe',
    "St. Peter's Kubatana",
    'Msasa Industrial Training College',
    'National Railways Training School',
    'Other',
  ];
  


  // Categories are now fetched dynamically from the backend
  // Use CategoryBloc or ApiService.getCategories() instead.
  
  // Task Status
  static const String statusOpen = 'open';
  static const String statusAssigned = 'assigned';
  static const String statusInProgress = 'in_progress';
  static const String statusCompleted = 'completed';
  static const String statusCancelled = 'cancelled';
  
  // Offer Status
  static const String offerPending = 'pending';
  static const String offerAccepted = 'accepted';
  static const String offerRejected = 'rejected';
  
  // Date Formats
  static const String dateFormat = 'dd MMM yyyy';
  static const String dateTimeFormat = 'dd MMM yyyy, HH:mm';
  static const String timeFormat = 'HH:mm';
  
  // Validation
  static const int minPasswordLength = 8;
  static const int maxTaskTitleLength = 100;
  static const int maxTaskDescriptionLength = 2000;
  static const double minBudget = 10.0;
  static const double maxBudget = 100000.0;
  
  // Map
  static const double defaultLatitude = -33.8688;
  static const double defaultLongitude = 151.2093; // Sydney
  static const double defaultZoom = 12.0;
  
  // Images
  static const int maxTaskPhotos = 10;
  static const int maxPhotoSizeMB = 5;
}
