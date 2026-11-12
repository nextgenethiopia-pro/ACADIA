// ACADIA Academic Structure
// Parsed from path/structure.txt

class AcademicStructure {
  // Grade 10 Subjects with Units
  static const Map<String, List<String>> grade10Subjects = {
    'Biology': [
      'Unit 1: SUB-FIELDS OF BIOLOGY',
      'Unit 2: PLANTS',
      'Unit 3: BIOCHEMICAL MOLECULES',
      'Unit 4: CELL REPRODUCTION',
      'Unit 5: HUMAN BIOLOGY',
      'Unit 6: ECOLOGICAL INTERACTION',
    ],
    'Chemistry': [
      'Unit 1: CHEMICAL REACTIONS AND STOICHIOMETRY',
      'Unit 2: SOLUTIONS',
      'Unit 3: IMPORTANT INORGANIC COMPOUNDS',
      'Unit 4: ENERGY CHANGES AND ELECTROCHEMISTRY',
      'Unit 5: METALS AND NONMETALS',
      'Unit 6: HYDROCARBONS AND THEIR NATURAL SOURCES',
    ],
    'Citizenship': [
      'Unit 1: DEMOCRACY AND DEMOCRATIZATION',
      'Unit 2: CITIZENS IN THE DIGITAL TECHNOLOGY AGE',
      'Unit 3: UNDERSTANDING GOOD GOVERNANCE',
      'Unit 4: PEACE AND INDIGENOUS CONFLICT RESOLUTION MECHANISMS',
      'Unit 5: FEDERALISM IN ETHIOPIA',
      'Unit 6: HUMAN RIGHTS',
      'Unit 7: PATRIOTISM',
      'Unit 8: GLOBALIZATION AND GLOBAL ISSUES',
    ],
    'Economics': [
      'Unit 1: THEORY OF CONSUMER BEHAVIOUR',
      'Unit 2: THEORIES OF DEMAND AND SUPPLY',
      'Unit 3: THEORIES OF PRODUCTION AND COST',
      'Unit 4: MARKET STRUCTURE',
      'Unit 5: BANKING AND FINANCE',
      'Unit 6: ECONOMIC GROWTH',
      'Unit 7: THE ETHIOPIAN ECONOMY',
      'Unit 8: BUSINESS STARTUPS AND INNOVATION',
    ],
    'English': [
      'Unit 1: POPULATION GROWTH',
      'Unit 2: TRAVEL BEHAVIORS',
      'Unit 3: PUNCTUALITY',
      'Unit 4: TOURIST ATTRACTIONS',
      'Unit 5: HONEY PROCESSING',
      'Unit 6: MIGRATION',
      'Unit 7: BRANDING ETHIOPIA AND NATIONAL IDENTITY',
      'Unit 8: THE HEALING POWER OF PLANTS',
      'Unit 9: MULTILINGUALISM',
      'Unit 10: DIGITAL VS SATELLITE TELEVISION',
    ],
    'Geography': [
      'Unit 1: LANDFORMS OF AFRICA',
      'Unit 2: CLIMATE OF AFRICA',
      'Unit 3: NATURAL RESOURCE BASE OF AFRICA',
      'Unit 4: POPULATION OF AFRICA',
      'Unit 5: MAJOR ECONOMIC AND CULTURAL ACTIVITIES OF AFRICA',
      'Unit 6: HUMAN NATURAL ENVIRONMENT INTERACTIONS',
      'Unit 7: GEOGRAPHIC ISSUES AND PUBLIC CONCERNS IN AFRICA',
      'Unit 8: GEOSPATIAL INFORMATION AND DATA PROCESSING',
    ],
    'History': [
      'Unit 1: DEVELOPMENT OF CAPITALISM AND NATIONALISM 1815-1914',
      'Unit 2: AFRICA AND THE COLONIAL EXPERIENCE (1880s-1960s)',
      'Unit 3: SOCIAL, ECONOMIC AND POLITICAL DEVELOPMENTS IN ETHIOPIA MID 19th C TO 1941',
      'Unit 4: SOCIETY AND POLITICS IN THE AGE OF WORLD WARS 1914-1945',
      'Unit 5: GLOBAL AND REGIONAL DEVELOPMENTS SINCE 1945',
      'Unit 6: ETHIOPIA INTERNAL DEVELOPMENTS AND EXTERNAL INFLUENCES FROM 1941 TO 1991',
      'Unit 7: AFRICA SINCE 1960',
      'Unit 8: POST-1991 DEVELOPMENTS IN ETHIOPIA',
      'Unit 9: INDIGENOUS KNOWLEDGE AND HERITAGES OF ETHIOPIA',
    ],
    'IT': [
      'Unit 1: ORGANIZATION OF FILES',
      'Unit 2: COMPUTER NETWORK',
      'Unit 3: APPLICATION SOFTWARE',
      'Unit 4: IMAGE PROCESSING AND MULTIMEDIA',
      'Unit 5: INFORMATION AND COMPUTER SECURITY',
      'Unit 6: FUNDAMENTALS OF PROGRAMMING',
    ],
    'Mathematics': [
      'Unit 1: RELATIONS AND FUNCTIONS',
      'Unit 2: POLYNOMIAL FUNCTIONS',
      'Unit 3: EXPONENTIAL AND LOGARITHMIC FUNCTIONS',
      'Unit 4: TRIGONOMETRIC FUNCTIONS',
      'Unit 5: CIRCLES',
      'Unit 6: SOLID FIGURES',
      'Unit 7: COORDINATE GEOMETRY',
    ],
    'Physics': [
      'Unit 1: VECTOR QUANTITIES',
      'Unit 2: UNIFORMLY ACCELERATED MOTION',
      'Unit 3: ELASTICITY AND STATIC EQUILIBRIUM OF RIGID BODY',
      'Unit 4: STATIC AND CURRENT ELECTRICITY',
      'Unit 5: MAGNETISM',
      'Unit 6: ELECTROMAGNETIC WAVES AND GEOMETRICAL OPTICS',
    ],
  };

  // Grade 11 Natural Science Subjects with Units
  static const Map<String, List<String>> grade11NaturalSubjects = {
    'Agriculture': [
      'Unit 1: INTRODUCTION TO CROP PRODUCTION',
      'Unit 2: FIELD CROPS PRODUCTION AND MANAGEMENT',
      'Unit 3: INDUSTRIAL CROPS PRODUCTION AND MANAGEMENT',
      'Unit 4: INTRODUCTION TO FARM ANIMALS',
      'Unit 5: ANIMAL FEEDS AND FEEDING PRACTICES',
      'Unit 6: ANIMAL GENETICS AND BREEDING PRACTICES',
      'Unit 7: FARM ANIMALS HOUSING',
      'Unit 8: BASIC ANIMAL HEALTH AND DISEASE CONTROL',
      'Unit 9: DAIRY CATTLE PRODUCTION AND MANAGEMENT',
      'Unit 10: INTRODUCTION TO NATURAL RESOURCES',
      'Unit 11: MANAGEMENT OF NATURAL RESOURCES',
      'Unit 12: CONCEPTS OF BIODIVERSITY',
      'Unit 13: CLIMATE CHANGE ADAPTATION AND MITIGATION',
      'Unit 14: INTRODUCTION TO HUMAN NUTRITION',
      'Unit 15: DIVERSIFIED FOOD PRODUCTION AND CONSUMPTION',
    ],
    'Aptitude': [
      'Part 1: Mathematical Part',
      'Part 2: English Part',
    ],
    'Biology': [
      'Unit 1: BIOLOGY AND TECHNOLOGY',
      'Unit 2: ANIMALS',
      'Unit 3: ENZYMES',
      'Unit 4: GENETICS',
      'Unit 5: THE HUMAN BODY SYSTEMS',
      'Unit 6: POPULATION AND NATURAL RESOURCES',
    ],
    'Chemistry': [
      'Unit 1: ATOMIC STRUCTURE AND PERIODIC PROPERTIES OF THE ELEMENTS',
      'Unit 2: CHEMICAL BONDING',
      'Unit 3: PHYSICAL STATES OF MATTER',
      'Unit 4: CHEMICAL KINETICS',
      'Unit 5: CHEMICAL EQUILIBRIUM',
      'Unit 6: SOME IMPORTANT OXYGEN-CONTAINING ORGANIC COMPOUNDS',
    ],
    'English': [
      'Unit 1: ENVIRONMENTAL HAZARDS',
      'Unit 2: CIVILIZATION',
      'Unit 3: CAUSES OF ROAD TRAFFIC ACCIDENTS',
      'Unit 4: PEOPLE AND NATURAL RESOURCES',
      'Unit 5: IRRIGATION',
      'Unit 6: GLOBAL WARMING',
      'Unit 7: PATRIOTISM',
      'Unit 8: EFFICIENCY OF HEALTH SERVICES',
      'Unit 9: INDIGENOUS CONFLICT RESOLUTION',
      'Unit 10: ARTIFICIAL INTELLIGENCE',
    ],
    'IT': [
      'Unit 1: INFORMATION SYSTEMS AND ITS APPLICATIONS',
      'Unit 2: EMERGING TECHNOLOGIES',
      'Unit 3: DATABASE MANAGEMENT',
      'Unit 4: WEB DEVELOPMENT',
      'Unit 5: HARDWARE TROUBLESHOOTING AND PREVENTIVE MAINTENANCE',
      'Unit 6: FUNDAMENTALS OF PROGRAMMING',
    ],
    'Mathematics': [
      'Unit 1: RELATIONS AND FUNCTIONS',
      'Unit 2: RATIONAL EXPRESSIONS AND RATIONAL FUNCTIONS',
      'Unit 3: MATRICES',
      'Unit 4: DETERMINANTS AND THEIR PROPERTIES',
      'Unit 5: VECTORS',
    ],
    'Physics': [
      'Unit 1: PHYSICS AND HUMAN SOCIETY',
      'Unit 2: VECTORS',
      'Unit 3: MOTION IN ONE AND TWO DIMENSIONS',
      'Unit 4: DYNAMICS',
      'Unit 5: HEAT CONDUCTION AND CALORIMETRY',
      'Unit 6: ELECTROSTATICS AND ELECTRIC CIRCUIT',
    ],
  };

