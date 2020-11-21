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
  return data['playerWords'][playerId] != null;
}
