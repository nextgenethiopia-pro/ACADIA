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
      'Chapter 6: Electromagnetism and Electronics',
      'Chapter 7: Cross Cutting Application of Physics',
    ],
    'Psychology': [
      'Chapter 1: Essence of Psychology',
      'Chapter 2: Sensation and Perception',
      'Chapter 3: Learning and Theories of Learning',
      'Chapter 4: Memory and Forgetting',
      'Chapter 5: Motivation and Emotion',
      'Chapter 6: Personality',
      'Chapter 7: Psychological Disorder and Treatment Techniques',
      'Chapter 8: Intro to Life Skills',
      'Chapter 9: Intra-personal and Interpersonal Skills',
      'Chapter 10: Academic Skills',
      'Chapter 11: Social Skills',
    ],
  };

  // University Freshman First Semester - Social Science
  static const Map<String, List<String>> freshmanSocialSem1 = {
    'Economics': [
      'Chapter 1: Basics of Economics',
      'Chapter 2: Theory of Demand and Supply',
      'Chapter 3: Theory of Customer Behaviour',
      'Chapter 4: The Theory of Production and Cost',
      'Chapter 5: Market Structure',
      'Chapter 6: Fundamental Concepts of Macroeconomics',
    ],
    'English I': [
      'Chapter 1: Study Skills',
      'Chapter 2: Health and Fitness',
      'Chapter 3: Cultural Values',
      'Chapter 4: Wild Life',
      'Chapter 5: Population',
    ],
    'Geography': [
      'Chapter 1: Introduction',
      'Chapter 2: The Geology of Ethiopia and the Horn',
      'Chapter 3: The Topography of Ethiopia and the Horn',
      'Chapter 4: Drainage System and Water Resource of Ethiopia and the Horn',
      'Chapter 5: The Climate of Ethiopia and the Horn',
      'Chapter 6: Soils, Natural Vegetation and Wildlife Resource',
      'Chapter 7: Population of Ethiopia and the Horn',
      'Chapter 8: Economic Activities in Ethiopia',
    ],
    'Logic': [
      'Chapter 1: Introduction to Philosophy',
      'Chapter 2: Basic Concept of Logic',
      'Chapter 3: Logic and Language',
      'Chapter 4: Basic Concepts of Critical Thinking',
      'Chapter 5: Informal Fallacies',
      'Chapter 6: Categorical Propositions',
    ],
    'Mathematics': [
      'Chapter 1: Function',
      'Chapter 2: Matrices and Determinant',
      'Chapter 3: Introduction to Calculus',
      'Chapter 4: Differential Equations',
    ],
    'Psychology': [
      'Chapter 1: Essence of Psychology',
      'Chapter 2: Sensation and Perception',
      'Chapter 3: Learning and Theories of Learning',
      'Chapter 4: Memory and Forgetting',
      'Chapter 5: Motivation and Emotion',
      'Chapter 6: Personality',
      'Chapter 7: Psychological Disorder and Treatment Techniques',
      'Chapter 8: Intro to Life Skills',
      'Chapter 9: Intra-personal and Interpersonal Skills',
      'Chapter 10: Academic Skills',
      'Chapter 11: Social Skills',
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

  // Get chapters for a subject
  static List<String> getChapters(String grade, String stream, String subject) {
    switch (grade) {
      case '9':
        return grade9Subjects[subject] ?? [];
      case '10':
        return grade10Subjects[subject] ?? [];
      case '11':
        return stream == 'natural'
            ? grade11NaturalSubjects[subject] ?? []
            : grade11SocialSubjects[subject] ?? [];
      case '12':
        return stream == 'natural'
            ? grade12NaturalSubjects[subject] ?? []
            : grade12SocialSubjects[subject] ?? [];
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
      return track == 'pre-engineering_courses'
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
        subjectsMap = track == 'pre-engineering_courses'
            ? freshmanPreEngSem2
            : freshmanOtherNaturalSem2;
      }
    }
    return subjectsMap[subject] ?? [];
  }
}