  // Grade 11 Social Science Subjects with Units
  static const Map<String, List<String>> grade11SocialSubjects = {
    'Aptitude': [
      'Part 1: Mathematical Part',
      'Part 2: English Part',
    ],
    'Citizenship': [
      'Unit 1: ETHICAL VALUES',
      'Unit 2: THE CULTURE OF USING DIGITAL TECHNOLOGY',
      'Unit 3: CONSTITUTION AND CONSTITUTIONALISM',
      'Unit 4: UNDERSTANDING INDIGENOUS KNOWLEDGE',
      'Unit 5: MULTICULTURALISM IN ETHIOPIA',
      'Unit 6: NATIONAL UNITY THROUGH DIVERSITY',
      'Unit 7: PROBLEM SOLVING SKILLS',
      'Unit 8: ETHIOPIA\'S FOREIGN RELATIONS IN EAST AFRICA',
    ],
    'Economics': [
      'Unit 1: THE FUNDAMENTAL CONCEPTS OF MACROECONOMICS',
      'Unit 2: AGGREGATE DEMAND AND AGGREGATE SUPPLY ANALYSIS',
      'Unit 3: MARKET FAILURE AND CONSUMER PROTECTION',
      'Unit 4: MACROECONOMIC POLICY INSTRUMENTS',
      'Unit 5: TAX THEORY AND PRACTICE',
      'Unit 6: POVERTY AND INEQUALITY',
      'Unit 7: MACROECONOMIC REFORMS IN ETHIOPIA',
      'Unit 8: ECONOMY, ENVIRONMENT AND CLIMATE CHANGE',
    ],
    'English': [
      'Unit 1: SUSTAINABLE DEVELOPMENT',
      'Unit 2: TIME MANAGEMENT',
      'Unit 3: EVIDENCE ON TRAFFIC ACCIDENT',
      'Unit 4: NATURAL RESOURCE MANAGEMENT',
      'Unit 5: MECHANIZED AGRICULTURE',
      'Unit 6: GREEN ECONOMIES',
      'Unit 7: NATIONAL PRIDE',
      'Unit 8: TELEMEDICINE',
      'Unit 9: CONFLICT MANAGEMENT',
      'Unit 10: ROBOTICS',
    ],
    'Geography': [
      'Unit 1: MAJOR GEOLOGICAL PROCESSES ASSOCIATED WITH PLATE TECTONICS',
      'Unit 2: CLIMATE CHANGE',
      'Unit 3: ISSUES IN SUSTAINABLE DEVELOPMENT I MANAGEMENT OF CONFLICT OVER RESOURCES',
      'Unit 4: ISSUES IN SUSTAINABLE DEVELOPMENT II POPULATION POLICIES, PROGRAMS AND THE ENVIRONMENT',
      'Unit 5: ISSUES IN SUSTAINABLE DEVELOPMENT III CHALLENGES OF ECONOMIC DEVELOPMENT',
      'Unit 6: ISSUES IN SUSTAINABLE DEVELOPMENT IV SOLUTIONS TO ENVIRONMENTAL AND SUSTAINABILITY PROBLEMS',
      'Unit 7: CONTEMPORARY GLOBAL GEOGRAPHIC ISSUES AND PUBLIC CONCERNS',
      'Unit 8: GEOGRAPHICAL ENQUIRY AND MAP MAKING',
    ],
    'History': [
      'Unit 1: DEVELOPMENT OF CAPITALISM AND NATIONALISM FROM 1815 TO 1914',
      'Unit 2: AFRICA AND THE COLONIAL EXPERIENCE (1880s TO 1960s)',
      'Unit 3: SOCIAL, ECONOMIC AND POLITICAL DEVELOPMENTS IN ETHIOPIA, MID 19th C TO 1941',
      'Unit 4: SOCIETY AND POLITICS IN THE AGE OF WORLD WARS, 1914 TO 1945',
      'Unit 5: GLOBAL AND REGIONAL DEVELOPMENTS SINCE 1945',
      'Unit 6: ETHIOPIA INTERNAL DEVELOPMENTS AND EXTERNAL INFLUENCES FROM 1941 TO 1991',
      'Unit 7: AFRICA SINCE THE 1960s',
      'Unit 8: POST 1991 DEVELOPMENTS IN ETHIOPIA',
      'Unit 9: INDIGENOUS KNOWLEDGE SYSTEMS AND HERITAGES OF ETHIOPIA',
    ],
    'IT': [
      'Unit 1: INFORMATION SYSTEMS AND THEIR APPLICATIONS',
      'Unit 2: EMERGING TECHNOLOGIES',
      'Unit 3: DATABASE MANAGEMENT SYSTEM',
      'Unit 4: WEB AUTHORING',
      'Unit 5: MAINTENANCE AND TROUBLESHOOTING',
      'Unit 6: FUNDAMENTALS OF PROGRAMMING',
    ],
    'Mathematics': [
      'Unit 1: SEQUENCES AND SERIES',
      'Unit 2: INTRODUCTIONS TO CALCULUS',
      'Unit 3: STATISTICS',
      'Unit 4: INTRODUCTION TO LINEAR PROGRAMMING',
      'Unit 5: MATHEMATICAL APPLICATIONS IN BUSINESS',
    ],
  };

  // Grade 9 Subjects with Units
  static const Map<String, List<String>> grade9Subjects = {
    'Biology': [
      'Unit 1: INTRODUCTION TO BIOLOGY',
      'Unit 2: CHARACTERISTICS AND CLASSIFICATION OF ORGANISMS',
      'Unit 3: CELLS',
      'Unit 4: REPRODUCTION',
      'Unit 5: HUMAN HEALTH, NUTRITION, AND DISEASE',
      'Unit 6: ECOLOGY',
    ],
    'Chemistry': [
      'Unit 1: CHEMISTRY AND ITS IMPORTANCE',
      'Unit 2: MEASUREMENTS AND SCIENTIFIC METHODS',
      'Unit 3: STRUCTURE OF THE ATOM',
      'Unit 4: PERIODIC CLASSIFICATION OF ELEMENTS',
      'Unit 5: CHEMICAL BONDING',
    ],
    'Citizenship': [
      'Unit 1: ETHICAL VALUES',
      'Unit 2: THE CULTURE OF USING DIGITAL TECHNOLOGY',
      'Unit 3: CONSTITUTION AND CONSTITUTIONALISM',
      'Unit 4: UNDERSTANDING INDIGENOUS KNOWLEDGE',
      'Unit 5: MULTICULTURALISM IN ETHIOPIA',
      'Unit 6: NATIONAL UNITY THROUGH DIVERSITY',
      'Unit 7: PROBLEM SOLVING SKILLS',
      'Unit 8: ETHIOPIA\'S FOREIGN RELATIONS IN EAST AFRICA',
    ],
    'Economics': [
      'Unit 1: INTRODUCING ECONOMICS',
      'Unit 2: THE BASIC ECONOMIC PROBLEMS AND ECONOMIC SYSTEMS',
      'Unit 3: ECONOMIC RESOURCES AND MARKETS',
      'Unit 4: INTRODUCTION TO DEMAND AND SUPPLY',
      'Unit 5: INTRODUCTION TO PRODUCTION AND COST',
      'Unit 6: INTRODUCTION TO MONEY',
      'Unit 7: INTRODUCTION TO MACROECONOMICS',
      'Unit 8: BASIC ENTREPRENEURSHIP',
    ],
    'English': [
      'Unit 1: LIVING IN URBAN AREAS',
      'Unit 2: STUDY SKILLS',
      'Unit 3: TRAFFIC ACCIDENT',
      'Unit 4: NATIONAL PARKS',
      'Unit 5: HORTICULTURE',
      'Unit 6: POVERTY IN ETHIOPIA',
      'Unit 7: COMMUNITY SERVICES',
      'Unit 8: COMMUNICABLE DISEASES',
    ],
    'Geography': [
      'Unit 1: INTRODUCTION TO GEOGRAPHY',
      'Unit 2: THE EARTH',
      'Unit 3: MAP READING AND INTERPRETATION',
      'Unit 4: THE PHYSICAL ENVIRONMENT OF ETHIOPIA',
      'Unit 5: POPULATION OF ETHIOPIA',
      'Unit 6: ECONOMIC ACTIVITIES IN ETHIOPIA',
    ],
    'History': [
      'Unit 1: THE DISCIPLINE OF HISTORY AND HUMAN EVOLUTION',
      'Unit 2: ANCIENT WORLD CIVILIZATIONS UP TO c. 500 AD',
      'Unit 3: PEOPLES AND STATES IN ETHIOPIA AND THE HORN TO THE END OF 13th C',
      'Unit 4: THE MIDDLE AGES AND EARLY MODERN WORLD, C. 500 TO 1750s',
      'Unit 5: PEOPLES AND STATES OF AFRICA TO 1500',
      'Unit 6: AFRICA AND THE OUTSIDE WORLD 1500-1880s',
      'Unit 7: STATES, PRINCIPALITIES, POPULATION MOVEMENTS & INTERACTIONS IN ETHIOPIA 13th TO MID-16th C',
      'Unit 8: POLITICAL, SOCIAL AND ECONOMIC PROCESSES IN ETHIOPIA MID-16th TO MID-19th C',
      'Unit 9: THE AGE OF REVOLUTIONS 1750s TO 1815',
    ],
    'IT': [
      'Unit 1: ORGANIZATION OF FILES',
      'Unit 2: COMPUTER NETWORK',
      'Unit 3: APPLICATION SOFTWARE',
      'Unit 4: IMAGE PROCESSING AND MULTIMEDIA',
      'Unit 5: INFORMATION AND COMPUTER SECURITY',
      'Unit 6: FUNDAMENTALS OF PROGRAMMING',
    ],
    'Mathematics': [
      'Unit 1: FURTHER ON SETS',
      'Unit 2: THE NUMBER SYSTEM',
      'Unit 3: SOLVING EQUATIONS',
      'Unit 4: SOLVING INEQUALITIES',
      'Unit 5: INTRODUCTION TO TRIGONOMETRY',
      'Unit 6: REGULAR POLYGONS',
      'Unit 7: CONGRUENCY AND SIMILARITY',
      'Unit 8: VECTORS IN TWO DIMENSIONS',
      'Unit 9: STATISTICS AND PROBABILITY',
    ],
    'Physics': [
      'Unit 1: PHYSICS AND HUMAN SOCIETY',
      'Unit 2: PHYSICAL QUANTITIES',
      'Unit 3: MOTION IN A STRAIGHT LINE',
      'Unit 4: FORCE, WORK, ENERGY AND POWER',
      'Unit 5: SIMPLE MACHINES',
      'Unit 6: MECHANICAL OSCILLATION AND SOUND WAVE',
      'Unit 7: TEMPERATURE AND THERMOMETRY',
    ],
  };

