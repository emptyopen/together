var inSyncWords = {
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
  ],
  'hard': [
    'water',
    'cat',
    'tool',
    'star',
    'lesiure',
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

incrementLevel(data) async {
  // switch case increment
  switch (data['level']) {
    case 'easy0':
      data['level'] = 'easy1';
      break;
    case 'easy1':
      data['level'] = 'easy2';
      break;
    case 'easy2':
      data['level'] = 'medium0';
      break;
    case 'medium0':
      data['level'] = 'medium1';
      break;
    case 'medium1':
      data['level'] = 'medium2';
      break;
    case 'medium2':
      data['level'] = 'hard0';
      break;
    case 'hard0':
      data['level'] = 'hard1';
      break;
    case 'hard1':
      data['level'] = 'hard2';
      break;
    case 'hard2':
      data['level'] = 'expert0';
      break;
    case 'expert0':
      data['level'] = 'expert1';
      break;
    case 'expert1':
      data['level'] = 'expert2';
      break;
    case 'expert2':
      data['state'] = 'scoreboard';
      break;
  }
}

previousLevel(data) {
  String level = 'easy0';
  switch (data['level']) {
    case 'easy1':
      level = 'easy0';
      break;
    case 'easy2':
      level = 'easy1';
      break;
    case 'medium0':
      level = 'easy2';
      break;
    case 'medium1':
      level = 'medium1';
      break;
    case 'medium2':
      level = 'medium1';
      break;
    case 'hard0':
      level = 'medium2';
      break;
    case 'hard1':
      level = 'hard0';
      break;
    case 'hard2':
      level = 'hard1';
      break;
    case 'expert0':
      level = 'hard2';
      break;
    case 'expert1':
      level = 'expert0';
      break;
    case 'expert2':
      level = 'expert1';
      break;
  }
  return level;
}

levelToNumber(data) {
  int level = 0;
  switch (data['level']) {
    case 'easy0':
      level = 1;
      break;
    case 'easy1':
      level = 2;
      break;
    case 'easy2':
      level = 3;
      break;
    case 'medium0':
      level = 4;
      break;
    case 'medium1':
      level = 5;
      break;
    case 'medium2':
      level = 6;
      break;
    case 'hard0':
      level = 7;
      break;
    case 'hard1':
      level = 8;
      break;
    case 'hard2':
      level = 9;
      break;
    case 'expert0':
      level = 10;
      break;
    case 'expert1':
      level = 11;
      break;
    case 'expert2':
      level = 12;
      break;
  }
  return level;
}

requiredScoreForLevel(level) {
  int requiredScore = 2;
  if (level.substring(level.length - 1) == '1') {
    requiredScore = 3;
  }
  if (level.substring(level.length - 1) == '2') {
    requiredScore = 4;
  }
  return requiredScore;
}

requiredScoreForPreviousLevel(level) {
  int requiredScore = 4;
  if (level.substring(level.length - 1) == '1') {
    requiredScore = 2;
  }
  if (level.substring(level.length - 1) == '2') {
    requiredScore = 3;
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