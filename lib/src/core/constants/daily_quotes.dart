class DailyQuotes {
  static const List<String> quotes = [
    'The only way to do great work is to love what you do. - Steve Jobs',
    'Education is the most powerful weapon which you can use to change the world. - Nelson Mandela',
    'The future belongs to those who believe in the beauty of their dreams. - Eleanor Roosevelt',
    'Success is not final, failure is not fatal: it is the courage to continue that counts. - Winston Churchill',
    'The mind is everything. What you think you become. - Buddha',
    'Strive not to be a success, but rather to be of value. - Albert Einstein',
    'The best time to plant a tree was 20 years ago. The second best time is now. - Chinese Proverb',
    'Learning never exhausts the mind. - Leonardo da Vinci',
    'Education is not the filling of a pail, but the lighting of a fire. - W.B. Yeats',
    'The beautiful thing about learning is that no one can take it away from you. - B.B. King',
    'Knowledge is power. Information is liberating. Education is the premise of progress, in every society, in every family. - Kofi Annan',
    'The more that you read, the more things you will know. The more that you learn, the more places you\'ll go. - Dr. Seuss',
    'Live as if you were to die tomorrow. Learn as if you were to live forever. - Mahatma Gandhi',
    'An investment in knowledge pays the best interest. - Benjamin Franklin',
    'Education is not preparation for life; education is life itself. - John Dewey',
    'The only person who is educated is the one who has learned how to learn and change. - Carl Rogers',
    'Intellectual growth should commence at birth and cease only at death. - Albert Einstein',
    'The purpose of learning is growth, and our minds, unlike our bodies, can continue growing as we continue to live. - Mortimer Adler',
    'Education is the passport to the future, for tomorrow belongs to those who prepare for it today. - Malcolm X',
    'Learning is not attained by chance, it must be sought for with ardor and attended to with diligence. - Abigail Adams'
  ];

  static String getQuoteForDay(DateTime date) {
    // Calculate day of year to get consistent quote for same date
    int dayOfYear = date.difference(DateTime(date.year, 1, 1)).inDays;
    return quotes[dayOfYear % quotes.length];
  }

  static String getTodayQuote() {
    return getQuoteForDay(DateTime.now());
  }
}