  // Grade 12 Natural Science Subjects with Units
  static const Map<String, List<String>> grade12NaturalSubjects = {
    'Agriculture': [
      'Unit 1: VEGETABLE CROPS PRODUCTION AND MANAGEMENT',
      'Unit 2: FRUIT CROPS PRODUCTION AND MANAGEMENT',
      'Unit 3: ROOT AND TUBER CROPS PRODUCTION AND MANAGEMENT',
      'Unit 4: COFFEE, TEA AND SPICES PRODUCTION AND MANAGEMENT',
      'Unit 5: INTRODUCTION TO PLANT BIOTECHNOLOGY',
      'Unit 6: BEEF CATTLE PRODUCTION AND MANAGEMENT',
      'Unit 7: SHEEP AND GOAT PRODUCTION AND MANAGEMENT',
      'Unit 8: CAMEL PRODUCTION AND MANAGEMENT',
      'Unit 9: POULTRY PRODUCTION AND MANAGEMENT',
      'Unit 10: FISHERY PRODUCTION AND MANAGEMENT',
      'Unit 11: APICULTURE',
      'Unit 12: NURSERY AND PLANTATION TECHNOLOGY',
      'Unit 13: BASICS OF AGRO-FORESTRY SYSTEMS AND PRACTICES',
      'Unit 14: SOIL AND WATER CONSERVATION',
      'Unit 15: GENDER AND HUMAN NUTRITION',
      'Unit 16: SAFE FOOD PRODUCTION AND POSTHARVEST HANDLING',
      'Unit 17: APPLICATION OF INFORMATION AND COMMUNICATION TECHNOLOGIES (ICT) IN AGRICULTURE',
    ],
    'Aptitude': [
      'Part 1: Mathematical Aptitude',
      'Part 2: English Aptitude',
      'Part 3: Logical Reasoning',
      'Part 4: Critical Thinking',
    ],
    'Biology': [
      'Unit 1: APPLICATION OF BIOLOGY',
      'Unit 2: MICROORGANISMS',
      'Unit 3: ENERGY TRANSFORMATION',
      'Unit 4: EVOLUTION',
      'Unit 5: HUMAN BODY SYSTEM',
      'Unit 6: CLIMATE CHANGE',
    ],
    'Chemistry': [
      'Unit 1: ACID-BASE CONCEPTS AND IONIC EQUILIBRIA',
      'Unit 2: ELECTROCHEMISTRY',
      'Unit 3: INDUSTRIAL CHEMISTRY',
      'Unit 4: POLYMERS',
      'Unit 5: INTRODUCTION TO ENVIRONMENTAL CHEMISTRY',
    ],
    'English': [
      'Unit 1: SUSTAINABLE DEVELOPMENT',
      'Unit 2: TIME MANAGEMENT',
      'Unit 3: EVIDENCE ON TRAFFIC ACCIDENT',
      'Unit 4: NATURAL RESOURCE MANAGEMENT',
      'Unit 5: MECHANIZED AGRICULTURE',
      'Unit 6: GREEN ECONOMIES',
      'Unit 7: NATIONAL PRIDE',
      'Unit 8: TELEMEDICINE',
      'Unit 9: CONFLICT MANAGEMENT',
      'Unit 10: ROBOTICS',
    ],
    'IT': [
      'Unit 1: INFORMATION SYSTEMS AND THEIR APPLICATIONS',
      'Unit 2: EMERGING TECHNOLOGIES',
      'Unit 3: DATABASE MANAGEMENT SYSTEM',
      'Unit 4: WEB AUTHORING',
      'Unit 5: MAINTENANCE AND TROUBLESHOOTING',
      'Unit 6: FUNDAMENTALS OF PROGRAMMING',
    ],
    'Mathematics': [
      'Unit 1: SEQUENCES AND SERIES',
      'Unit 2: INTRODUCTIONS TO CALCULUS',
      'Unit 3: STATISTICS',
      'Unit 4: INTRODUCTION TO LINEAR PROGRAMMING',
      'Unit 5: MATHEMATICAL APPLICATIONS IN BUSINESS',
    ],
    'Physics': [
      'Unit 1: APPLICATION OF PHYSICS IN OTHER FIELDS',
      'Unit 2: TWO-DIMENSIONAL MOTION',
      'Unit 3: FLUID MECHANICS',
      'Unit 4: ELECTROMAGNETISM',
      'Unit 5: BASICS OF ELECTRONICS',
    ],
  };

  // Grade 12 Social Science Subjects with Units
  static const Map<String, List<String>> grade12SocialSubjects = {
    'Aptitude': [
      'Part 1: Mathematical Part',
      'Part 2: English Part',
    ],
    'Citizenship': [
      'Unit 1: ETHICAL VALUES',
      'Unit 2: THE CULTURE OF USING DIGITAL TECHNOLOGY',
      'Unit 3: CONSTITUTION AND CONSTITUTIONALISM',
      'Unit 4: UNDERSTANDING INDIGENOUS KNOWLEDGE',
      'Unit 5: MULTICULTURALISM IN ETHIOPIA',
      'Unit 6: NATIONAL UNITY THROUGH DIVERSITY',
      'Unit 7: PROBLEM SOLVING SKILLS',
      'Unit 8: ETHIOPIA\'S FOREIGN RELATIONS IN EAST AFRICA',
    ],
    'Economics': [
      'Unit 1: THE FUNDAMENTAL CONCEPTS OF MACROECONOMICS',
      'Unit 2: AGGREGATE DEMAND AND AGGREGATE SUPPLY ANALYSIS',
      'Unit 3: MARKET FAILURE AND CONSUMER PROTECTION',
      'Unit 4: MACROECONOMIC POLICY INSTRUMENTS',
      'Unit 5: TAX THEORY AND PRACTICE',
      'Unit 6: POVERTY AND INEQUALITY',
      'Unit 7: MACROECONOMIC REFORMS IN ETHIOPIA',
      'Unit 8: ECONOMY, ENVIRONMENT AND CLIMATE CHANGE',
    ],
    'English': [
      'Unit 1: SUSTAINABLE DEVELOPMENT',
      'Unit 2: TIME MANAGEMENT',
      'Unit 3: EVIDENCE ON TRAFFIC ACCIDENT',
      'Unit 4: NATURAL RESOURCE MANAGEMENT',
      'Unit 5: MECHANIZED AGRICULTURE',
      'Unit 6: GREEN ECONOMIES',
      'Unit 7: NATIONAL PRIDE',
      'Unit 8: TELEMEDICINE',
      'Unit 9: CONFLICT MANAGEMENT',
      'Unit 10: ROBOTICS',
    ],
    'Geography': [
      'Unit 1: MAJOR GEOLOGICAL PROCESSES ASSOCIATED WITH PLATE TECTONICS',
      'Unit 2: CLIMATE CHANGE',
      'Unit 3: ISSUES IN SUSTAINABLE DEVELOPMENT I MANAGEMENT OF CONFLICT OVER RESOURCES',
      'Unit 4: ISSUES IN SUSTAINABLE DEVELOPMENT II POPULATION POLICIES, PROGRAMS AND THE ENVIRONMENT',
      'Unit 5: ISSUES IN SUSTAINABLE DEVELOPMENT III CHALLENGES OF ECONOMIC DEVELOPMENT',
      'Unit 6: ISSUES IN SUSTAINABLE DEVELOPMENT IV SOLUTIONS TO ENVIRONMENTAL AND SUSTAINABILITY PROBLEMS',
      'Unit 7: CONTEMPORARY GLOBAL GEOGRAPHIC ISSUES AND PUBLIC CONCERNS',
      'Unit 8: GEOGRAPHICAL ENQUIRY AND MAP MAKING',
    ],
    'History': [
      'Unit 1: DEVELOPMENT OF CAPITALISM AND NATIONALISM FROM 1815 TO 1914',
      'Unit 2: AFRICA AND THE COLONIAL EXPERIENCE (1880s TO 1960s)',
      'Unit 3: SOCIAL, ECONOMIC AND POLITICAL DEVELOPMENTS IN ETHIOPIA, MID 19th C TO 1941',
      'Unit 4: SOCIETY AND POLITICS IN THE AGE OF WORLD WARS, 1914 TO 1945',
      'Unit 5: GLOBAL AND REGIONAL DEVELOPMENTS SINCE 1945',
      'Unit 6: ETHIOPIA INTERNAL DEVELOPMENTS AND EXTERNAL INFLUENCES FROM 1941 TO 1991',
      'Unit 7: AFRICA SINCE THE 1960s',
      'Unit 8: POST 1991 DEVELOPMENTS IN ETHIOPIA',
      'Unit 9: INDIGENOUS KNOWLEDGE SYSTEMS AND HERITAGES OF ETHIOPIA',
    ],
    'IT': [
      'Unit 1: INFORMATION SYSTEMS AND THEIR APPLICATIONS',
      'Unit 2: EMERGING TECHNOLOGIES',
      'Unit 3: DATABASE MANAGEMENT SYSTEM',
      'Unit 4: WEB AUTHORING',
      'Unit 5: MAINTENANCE AND TROUBLESHOOTING',
      'Unit 6: FUNDAMENTALS OF PROGRAMMING',
    ],
    'Mathematics': [
      'Unit 1: SEQUENCES AND SERIES',
      'Unit 2: INTRODUCTIONS TO CALCULUS',
      'Unit 3: STATISTICS',
      'Unit 4: INTRODUCTION TO LINEAR PROGRAMMING',
      'Unit 5: MATHEMATICAL APPLICATIONS IN BUSINESS',
    ],
  };

  // Content Types per Unit
  static const List<String> contentTypes = [
    'exam',
    'flashcard',
    'past_paper',
    'quiz',
    'short_note',
    'video',
  ];

