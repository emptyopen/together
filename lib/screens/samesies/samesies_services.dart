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
    'fruits',
    'vegetables',
    'desserts',
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

scorePassesLevel(score, data) {
  switch (data['level']) {
    case 'easy0':
      return score > 4;
      break;
    case 'easy1':
      return score > 6;
      break;
    case 'easy2':
      return score > 8;
      break;
    case 'medium0':
      return score > 6;
      break;
    case 'medium1':
      return score > 8;
      break;
    case 'medium2':
      return score > 10;
      break;
    case 'hard0':
      return score > 6;
      break;
    case 'hard1':
      return score > 8;
      break;
    case 'hard2':
      return score > 10;
      break;
    case 'expert0':
      return score > 6;
      break;
    case 'expert1':
      return score > 8;
      break;
    case 'expert2':
      return score > 10;
      break;
  }
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
