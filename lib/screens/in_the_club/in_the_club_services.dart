List inTheClubSampleQuestions = [
  'What is the most important room in the house?',
  'What is the most important part of the body?',
  'Which decade has the worst music?',
  'Which is the least important part of the body',
  'What is the ugliest fruit?',
  'Which is the most uncomfortable medical procedure?',
  'What is the most interesting color?',
  'What is the most difficult high school class?',
  'What is the spiciest word?',
  'What is the best car?',
  'Which celebrity has the biggest eyes?',
  'Which city is the easiest to live in?',
];

List inTheClubWouldYouRather = [
  [
    'Rip your pants at a wedding',
    'Run into your stalker ex on a date',
    'Accidentally kiss your boss as you turn a corner',
    'Blank on your last name when going through airport immigration'
  ],
  [
    'Win \$1,000,000',
    'Your body becomes 5 years younger',
    'You get a random house in the US state of your choice',
    'Two weeks per year you get a free vacation to Hawaii (everything free)'
  ],
  [
    'Go without your phone for a week',
    'Go without toilet paper for a week',
    'No brushing teeth for a week',
    'Eat only bread and butter for a week',
  ],
  [
    'Every time you stand up, you have to scream',
    'Every time you greet someone, you audibly fart',
    'Every time you check your phone, you have to clap three times to unlock it',
    'Every time you hug someone, you have you to apologize afterwards for being sweaty (even when you are not)'
  ],
  [
    'Eat a small tub of yogurt with ketchup mixed in',
    'Eat a steak covered in milk',
    'Drink a large cup of coffee with several raw scallops inside',
    'Eat a tiramisu that has a layer of wasabi',
  ],
];

allPlayersAreReady(data) {
  bool allReady = true;
  data['playerIds'].forEach((v) {
    if (!data['ready$v']) {
      allReady = false;
    }
  });
  return allReady;
}