  // Display names for content types
  static const Map<String, String> contentTypeDisplayNames = {
    'exam': 'Exam',
    'flashcard': 'Flashcard',
    'past_paper': 'Past Paper',
    'quiz': 'Quiz',
    'short_note': 'Short Note',
    'video': 'Video',
  };

  // Subject Colors (Blueprint exact hex values)
  static const Map<String, String> subjectColors = {
    'Mathematics': '#9C27B0',
    'English': '#2196F3',
    'Physics': '#FF9800',
    'Chemistry': '#4CAF50',
    'Biology': '#E91E63',
    'Aptitude': '#708090',
    'Geography': '#009688',
    'History': '#795548',
    'Economics': '#FF5722',
    'IT': '#3F51B5',
    'Agriculture': '#8BC34A',
    'Citizenship': '#00BCD4',
    'Logic': '#1A237E',
    'Psychology': '#CE93D8',
    'Anthropology': '#FFD54F',
    'Applied Mathematics': '#7E57C2',
    'C++ Programming': '#424242',
    'Emerging Technologies': '#B0BEC5',
    'English I': '#2196F3',
    'English II': '#2196F3',
    'English Skill 2': '#2196F3',
    'English Skill II': '#2196F3',
    'Entrepreneurship': '#FFD700',
    'Moral and Citizenship Education': '#808000',
  };

  // University Freshman First Semester - Natural Science
  static const Map<String, List<String>> freshmanNaturalSem1 = {
    'English I': [
      'Chapter 1_ study skills',
      'Chapter 2_ health and fitness',
      'Chapter 3_ cultural values',
      'Chapter 4_ wild life',
      'Chapter 5_ population',
    ],
    'Geography': [
      'Chapter 1_ introduction',
      'Chapter 2_ the geology of Ethiopia and the horn',
      'Chapter 3_ the topography of Ethiopia and the horn',
      'Chapter 4_ drainage system and water resource of Ethiopia and the horn',
      'Chapter 5_ the climate of Ethiopia and the horn',
      'Chapter 6_ soils, natural vegetation and wildlife resource',
      'Chapter 7_ population of ethiopia and the horn',
      'Chapter 8_ economic activitie in Ethiopia',
    ],
    'Logic': [
      'Chapter 1_ introduction to philosophy',
      'Chapter 2_ basic concept of logic',
      'Chapter 3_ logic and language',
      'Chapter 4_ basic concepts of critical thinking',
      'Chapter 5_ informal fallacies',
      'Chapter 6_ categorical propositions',
    ],
    'Mathematics': [
      'Chapter 1_ propositional logic and set theory',
      'Chapter 2_ the real and complex number system',
      'Chapter 3_ function',
      'Chapter 4_ analytic geometry',
    ],
    'Physics': [
      'Chapter 1_ preliminaries',
      'Chapter 2_ kinematic and dynamic of particles',
      'Chapter 3_ fluid dynamics',
      'Chapter 4_ heat and thermodynamics',
      'Chapter 5_ oscillation, waves and optics',
      'Chapter 6_ electromagnetism and electronics',
      'Chapter 7_ cross cutting application of physics',
    ],
    'Psychology': [
      'Chapter 1_ essence of psychology',
      'Chapter 2_ sensation and perception',
      'Chapter 3_ leaning and theories of learning',
      'Chapter 4_ memory and forgetting',
      'Chapter 5_ motivation and emotion',
      'Chapter 6_ personality',
      'Chapter 7_ psychological disorder and treatment techniques',
      'Chapter 8_ intro to life skills',
      'Chapter 9_ inta-personal and interpersonal skills',
      'Chapter 10_ academic skills',
      'Chapter 11_ social skills',
    ],
  };

  // University Freshman First Semester - Social Science
  // Values are the exact GitHub folder names; display titles are derived with
  // displayChapterTitle() so navigation never depends on repository metadata.
  static const Map<String, List<String>> freshmanSocialSem1 = {
    'Economics': [
      'Chapter 1_ basics of economics',
      'Chapter 2_ theory of demand and supply',
      'Chapter 3_ theory of customer behaviour',
      'Chapter 4_ the theory of production and cost',
      'Chapter 5_ market structure',
      'Chapter 6_ fundamental concepts of macroeconomics',
    ],
    'English I': [
      'Chapter 1_ study skills',
      'Chapter 2_ health and fitness',
      'Chapter 3_ cultural values',
      'Chapter 4_ wild life',
      'Chapter 5_ population',
    ],
    'Geography': [
      'Chapter 1_ introduction',
      'Chapter 2_ the geology of Ethiopia and the horn',
      'Chapter 3_ the topography of Ethiopia and the horn',
      'Chapter 4_ drainage system and water resource of Ethiopia and the horn',
      'Chapter 5_ the climate of Ethiopia and the horn',
      'Chapter 6_ soils, natural vegetation and wildlife resource',
      'Chapter 7_ population of ethiopia and the horn',
      'Chapter 8_ economic activitie in Ethiopia',
    ],
    'Logic': [
      'Chapter 1_ introduction to philosophy',
      'Chapter 2_ basic concept of logic',
      'Chapter 3_ logic and language',
      'Chapter 4_ basic concepts of critical thinking',
      'Chapter 5_ informal fallacies',
      'Chapter 6_ categorical propositions',
    ],
    'Mathematics': [
      'Chapter 1_ propositional logic and set theory',
      'Chapter 2_ function',
      'Chapter 2_ the real and complex number system',
      'Chapter 3_ matrices and determinant',
      'Chapter 4_ introduction to calculus',
    ],
    'Psychology': [
      'Chapter 1_ essence of psychology',
      'Chapter 2_ sensation and perception',
      'Chapter 3_ leaning and theories of learning',
      'Chapter 4_ memory and forgetting',
      'Chapter 5_ motivation and emotion',
      'Chapter 6_ personality',
      'Chapter 7_ psychological disorder and treatment techniques',
      'Chapter 8_ intro to life skills',
      'Chapter 9_ inta-personal and interpersonal skills',
      'Chapter 10_ academic skills',
      'Chapter 11_ social skills',
    ],
  };

  // University Freshman Second Semester - Pre-Engineering
  static const Map<String, List<String>> freshmanPreEngSem2 = {
    'Anthropology': [
      'Unit 1: Introducing Anthropology and its Subject Matter',
      'Unit 2: Human Culture and Ties that Connect',
      'Unit 3: Human Diversity, Culture Areas and Contact in Ethiopia',
      'Unit 4: Marginalized, Minorities, and Vulnerable Groups',
      'Unit 5: Identity, Inter-Ethnic Relations and Multiculturalism in Ethiopia',
      'Unit 6: Customary and Local Governance Systems and Peace Making',
      'Unit 7: Indigenous Knowledge Systems (IKS) and Practices',
    ],
    'Applied Mathematics': [
      'Chapter 1: Vectors and Vector Spaces',
      'Chapter 2: Matrices and Determinants',
      'Chapter 3: Limit and Continuity',
      'Chapter 4: Derivatives',
      'Chapter 5: Application of Derivative',
      'Chapter 6: Integration',
      'Chapter 7: Integration Techniques',
      'Chapter 8: Improper Integrals',
      'Chapter 9: Application of Integration (Area)',
      'Chapter 10: Volume of Solids of Revolution',
      'Chapter 11: Arc Length',
      'Chapter 12: Surface Area',
    ],
    'C++ Programming': [
      'Chapter 1: Introduction to C++ Programming',
      'Chapter 2: Basics of C++ (Comments, Case Sensitivity, Statements)',
      'Chapter 3: Primitive Data Types',
      'Chapter 4: Flow of Controls',
      'Chapter 5: Arrays and Strings',
      'Chapter 6: Functions',
      'Chapter 7: Structures and Unions',
      'Chapter 8: Pointers',
    ],
    'Emerging Technologies': [
      'Chapter 1: Introduction to Emerging Technologies',
      'Chapter 2: Overview for Data Science',
      'Chapter 3: Introduction to Artificial Intelligence (AI)',
      'Chapter 4: Internet of Things (IoT)',
      'Chapter 5: Augmented Reality',
      'Chapter 6: Ethics and Professionalism of Emerging Technologies',
      'Chapter 7: Other Emerging Technologies',
    ],
    'English II': [
      'Unit 1: Life Skills',
      'Unit 2: Speculations about the Future of Science',
      'Unit 3: Environmental Protection',
      'Unit 4: Indigenous Knowledge',
      'Unit 5: Cultural Heritage',
    ],
    'Entrepreneurship': [
      'Chapter 1: The Nature of Entrepreneurship',
      'Chapter 2: Business Planning',
      'Chapter 3: Business Formation',
      'Chapter 4: Product-Service Development',
      'Chapter 5: Marketing',
      'Chapter 6: Business Financing',
      'Chapter 7: Managing Growth and Transition',
    ],
    'History': [
      'Chapter 1: Introduction',
      'Chapter 2: Peoples and Cultures in Ethiopia and the Horn',
      'Chapter 3: Politics, Economy and Socio Cultural Processes in Ethiopia to End of the 13th Century',
      'Chapter 4: Politics, Economy and Socio Cultural Processes in Ethiopia from Late 13th to 16th Century',
      'Chapter 5: Politics, Economy and Socio Cultural Processes in Ethiopia from Early 16th to 18th Century',
      'Chapter 6: Internal Interactions and External Relations in Ethiopia 1800-1941',
      'Chapter 7: Internal Developments and External Relations, 1941-1994',
    ],
    'Moral and Citizenship Education': [
      'Chapter 1: Understanding Civics and Ethics',
      'Chapter 2: Approaches to Ethics',
      'Chapter 3: Ethical Decision Making and Moral Judgments',
      'Chapter 4: State, Government and Citizenship',
      'Chapter 5: Constitution, Democracy and Human Rights',
    ],
  };

