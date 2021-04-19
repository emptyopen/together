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
    'Get two random houses in the US state of your choice',
    'You get a free vacation to Hawaii once per year (everything free for two weeks)'
  ],
  [
    'Go without your phone for a week',
    'Go without toilet paper for a week',
    'No brushing teeth or showering for a week',
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
    'Drink a three large cups of coffee with mustard and several raw scallops',
    'Eat a large tiramisu that has a layer of wasabi',
  ],
  [
    'Find an abandoned, semi-fresh bouquet of roses on the ground',
    'Find a scarf of your favorite color on the ground',
    'Find a dog leash on the ground',
    'Find a used but functional frisbee on the ground',
  ],
  [
    'Be able to jump from the exactly the twelfth floor of a building safely',
    'Be able to clean your hairbrush with a wink',
    'You can adjust how tan you are by how hard you slap your own face',
    'As long as you are moonwalking, your neighbors can\'t see you'
  ],
  [
    'Know the name of a stranger\'s pet, once per day',
    'You get 1 cent in your bank account every 40 miles you walk',
    'There is one less cloud in the sky per day above you',
    'You can conjure the number of cars that you\'ve seen in the past week',
  ],
  [
    'Stub your toe',
    'Lose \$10 dollars from your bank account',
    'Drop the next scoop of icecream you get on the ground',
    'For one hour, no matter what you drink you still feel thirsty',
  ],
  [
    'Find out your significant other accidentally killed someone and was proven innocent',
    'Find out you live next to a serial killer',
    'Find out your only sibling was adopted and they don\'t know',
    'Find out your building was built on an old cemetery',
  ],
  [
    'Find out someone was previously killed in your bedroom',
    'Find out your car doesn\'t fit in your garage',
    'Find out your roof is leaking',
    'Find out your neighbors just got two new dogs that like to howl',
  ],
  [
    'You get a small promotion',
    'You get a free vacation to Thailand',
    'You get twelve free house cleanings',
    'Your most annoying neighbor moves out',
  ],
  [
    'The next five times you try to take a selfie with a celebrity, your battery dies',
    'An amazing restaurant opens up on your street two days before you move out of state',
    'You become allergic to your second favorite dessert for one year',
    'Loud construction starts up next door for two months'
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
