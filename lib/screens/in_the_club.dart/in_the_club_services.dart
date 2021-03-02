var samesiesWords = {
  'easy': [
    'kitchen',
    'door',
    'bathroom',
    'makeup',
    'yoga',
    'airplane',
    'cake',
    'curtains',
    'grass',
    'Christmas',
    'France',
    'Egypt',
    'Australia',
    'pencil',
    'mirror',
    'concert',
    'frozen',
    'ground',
    'dentist',
    'camera',
    'witch',
    'champagne',
    'bagel',
    'salt',
    'beach',
    'laughter',
    'underwear',
    'playground',
    'hike',
    'pocket',
    'shoes',
    'angel',
    'snail',
    'umpire',
    'donation',
    'George Washington',
    'circus',
    'Elon Musk',
    'selfie',
    'McDonald\'s',
    'Starbucks',
    'rose',
    'Halloween',
    'bus',
    'nose',
  ],
  'medium': [
    'alarm',
    'computer',
    'summer',
    'elevator',
    'fruit',
    'vegetable',
    'dessert',
    'palace',
    'garden',
    'Japan',
    'Hawaii',
    'lion',
    'cigar',
    'bank',
    'abstract',
    'houseplant',
    'flour',
    'pool',
    'bed',
    'pig',
    'garage',
    'countryside',
    'Arctic',
    'sink',
    'cabin',
    'baby',
    'sweet',
    'hand',
    'massage',
    'paranormal',
    'punch',
    'guest',
    'sleep',
    'sword',
    'escape',
    'mask',
    'alcohol',
    'sting',
    'Canada',
    'parachute',
    'village',
    'feminine',
    'masculine',
    'country music',
    'rain',
    'December',
    'ballet',
    'carbs',
    'astronaut',
    'back pain',
    'traffic ticket',
    'Gucci',
    'TV',
    'tool',
  ],
  'hard': [
    'water',
    'cat',
    'star',
    'leisure',
    'parents',
    'phone',
    'wind',
    'road',
    'universe',
    'table',
    'painting',
    'smell',
    'moon',
    'travel',
    'past',
    'crime',
    'cage',
    'calm',
    'backyard',
    'neighbor',
    'you',
    'box',
    'depths',
    'charisma',
    'warning',
    'pop',
    'storm',
    'flower',
    'fire',
    'warm',
    'gold',
    'tree',
    'hair',
    'team',
    'project',
    'Sweden',
    'boarding school',
    'fuzzy',
    'Shakespeare',
    'reality show',
    'video game',
    'Los Angeles',
    'haircut',
  ],
  'expert': [
    'self-improvement',
    'noise',
    'music',
    'art',
    'metal',
    'house',
    'light',
    'nothing',
    'card',
    'pass',
    'life',
    'cold',
    'rhetoric',
    'purple',
    'architecture',
    'body',
    'relationship',
    'small',
    'ethics',
    'go',
    'visit',
    'bag',
    'water',
    'oil',
    'theater',
    'rare',
    'product',
    'sell',
    'top',
    'city',
    'grateful',
    'mix',
    'ex',
    'track',
    'Olympics',
  ],
};

allPlayersAreReady(data) {
  bool allReady = true;
  data['playerIds'].forEach((v) {
    if (!data['ready$v']) {
      allReady = false;
    }
  });
  return allReady;
}

playerIsDoneSubmitting(playerId, data) {
  // player words are not empty
  return data['playerWords$playerId'].length >= 10;
}

List quickLevels = ['easy0', 'medium0', 'hard0', 'expert0'];
List mediumLevels = [
  'easy0',
  'easy1',
  'medium0',
  'medium1',
  'hard0',
  'hard1',
  'expert0',
  'expert1'
];
List longLevels = [
  'easy0',
  'easy1',
  'easy2',
  'medium0',
  'medium1',
  'medium2',
  'hard0',
  'hard1',
  'hard2',
  'expert0',
  'expert1',
  'expert2'
];

getLevelList(data) {
  List levelList = mediumLevels;
  switch (data['rules']['gameLength']) {
    case 'Quick':
      levelList = quickLevels;
      break;
    case 'Long':
      levelList = longLevels;
      break;
  }
  return levelList;
}

incrementLevel(data) async {
  List levelList = getLevelList(data);
  int currentLevelIndex = levelList.indexWhere((x) => x == data['level']);
  print(
      'incrementing: $currentLevelIndex || ${levelList.length - 1} || $levelList}');
  if (currentLevelIndex >= (levelList.length - 1)) {
    data['state'] = 'scoreboard';
    print('setting beatFinalLevel true');
    data['beatFinalLevel'] = true;
  } else {
    data['level'] = levelList[currentLevelIndex + 1];
  }
}

previousLevel(data) {
  List levelList = getLevelList(data);
  int currentLevelIndex = levelList.indexWhere((x) => x == data['level']);
  if (currentLevelIndex > 0) {
    return levelList[currentLevelIndex - 1];
  } else {
    return levelList[0];
  }
}

levelToNumber(data) {
  List levelList = getLevelList(data);
  int levelIndex = levelList.indexWhere((x) => x == data['level']);
  return levelIndex + 1;
}

requiredScoreForLevel(data, {previous = false}) {
  String level = data['level'] as String;
  int requiredScore = 2;
  if (level.substring(level.length - 1) == '1') {
    requiredScore = 3;
  }
  if (level.substring(level.length - 1) == '2') {
    requiredScore = 4;
  }
  if (data['rules']['difficulty'] == 'Easy') {
    requiredScore -= 1;
  }
  if (data['rules']['difficulty'] == 'Hard') {
    requiredScore += 1;
  }
  return requiredScore;
}

getSubmissionLimit(data) {
  int limit = 5;
  if (data['level'].substring(data['level'].length - 1) == '1') {
    limit = 7;
  }
  if (data['level'].substring(data['level'].length - 1) == '2') {
    limit = 9;
  }
  return limit;
}