  // University Freshman Second Semester - Other Natural Science
  static const Map<String, List<String>> freshmanOtherNaturalSem2 = {
    'Anthropology': [
      'Unit 1: Introducing Anthropology and its Subject Matter',
      'Unit 2: Human Culture and Ties that Connect',
      'Unit 3: Human Diversity, Culture Areas and Contact in Ethiopia',
      'Unit 4: Marginalized, Minorities, and Vulnerable Groups',
      'Unit 5: Identity, Inter-Ethnic Relations and Multiculturalism in Ethiopia',
      'Unit 6: Customary and Local Governance Systems and Peace Making',
      'Unit 7: Indigenous Knowledge Systems (IKS) and Practices',
    ],
    'Biology': [
      'Chapter 1: Introduction',
      'Chapter 2: Biological Molecules',
      'Chapter 3: The Cellular Basics of Life',
      'Chapter 4: Cellular Metabolism and Metabolic Disorder',
      'Chapter 5: Genetics and Evolution',
      'Chapter 6: Infectious Diseases and Immunity',
      'Chapter 7: Taxonomy of Organism',
      'Chapter 8: Ecology and Conservation of Natural Resources',
      'Chapter 9: Introduction to Botany and Zoology',
      'Chapter 10: Application of Biological Science',
    ],
    'Chemistry': [
      'Chapter 1: Essential Ideas in Chemistry',
      'Chapter 2: Atoms, Molecules and Ions',
      'Chapter 3: Mass and Mole Concept',
      'Chapter 4: Stoichiometry of Chemical Reaction',
      'Chapter 5: Electronic Structure and Periodic Properties of Elements',
      'Chapter 6: Chemical Bonding and Molecular Geometry',
      'Chapter 7: Equilibrium Concepts and Acid Base Equilibrium',
      'Chapter 8: Organic Chemistry',
    ],
    'Economics': [
      'Chapter 1: Basics of Economics',
      'Chapter 2: Theory of Demand and Supply',
      'Chapter 3: Theory of Customer Behaviour',
      'Chapter 4: The Theory of Production and Cost',
      'Chapter 5: Market Structure',
      'Chapter 6: Fundamental Concepts of Macroeconomics',
    ],
    'Emerging Technologies': [
      'Chapter 1: Introduction to Emerging Technologies',
      'Chapter 2: Overview for Data Science',
      'Chapter 3: Introduction to Artificial Intelligence (AI)',
      'Chapter 4: Internet of Things (IoT)',
      'Chapter 5: Augmented Reality',
      'Chapter 6: Ethics and Professionalism of Emerging Technologies',
      'Chapter 7: Other Emerging Technologies',
    ],
    'English II': [
      'Unit 1: Life Skills',
      'Unit 2: Speculations about the Future of Science',
      'Unit 3: Environmental Protection',
      'Unit 4: Indigenous Knowledge',
      'Unit 5: Cultural Heritage',
    ],
    'History': [
      'Chapter 1: Introduction',
      'Chapter 2: Peoples and Cultures in Ethiopia and the Horn',
      'Chapter 3: Politics, Economy and Socio Cultural Processes in Ethiopia to End of the 13th Century',
      'Chapter 4: Politics, Economy and Socio Cultural Processes in Ethiopia from Late 13th to 16th Century',
      'Chapter 5: Politics, Economy and Socio Cultural Processes in Ethiopia from Early 16th to 18th Century',
      'Chapter 6: Internal Interactions and External Relations in Ethiopia 1800-1941',
      'Chapter 7: Internal Developments and External Relations, 1941-1994',
    ],
    'Moral and Citizenship Education': [
      'Chapter 1: Understanding Civics and Ethics',
      'Chapter 2: Approaches to Ethics',
      'Chapter 3: Ethical Decision Making and Moral Judgments',
      'Chapter 4: State, Government and Citizenship',
      'Chapter 5: Constitution, Democracy and Human Rights',
    ],
  };

  // University Freshman Second Semester - Social Science
  static const Map<String, List<String>> freshmanSocialSem2 = {
    'Anthropology': [
      'Unit 1: Introducing Anthropology and its Subject Matter',
      'Unit 2: Human Culture and Ties that Connect',
      'Unit 3: Human Diversity, Culture Areas and Contact in Ethiopia',
      'Unit 4: Marginalized, Minorities, and Vulnerable Groups',
      'Unit 5: Identity, Inter-Ethnic Relations and Multiculturalism in Ethiopia',
      'Unit 6: Customary and Local Governance Systems and Peace Making',
      'Unit 7: Indigenous Knowledge Systems (IKS) and Practices',
    ],
    'Economics': [
      'Chapter 1: Basics of Economics',
      'Chapter 2: Theory of Demand and Supply',
      'Chapter 3: Theory of Customer Behaviour',
      'Chapter 4: The Theory of Production and Cost',
      'Chapter 5: Market Structure',
      'Chapter 6: Fundamental Concepts of Macroeconomics',
    ],
    'Emerging Technologies': [
      'Chapter 1: Introduction to Emerging Technologies',
      'Chapter 2: Overview for Data Science',
      'Chapter 3: Introduction to Artificial Intelligence (AI)',
      'Chapter 4: Internet of Things (IoT)',
      'Chapter 5: Augmented Reality',
      'Chapter 6: Ethics and Professionalism of Emerging Technologies',
      'Chapter 7: Other Emerging Technologies',
    ],
    'English II': [
      'Unit I: Life Skills',
      'Unit II: Speculations about the Future of Science',
      'Unit III: Environmental Protection',
      'Unit IV: Indigenous Knowledge',
      'Unit V: Cultural Heritage',
    ],
    'Entrepreneurship': [
      'Chapter 1: The Nature of Entrepreneurship',
      'Chapter 2: Business Planning',
      'Chapter 3: Business Formation',
      'Chapter 4: Product-Service Development',
      'Chapter 5: Marketing',
      'Chapter 6: Business Financing',
      'Chapter 7: Managing Growth and Transition',
    ],
    'History': [
      'Chapter 1: Introduction',
      'Chapter 2: Peoples and Cultures in Ethiopia and the Horn',
      'Chapter 3: Politics, Economy and Socio Cultural Processes in Ethiopia to End of the 13th Century',
      'Chapter 4: Politics, Economy and Socio Cultural Processes in Ethiopia from Late 13th to 16th Century',
      'Chapter 5: Politics, Economy and Socio Cultural Processes in Ethiopia from Early 16th to 18th Century',
      'Chapter 6: Internal Interactions and External Relations in Ethiopia 1800-1941',
      'Chapter 7: Internal Developments and External Relations, 1941-1994',
    ],
    'Moral and Citizenship Education': [
      'Chapter 1: Understanding Civics and Ethics',
      'Chapter 2: Approaches to Ethics',
      'Chapter 3: Ethical Decision Making and Moral Judgments',
      'Chapter 4: State, Government and Citizenship',
      'Chapter 5: Constitution, Democracy and Human Rights',
    ],
  };

