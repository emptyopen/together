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
  ],
  'expert': [
    'self-improvement',
    'noise',
    'music',
    'art',
    'metal',
    'depths',
    'house',
    'light',
    'smell',
    'nothing',
    'card',
    'pass',
  ],
};

allPlayersAreReady(data) {
  bool allReady = true;
  data['ready'].forEach((i, v) {
    if (!v) {
      allReady = false;
    }
  });
  return allReady;
}

playerIsDoneSubmitting(playerId, data) {
  // player words are not empty
  return data['playerWords'][playerId].length >= 10;
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
  int requiredScore = 4;
  if (level.substring(level.length - 1) == '1') {
    requiredScore = 6;
  }
  if (level.substring(level.length - 1) == '2') {
    requiredScore = 8;
  }
  return requiredScore;
}

requiredScoreForPreviousLevel(level) {
  int requiredScore = 8;
  if (level.substring(level.length - 1) == '1') {
    requiredScore = 4;
  }
  if (level.substring(level.length - 1) == '2') {
    requiredScore = 6;
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