  // Entrance curriculum mirrors the exact GitHub hierarchy so navigation is
  // fully hardcoded/offline. Content is fetched only after a unit is opened.
  static const Map<String, Map<String, List<String>>> entranceNaturalScienceChapters =
  {
    'Aptitude': {
      '9': [
        'Part 1_ Mathematical Aptitude',
        'Part 2_ English Aptitude',
        'Part 3_ Logical Reasoning',
        'Part 4_ Critical Thinking'
      ],
      '10': [
        'Part 1_ Mathematical Aptitude',
        'Part 2_ English Aptitude',
        'Part 3_ Logical Reasoning',
        'Part 4_ Critical Thinking'
      ],
      '11': [
        'Part 1_ Mathematical Aptitude',
        'Part 2_ English Aptitude',
        'Part 3_ Logical Reasoning',
        'Part 4_ Critical Thinking'
      ],
      '12': [
        'Part 1_ Mathematical Aptitude',
        'Part 2_ English Aptitude',
        'Part 3_ Logical Reasoning',
        'Part 4_ Critical Thinking'
      ],
    },
    'Biology': {
      '9': [
        'Unit 1_ INTRODUCTION TO BIOLOGY',
        'Unit 2_ CHARACTERISTICS AND CLASSIFICATION OF ORGANISMS',
        'Unit 3_ CELLS',
        'Unit 4_ REPRODUCTION',
        'Unit 5_ HUMAN HEALTH, NUTRITION, AND DISEASE',
        'Unit 6_ ECOLOGY'
      ],
      '10': [
        'Unit 1_ SUB-FIELDS OF BIOLOGY',
        'Unit 2_ PLANTS',
        'Unit 3_ BIOCHEMICAL MOLECULES',
        'Unit 4_ CELL REPRODUCTION',
        'Unit 5_ HUMAN BIOLOGY',
        'Unit 6_ ECOLOGICAL INTERACTION'
      ],
      '11': [
        'Unit 1_ BIOLOGY AND TECHNOLOGY',
        'Unit 2_ ANIMALS',
        'Unit 3_ ENZYMES',
        'Unit 4_ GENETICS',
        'Unit 5_ THE HUMAN BODY SYSTEMS',
        'Unit 6_ POPULATION AND NATURAL RESOURCES'
      ],
      '12': [
        'Unit 1_ APPLICATION OF BIOLOGY',
        'Unit 2_ MICROORGANISMS',
        'Unit 3_ ENERGY TRANSFORMATION',
        'Unit 4_ EVOLUTION',
        'Unit 5_ HUMAN BODY SYSTEM',
        'Unit 6_ CLIMATE CHANGE'
      ],
    },
    'Chemistry': {
      '9': [
        'Unit 1_ CHEMISTRY AND ITS IMPORTANCE',
        'Unit 2_ MEASUREMENTS AND SCIENTIFIC METHODS',
        'Unit 3_ STRUCTURE OF THE ATOM',
        'Unit 4_ PERIODIC CLASSIFICATION OF ELEMENTS',
        'Unit 5_ CHEMICAL BONDING'
      ],
      '10': [
        'Unit 1_ CHEMICAL REACTIONS AND STOICHIOMETRY',
        'Unit 2_ SOLUTIONS',
        'Unit 3_ IMPORTANT INORGANIC COMPOUNDS',
        'Unit 4_ ENERGY CHANGES AND ELECTROCHEMISTRY',
        'Unit 5_ METALS AND NONMETALS',
        'Unit 6_ HYDROCARBONS AND THEIR NATURAL SOURCES'
      ],
      '11': [
        'Unit 1_ ATOMIC STRUCTURE AND PERIODIC PROPERTIES OF THE ELEMENTS',
        'Unit 2_ Chemical Bonding',
        'Unit 3_ PHYSICAL STATES OF MATTER',
        'Unit 4_ CHEMICAL KINETICS',
        'Unit 5_ CHEMICAL EQUILIBRIUM',
        'Unit 6_ SOME IMPORTANT OXYGEN-CONTAINING ORGANIC COMPOUNDS'
      ],
      '12': [
        'Unit 1_ ACID-BASE CONCEPTS AND IONIC EQUILIBRIA',
        'Unit 2_ ELECTROCHEMISTRY',
        'Unit 3_ INDUSTRIAL CHEMISTRY',
        'Unit 4_ POLYMERS',
        'Unit 5_ INTRODUCTION TO ENVIRONMENTAL CHEMISTRY'
      ],
    },
    'English': {
      '9': [
        'Unit 1_ LIVING IN URBAN AREAS',
        'Unit 2_ STUDY SKILLS',
        'Unit 3_ TRAFFIC ACCIDENT',
        'Unit 4_ NATIONAL PARKS',
        'Unit 5_ HORTICULTURE',
        'Unit 6_ POVERTY IN ETHIOPIA',
        'Unit 7_ COMMUNITY SERVICES',
        'Unit 8_ COMMUNICABLE DISEASES'
      ],
      '10': [
        'Unit 1_ POPULATION GROWTH',
        'Unit 2_ TRAVEL BEHAVIORS',
        'Unit 3_ PUNCTUALITY',
        'Unit 4_ TOURIST ATTRACTIONS',
        'Unit 5_ HONEY PROCESSING',
        'Unit 6_ MIGRATION',
        'Unit 7_ BRANDING ETHIOPIA AND NATIONAL IDENTITY',
        'Unit 8_ THE HEALING POWER OF PLANTS',
        'Unit 9_ MULTILINGUALISM',
        'Unit 10_ DIGITAL VS SATELLITE TELEVISION'
      ],
      '11': [
        'Unit 1_ ENVIRONMENTAL HAZARDS',
        'Unit 2_ CIVILIZATION',
        'Unit 3_ CAUSES OF ROAD TRAFFIC ACCIDENTS',
        'Unit 4_ PEOPLE AND NATURAL RESOURCES',
        'Unit 5_ IRRIGATION',
        'Unit 6_ GLOBAL WARMING',
        'Unit 7_ PATRIOTISM',
        'Unit 8_ EFFICIENCY OF HEALTH SERVICES',
        'Unit 9_ INDIGENOUS CONFLICT RESOLUTION',
        'Unit 10_ ARTIFICIAL INTELLIGENCE'
      ],
      '12': [
        'Unit 1_ SUSTAINABLE DEVELOPMENT',
        'Unit 2_ TIME MANAGEMENT',
        'Unit 3_ EVIDENCE ON TRAFFIC ACCIDENT',
        'Unit 4_ NATURAL RESOURCE MANAGEMENT',
        'Unit 5_ MECHANIZED AGRICULTURE',
        'Unit 6_ GREEN ECONOMIES',
        'Unit 7_ NATIONAL PRIDE',
        'Unit 8_ TELEMEDICINE',
        'Unit 9_ CONFLICT MANAGEMENT',
        'Unit 10_ ROBOTICS'
      ],
    },
    'Mathematics': {
      '9': [
        'Unit 1_ FURTHER ON SETS',
        'Unit 2_ THE NUMBER SYSTEM',
        'Unit 3_ SOLVING EQUATIONS',
        'Unit 4_ SOLVING INEQUALITIES',
        'Unit 5_ INTRODUCTION TO TRIGONOMETRY',
        'Unit 6_ REGULAR POLYGONS',
        'Unit 7_ CONGRUENCY AND SIMILARITY',
        'Unit 8_ VECTORS IN TWO DIMENSIONS',
        'Unit 9_ STATISTICS AND PROBABILITY'
      ],
      '10': [
        'Unit 1_ Relations and Functions',
        'Unit 2_ POLYNOMIAL FUNCTIONS',
        'Unit 3_ EXPONENTIAL AND LOGARITHMIC FUNCTIONS',
        'Unit 4_ TRIGONOMETRIC FUNCTIONS',
        'Unit 5_ CIRCLES',
        'Unit 6_ SOLID FIGURES',
        'Unit 7_ COORDINATE GEOMETRY'
      ],
      '11': [
        'Unit 1_ Relations and Functions',
        'Unit 2_ RATIONAL EXPRESSIONS AND RATIONAL FUNCTIONS',
        'Unit 3_ MATRICES',
        'Unit 4_ DETERMINANTS AND THEIR PROPERTIES',
        'Unit 5_ VECTORS'
      ],
      '12': [
        'Unit 1_ SEQUENCES AND SERIES',
        'Unit 2_ INTRODUCTIONS TO CALCULUS',
        'Unit 3_ STATISTICS',
        'Unit 4_ INTRODUCTION TO LINEAR PROGRAMMING',
        'Unit 5_ MATHEMATICAL APPLICATIONS IN BUSINESS'
      ],
    },
    'Physics': {
      '9': [
        'Unit 1_ PHYSICS AND HUMAN SOCIETY',
        'Unit 2_ PHYSICAL QUANTITIES',
        'Unit 3_ MOTION IN A STRAIGHT LINE',
        'Unit 4_ FORCE, WORK, ENERGY AND POWER',
        'Unit 5_ SIMPLE MACHINES',
        'Unit 6_ MECHANICAL OSCILLATION AND SOUND WAVE',
        'Unit 7_ TEMPERATURE AND THERMOMETRY'
      ],
      '10': [
        'Unit 1_ VECTOR QUANTITIES',
        'Unit 2_ UNIFORMLY ACCELERATED MOTION',
        'Unit 3_ ELASTICITY AND STATIC EQUILIBRIUM OF RIGID BODY',
        'Unit 4_ STATIC AND CURRENT ELECTRICITY',
        'Unit 5_ MAGNETISM',
        'Unit 6_ ELECTROMAGNETIC WAVES AND GEOMETRICAL OPTICS'
      ],
      '11': [
        'Unit 1_ PHYSICS AND HUMAN SOCIETY',
        'Unit 2_ VECTORS',
        'Unit 3_ MOTION IN ONE AND TWO DIMENSIONS',
        'Unit 4_ DYNAMICS',
        'Unit 5_ HEAT CONDUCTION AND CALORIMETRY',
        'Unit 6_ ELECTROSTATICS AND ELECTRIC CIRCUIT',
        'Unit 7_ NUCLEAR PHYSICS'
      ],
      '12': [
        'Unit 1_ APPLICATION OF PHYSICS IN OTHER FIELDS',
        'Unit 2_ TWO-DIMENSIONAL MOTION',
        'Unit 3_ FLUID MECHANICS',
        'Unit 4_ ELECTROMAGNETISM',
        'Unit 5_ BASICS OF ELECTRONICS'
      ],
    },
  };

  static const Map<String, Map<String, List<String>>> entranceSocialScienceChapters =
  {
    'Aptitude': {
      '9': [
        'Part 1_ Mathematical Aptitude',
        'Part 2_ English Aptitude',
        'Part 3_ Logical Reasoning',
        'Part 4_ Critical Thinking'
      ],
      '10': [
        'Part 1_ Mathematical Aptitude',
        'Part 2_ English Aptitude',
        'Part 3_ Logical Reasoning',
        'Part 4_ Critical Thinking'
      ],
      '11': [
        'Part 1_ Mathematical Aptitude',
        'Part 2_ English Aptitude',
        'Part 3_ Logical Reasoning',
        'Part 4_ Critical Thinking'
      ],
      '12': [
        'Part 1_ Mathematical Aptitude',
        'Part 2_ English Aptitude',
        'Part 3_ Logical Reasoning',
        'Part 4_ Critical Thinking'
      ],
    },
    'Economics': {
      '9': [
        'Unit 1_ INTRODUCING ECONOMICS',
        'Unit 2_ THE BASIC ECONOMIC PROBLEMS AND ECONOMIC SYSTEMS',
        'Unit 3_ ECONOMIC RESOURCES AND MARKETS',
        'Unit 4_ INTRODUCTION TO DEMAND AND SUPPLY',
        'Unit 5_ INTRODUCTION TO PRODUCTION AND COST',
        'Unit 6_ INTRODUCTION TO MONEY',
        'Unit 7_ INTRODUCTION TO MACROECONOMICS',
        'Unit 8_ BASIC ENTREPRENEURSHIP'
      ],
      '10': [
        'Unit 1_ THEORY OF CONSUMER BEHAVIOUR',
        'Unit 2_ THEORIES OF DEMAND AND SUPPLY',
        'Unit 3_ THEORIES OF PRODUCTION AND COST',
        'Unit 4_ MARKET STRUCTURE',
        'Unit 5_ BANKING AND FINANCE',
        'Unit 6_ ECONOMIC GROWTH',
        'Unit 7_ THE ETHIOPIAN ECONOMY',
        'Unit 8_ BUSINESS STARTUPS AND INNOVATION'
      ],
      '11': [
        'Unit 1_ THEORY OF CONSUMER BEHAVIOR AND DEMAND',
        'Unit 2_ MARKET STRUCTURE AND THE DECISION OF FIRMS',
        'Unit 3_ NATIONAL INCOME ACCOUNTING',
        'Unit 4_ CONSUMPTION, SAVING AND INVESTMENT',
        'Unit 5_ TRADE AND FINANCE',
        'Unit 6_ ECONOMIC DEVELOPMENT',
        'Unit 7_ MAIN SECTORS, SECTORIAL POLICIES AND STRATEGIES OF ETHIOPIA'
      ],
      '12': [
        'Unit 1_ THE FUNDAMENTAL CONCEPTS OF MACROECONOMICS',
        'Unit 2_ AGGREGATE DEMAND AND AGGREGATE SUPPLY ANALYSIS',
        'Unit 3_ MARKET FAILURE AND CONSUMER PROTECTION',
        'Unit 4_ MACROECONOMIC POLICY INSTRUMENTS',
        'Unit 5_ TAX THEORY AND PRACTICE',
        'Unit 6_ POVERTY AND INEQUALITY',
        'Unit 7_ MACROECONOMIC REFORMS IN ETHIOPIA',
        'Unit 8_ ECONOMY, ENVIRONMENT AND CLIMATE CHANGE'
      ],
    },
    'English': {
      '9': [
        'Unit 1_ LIVING IN URBAN AREAS',
        'Unit 2_ STUDY SKILLS',
        'Unit 3_ TRAFFIC ACCIDENT',
        'Unit 4_ NATIONAL PARKS',
        'Unit 5_ HORTICULTURE',
        'Unit 6_ POVERTY IN ETHIOPIA',
        'Unit 7_ COMMUNITY SERVICES',
        'Unit 8_ COMMUNICABLE DISEASES'
      ],
      '10': [
        'Unit 1_ POPULATION GROWTH',
        'Unit 2_ TRAVEL BEHAVIORS',
        'Unit 3_ PUNCTUALITY',
        'Unit 4_ TOURIST ATTRACTIONS',
        'Unit 5_ HONEY PROCESSING',
        'Unit 6_ MIGRATION',
        'Unit 7_ BRANDING ETHIOPIA AND NATIONAL IDENTITY',
        'Unit 8_ THE HEALING POWER OF PLANTS',
        'Unit 9_ MULTILINGUALISM',
        'Unit 10_ DIGITAL VS SATELLITE TELEVISION'
      ],
      '11': [
        'Unit 1_ ENVIRONMENTAL HAZARDS',
        'Unit 2_ CIVILIZATION',
        'Unit 3_ CAUSES OF ROAD TRAFFIC ACCIDENTS',
        'Unit 4_ PEOPLE AND NATURAL RESOURCES',
        'Unit 5_ IRRIGATION',
        'Unit 6_ GLOBAL WARMING',
        'Unit 7_ PATRIOTISM',
        'Unit 8_ EFFICIENCY OF HEALTH SERVICES',
        'Unit 9_ INDIGENOUS CONFLICT RESOLUTION',
        'Unit 10_ ARTIFICIAL INTELLIGENCE'
      ],
      '12': [
        'Unit 1_ SUSTAINABLE DEVELOPMENT',
        'Unit 2_ TIME MANAGEMENT',
        'Unit 3_ EVIDENCE ON TRAFFIC ACCIDENT',
        'Unit 4_ NATURAL RESOURCE MANAGEMENT',
        'Unit 5_ MECHANIZED AGRICULTURE',
        'Unit 6_ GREEN ECONOMIES',
        'Unit 7_ NATIONAL PRIDE',
        'Unit 8_ TELEMEDICINE',
        'Unit 9_ CONFLICT MANAGEMENT',
        'Unit 10_ ROBOTICS'
      ],
    },
    'Geography': {
      '9': [
        'Unit 1_ INTRODUCTION TO GEOGRAPHY',
        'Unit 2_ THE EARTH',
        'Unit 3_ MAP READING AND INTERPRETATION',
        'Unit 4_ THE PHYSICAL ENVIRONMENT OF ETHIOPIA',
        'Unit 5_ POPULATION OF ETHIOPIA',
        'Unit 6_ ECONOMIC ACTIVITIES IN ETHIOPIA'
      ],
      '10': [
        'Unit 1_ LANDFORMS OF AFRICA',
        'Unit 2_ CLIMATE OF AFRICA',
        'Unit 3_ NATURAL RESOURCE BASE OF AFRICA',
        'Unit 4_ POPULATION OF AFRICA',
        'Unit 5_ MAJOR ECONOMIC AND CULTURAL ACTIVITIES OF AFRICA',
        'Unit 6_ HUMAN NATURAL ENVIRONMENT INTERACTIONS',
        'Unit 7_ GEOGRAPHIC ISSUES AND PUBLIC CONCERNS IN AFRICA',
        'Unit 8_ GEOSPATIAL INFORMATION AND DATA PROCESSING'
      ],
      '11': [
        'Unit 1_ FORMATION OF THE CONTINENTS',
        'Unit 2_ CLIMATE CLASSIFICATION AND CLIMATE REGIONS OF OUR WORLD',
        'Unit 3_ NATURAL RESOURCES AND CONFLICTS OVER RESOURCES',
        'Unit 4_ GLOBAL POPULATION DYNAMICS AND CHALLENGES',
        'Unit 5_ GEOGRAPHY AND ECONOMIC DEVELOPMENT',
        'Unit 6_ MAJOR GLOBAL ENVIRONMENTAL CHANGES',
        'Unit 7_ GEOGRAPHIC ISSUES AND PUBLIC CONCERNS',
        'Unit 8_ GEO-SPATIAL INFORMATION AND DATA PROCESSING'
      ],
      '12': [
        'Unit 1_ MAJOR GEOLOGICAL PROCESSES ASSOCIATED WITH PLATE TECTONICS',
        'Unit 2_ CLIMATE CHANGE',
        'Unit 3_ ISSUES IN SUSTAINABLE DEVELOPMENT I - MANAGEMENT OF CONFLICT OVER RESOURCES',
        'Unit 4_ ISSUES IN SUSTAINABLE DEVELOPMENT II - POPULATION POLICIES, PROGRAMS AND THE ENVIRONMENT',
        'Unit 5_ ISSUES IN SUSTAINABLE DEVELOPMENT III - CHALLENGES OF ECONOMIC DEVELOPMENT',
        'Unit 6_ ISSUES IN SUSTAINABLE DEVELOPMENT IV - SOLUTIONS TO ENVIRONMENTAL AND SUSTAINABILITY PROBLEMS',
        'Unit 7_ CONTEMPORARY GLOBAL GEOGRAPHIC ISSUES AND PUBLIC CONCERNS',
        'Unit 8_ GEOGRAPHICAL ENQUIRY AND MAP MAKING'
      ],
    },
    'History': {
      '9': [
        'Unit 1_ THE DISCIPLINE OF HISTORY AND HUMAN EVOLUTION',
        'Unit 2_ ANCIENT WORLD CIVILIZATIONS UP TO c. 500 AD',
        'Unit 3_ PEOPLES AND STATES IN ETHIOPIA AND THE HORN TO THE END OF 13th C',
        'Unit 4_ THE MIDDLE AGES AND EARLY MODERN WORLD, C. 500 TO 1750s',
        'Unit 5_ PEOPLES AND STATES OF AFRICA TO 1500',
        'Unit 6_ AFRICA AND THE OUTSIDE WORLD 1500-1880s',
        'Unit 7_ STATES, PRINCIPALITIES, POPULATION MOVEMENTS AND INTERACTIONS IN ETHIOPIA 13th TO MID-16th C',
        'Unit 8_ POLITICAL, SOCIAL AND ECONOMIC PROCESSES IN ETHIOPIA MID-16th TO MID-19th C',
        'Unit 9_ THE AGE OF REVOLUTIONS 1750s TO 1815'
      ],
      '10': [
        'Unit 1_ DEVELOPMENT OF CAPITALISM AND NATIONALISM 1815-1914',
        'Unit 2_ AFRICA AND THE COLONIAL EXPERIENCE (1880s-1960s)',
        'Unit 3_ SOCIAL, ECONOMIC AND POLITICAL DEVELOPMENTS IN ETHIOPIA MID 19th C TO 1941',
        'Unit 4_ SOCIETY AND POLITICS IN THE AGE OF WORLD WARS 1914-1945',
        'Unit 5_ GLOBAL AND REGIONAL DEVELOPMENTS SINCE 1945',
        'Unit 6_ ETHIOPIA INTERNAL DEVELOPMENTS AND EXTERNAL INFLUENCES FROM 1941 TO 1991',
        'Unit 7_ AFRICA SINCE 1960',
        'Unit 8_ POST-1991 DEVELOPMENTS IN ETHIOPIA',
        'Unit 9_ INDIGENOUS KNOWLEDGE AND HERITAGES OF ETHIOPIA'
      ],
      '11': [
        'Unit 1_ HISTORY, HISTORIOGRAPHY, AND HUMAN EVOLUTION',
        'Unit 2_ MAJOR SPOTS OF ANCIENT WORLD CIVILIZATIONS UP TO c.500 A.D',
        'Unit 3_ PEOPLES, STATES AND HISTORICAL PROCESSES IN ETHIOPIA AND THE HORN TO THE END OF THE 13TH CENTURY',
        'Unit 4_ THE MIDDLE AGES AND EARLY MODERN WORLD, C. 500 AD-1789',
        'Unit 5_ PEOPLES AND STATES OF AFRICA TO 1500',
        'Unit 6_ AFRICA AND THE OUTSIDE WORLD 1500-1880s',
        'Unit 7_ STATES, PRINCIPALITIES, POPULATION MOVEMENTS AND INTERACTIONS IN ETHIOPIA',
        'Unit 8_ POLITICAL, SOCIAL AND ECONOMIC PROCESSES IN ETHIOPIA, MID 16TH TO MID-19TH CENTURY',
        'Unit 9_ THE AGE OF REVOLUTIONS, 1789 TO 1815'
      ],
      '12': [
        'Unit 1_ DEVELOPMENT OF CAPITALISM AND NATIONALISM FROM 1815 TO 1914',
        'Unit 2_ AFRICA AND THE COLONIAL EXPERIENCE (1880s TO 1960s)',
        'Unit 3_ SOCIAL, ECONOMIC AND POLITICAL DEVELOPMENTS IN ETHIOPIA, MID 19th C TO 1941',
        'Unit 4_ SOCIETY AND POLITICS IN THE AGE OF WORLD WARS, 1914 TO 1945',
        'Unit 5_ GLOBAL AND REGIONAL DEVELOPMENTS SINCE 1945',
        'Unit 6_ ETHIOPIA INTERNAL DEVELOPMENTS AND EXTERNAL INFLUENCES FROM 1941 TO 1991',
        'Unit 7_ AFRICA SINCE THE 1960s',
        'Unit 8_ POST 1991 DEVELOPMENTS IN ETHIOPIA',
        'Unit 9_ INDIGENOUS KNOWLEDGE SYSTEMS AND HERITAGES OF ETHIOPIA'
      ],
    },
    'Mathematics': {
      '9': [
        'Unit 1_ FURTHER ON SETS',
        'Unit 2_ THE NUMBER SYSTEM',
        'Unit 3_ SOLVING EQUATIONS',
        'Unit 4_ SOLVING INEQUALITIES',
        'Unit 5_ INTRODUCTION TO TRIGONOMETRY',
        'Unit 6_ REGULAR POLYGONS',
        'Unit 7_ CONGRUENCY AND SIMILARITY',
        'Unit 8_ VECTORS IN TWO DIMENSIONS',
        'Unit 9_ STATISTICS AND PROBABILITY'
      ],
      '10': [
        'Unit 1_ Relations and Functions',
        'Unit 2_ POLYNOMIAL FUNCTIONS',
        'Unit 3_ EXPONENTIAL AND LOGARITHMIC FUNCTIONS',
        'Unit 4_ TRIGONOMETRIC FUNCTIONS',
        'Unit 5_ CIRCLES',
        'Unit 6_ SOLID FIGURES',
        'Unit 7_ COORDINATE GEOMETRY'
      ],
      '11': [
        'Unit 1_ Relations and Functions',
        'Unit 2_ RATIONAL EXPRESSIONS AND RATIONAL FUNCTIONS',
        'Unit 3_ MATRICES',
        'Unit 4_ DETERMINANTS AND THEIR PROPERTIES',
        'Unit 5_ VECTORS'
      ],
      '12': [
        'Unit 1_ SEQUENCES AND SERIES',
        'Unit 2_ INTRODUCTIONS TO CALCULUS',
        'Unit 3_ STATISTICS',
        'Unit 4_ INTRODUCTION TO LINEAR PROGRAMMING',
        'Unit 5_ MATHEMATICAL APPLICATIONS IN BUSINESS'
      ],
    },
  };

  static List<String> getEntranceChapters(
      String grade, String stream, String subject) {
    final key = stream.trim().toLowerCase();
    final source = key == 'social' || key == 'social_science'
        ? entranceSocialScienceChapters
        : entranceNaturalScienceChapters;
    return source[subject]?[grade.trim()] ?? const [];
  }

  // Entrance subjects are hardcoded from the GitHub repository hierarchy.
  static List<String> getEntranceSubjects(String stream) {
    final normalized = stream.trim().toLowerCase();
    return normalized == 'social' || normalized == 'social_science'
        ? const [
            'Mathematics',
            'English',
            'Aptitude',
            'Economics',
            'Geography',
            'History',
          ]
        : const [
            'Mathematics',
            'English',
            'Physics',
            'Chemistry',
            'Biology',
            'Aptitude',
          ];
  }

  static List<String> _lookupMap(Map<String, List<String>> map, String subject) {
    if (map.containsKey(subject)) return map[subject]!;
    final lower = subject.trim().toLowerCase().replaceAll('_', ' ');
    for (final entry in map.entries) {
      if (entry.key.toLowerCase().replaceAll('_', ' ') == lower) {
        return entry.value;
      }
    }
    return [];
  }

  // Get chapters for a subject
  static List<String> getChapters(String grade, String stream, String subject) {
    final gradeNum = RegExp(r'(\d+)').firstMatch(grade)?.group(1) ?? grade;
    final isSocial = stream.toLowerCase().contains('social');
    switch (gradeNum) {
      case '9':
        return _lookupMap(grade9Subjects, subject);
      case '10':
        return _lookupMap(grade10Subjects, subject);
      case '11':
        return isSocial
            ? _lookupMap(grade11SocialSubjects, subject)
            : _lookupMap(grade11NaturalSubjects, subject);
      case '12':
        return isSocial
            ? _lookupMap(grade12SocialSubjects, subject)
            : _lookupMap(grade12NaturalSubjects, subject);
      default:
        return [];
    }
  }

  // Get all subjects for a grade/stream
  static List<String> getSubjects(String grade, String? stream) {
    switch (grade) {
      case '9':
        return grade9Subjects.keys.toList();
      case '10':
        return grade10Subjects.keys.toList();
      case '11':
        return stream == 'natural'
            ? grade11NaturalSubjects.keys.toList()
            : grade11SocialSubjects.keys.toList();
      case '12':
        return stream == 'natural'
            ? grade12NaturalSubjects.keys.toList()
            : grade12SocialSubjects.keys.toList();
      default:
        return [];
    }
  }

  // Get available grades
  static List<String> get grades => ['9', '10', '11', '12'];

  // Get available streams for grade 11-12
  static List<String> get streams => ['natural', 'social'];

  // Get subjects for University Freshman
  static List<String> getUniversitySubjects(String semester, String stream,
      [String? track]) {
    if (semester == '1') {
      return stream == 'natural'
          ? freshmanNaturalSem1.keys.toList()
          : freshmanSocialSem1.keys.toList();
    } else if (semester == '2') {
      if (stream == 'social') {
        return freshmanSocialSem2.keys.toList();
      }
      return track == 'pre_engineering'
          ? freshmanPreEngSem2.keys.toList()
          : freshmanOtherNaturalSem2.keys.toList();
    }
    return [];
  }

  // Get chapters for University subjects
  static List<String> getUniversityChapters(
      String semester, String stream, String subject,
      [String? track]) {
    Map<String, List<String>> subjectsMap = {};
    if (semester == '1') {
      subjectsMap =
          stream == 'natural' ? freshmanNaturalSem1 : freshmanSocialSem1;
    } else if (semester == '2') {
      if (stream == 'social') {
        subjectsMap = freshmanSocialSem2;
      } else {
        subjectsMap = (track == 'pre_engineering' ||
                track == 'pre-engineering_courses' ||
                track == 'pre_engineering_courses')
            ? freshmanPreEngSem2
            : freshmanOtherNaturalSem2;
      }
    }
    return subjectsMap[subject] ?? [];
  }

  // ============================================================
  // Repository folder mapping
  // The curriculum above is the navigation source of truth. These mappings
  // translate display subjects/chapters into the exact GitHub folder names.
  // ============================================================

  static const Map<String, String> _sem1SubjectFolders = {
    'English I': 'english',
    'Geography': 'geography',
    'Logic': 'logic',
    'Mathematics': 'mathematics',
    'Physics': 'physics',
    'Psychology': 'psychology',
    'Economics': 'economics',
  };

  static const Map<String, String> _otherNaturalSem2SubjectFolders = {
    'Anthropology': 'Anthropology',
    'Biology': 'Biology',
    'Chemistry': 'Chemistry',
    'Economics': 'Economics',
    'Emerging Technologies': 'Emerging Technologies',
    'English II': 'English Skill II',
    'History': 'History',
    'Moral and Citizenship Education': 'Moral and Citizenship Education',
  };

  static const Map<String, String> _preEngineeringSem2SubjectFolders = {
    'Anthropology': 'Anthropology',
    'Applied Mathematics': 'Applied Mathematics',
    'C++ Programming': 'C++ Programming',
    'Emerging Technologies': 'Emerging Technologies',
    'English II': 'English Skill 2',
    'Entrepreneurship': 'Entrepreneurship',
    'History': 'History',
    'Moral and Citizenship Education': 'Moral and Citizenship Education',
  };

  static bool isPreEngineeringTrack(String? track) {
    final normalized = (track ?? '').trim().toLowerCase();
    return normalized == 'pre_engineering' ||
        normalized == 'pre-engineering' ||
        normalized == 'pre_engineering_courses' ||
        normalized == 'pre-engineering_courses';
  }

  static String normalizeUniversityStream(String? stream) {
    final normalized = (stream ?? '').trim().toLowerCase();
    if (normalized == 'social' || normalized == 'social_science') {
      return 'social_science';
    }
    return 'natural_science';
  }

  /// The repository program folder for a freshman semester, or null when the
  /// repository structure does not contain that program.
  static String? getUniversityProgramFolder(
      String semester, String stream, [String? track]) {
    if (semester == '1') {
      return normalizeUniversityStream(stream) == 'social_science'
          ? 'Social_Science'
          : 'Natural_Science';
    }
    if (semester == '2') {
      if (normalizeUniversityStream(stream) == 'social_science') return null;
      return isPreEngineeringTrack(track)
          ? 'Pre_Engineering_Courses'
          : 'Other_Natural_Science';
    }
    return null;
  }

  /// Repository folder for a subject display name.
  static String? getUniversitySubjectFolder(String subject,
      {required String semester, required String stream, String? track}) {
    if (semester == '1') return _sem1SubjectFolders[subject];
    if (semester == '2') {
      if (normalizeUniversityStream(stream) == 'social_science') return null;
      final map = isPreEngineeringTrack(track)
          ? _preEngineeringSem2SubjectFolders
          : _otherNaturalSem2SubjectFolders;
      return map[subject];
    }
    return null;
  }

  /// Repository-relative path to a freshman subject folder, e.g.
  /// University/Freshman/First_Semester/Natural_Science/english
  static String? getUniversitySubjectPath(
      {required String semester,
      required String stream,
      required String subject,
      String? track}) {
    final program = getUniversityProgramFolder(semester, stream, track);
    final subjectFolder = getUniversitySubjectFolder(subject,
        semester: semester, stream: stream, track: track);
    if (program == null || subjectFolder == null) return null;
    final semesterFolder =
        semester == '1' ? 'First_Semester' : 'Second_Semester';
    return 'University/Freshman/$semesterFolder/$program/$subjectFolder';
  }

  /// Human-readable chapter title derived from the repository folder name.
  static String displayChapterTitle(String chapterFolder) {
    final override = _chapterDisplayOverrides[chapterFolder];
    if (override != null) return override;

    final separator = chapterFolder.indexOf('_');
    if (separator <= 0) return chapterFolder;

    final prefix = chapterFolder.substring(0, separator).trim();
    final rest = chapterFolder.substring(separator + 1).trim();
    if (rest.isEmpty) return chapterFolder;

    const minorWords = {
      'a', 'an', 'and', 'as', 'at', 'but', 'by', 'for', 'from',
      'in', 'of', 'on', 'or', 'the', 'to', 'with',
    };
    final words = rest.split(RegExp(r'\s+'));
    final titled = <String>[];
    for (var i = 0; i < words.length; i++) {
      final word = words[i];
      final lower = word.toLowerCase();
      if (i > 0 && minorWords.contains(lower)) {
        titled.add(lower);
      } else {
        titled.add(lower[0].toUpperCase() + lower.substring(1));
      }
    }
    return '$prefix: ${titled.join(' ')}';
  }

  static const Map<String, String> _chapterDisplayOverrides = {
    'Chapter 3_ leaning and theories of learning':
        'Chapter 3: Learning and Theories of Learning',
    'Chapter 9_ inta-personal and interpersonal skills':
        'Chapter 9: Intra-personal and Interpersonal Skills',
    'Chapter 8_ economic activitie in Ethiopia':
        'Chapter 8: Economic Activities in Ethiopia',
  };
}