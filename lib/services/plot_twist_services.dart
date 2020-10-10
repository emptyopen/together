import 'package:flutter/material.dart';

var storyBeginnings = {
  'The Elevator':
      'A sputtering noise is quickly followed by a gutteral screech, and the elevator grinds to a halt.',
  'The Mountain Lodge':
      'The hodgepodge group of hikers get stranded by a rogue blizzard. Shuffling in one by one out of the raging snowstorm, '
          'they begin to introduce themselves.',
  'The Traffic Jam':
      'It\'s another regular day in LA traffic, with nothing foreshadowing the events to come. '
          'Autonomous cars are not yet widespread, but those that have them are bored out of their minds. '
          '\n\nSeveral commuters have downloaded an app to communicate with strangers while in traffic, and they begin to filter into a random lobby.',
};

var exampleCharacters = {
  // need at least 10 * 2 ?
  'charlie': {
    'name': 'Charlie Watson',
    'age': 28,
    'description':
        'Somewhat of a crazed lunatic. Harmless, but particularly obsessed with ping pong.',
  },
  'carla': {
    'name': 'Carla Summers',
    'age': 40,
    'description':
        'A sweet Southern lady who enjoys making apple pies. Has 14 dogs and 8 cats and loves talking about them.',
  },
  'joe': {
    'name': 'Joe McCally',
    'age': 51,
    'description':
        'A hardened car mechanic from suburban Ohio. Doesn\'t go anywhere without his toolkit.',
  },
  'pyka': {
    'name': 'Pyka Northridge',
    'age': 19,
    'description':
        'Just completed her first year of college, undecided major. Very friendly party girl.',
  },
  'mike': {
    'name': 'Mike Chan',
    'age': 34,
    'description': 'Biggest passion in life is skateboarding, despite his age.'
  },
  'penelope': {
    'name': 'Penelope Cruz',
    'age': 24,
    'description':
        'A collegiate volleyball champion - and unrivaled in the ability to get wasted on a Friday evening.',
  },
  'angela': {
    'name': 'Angela Murkinson',
    'age': 31,
    'description': 'A spy from an unknown European country.',
  },
  'jim': {
    'name': 'Jim Jackson',
    'age': 53,
    'description':
        'A local bus driver, driving buses as a front for trading in international arms.',
  },
  'dexter': {
    'name': 'Dexter Bax',
    'age': 33,
    'description': 'A forensic scientist working a local case.',
  },
  'kiko': {
    'name': 'Kiko Hanayama',
    'age': 26,
    'description':
        'The relentless peace advocate. Stops at nothing to have everyone get along.',
  },
  'marcus': {
    'name': 'Marcus Kempler',
    'age': 42,
    'description':
        'Part-time barista with some digital photography on the side. Won\'t shut up about the future of automation.',
  },
  'percy': {
    'name': 'Percy Wilkins',
    'age': '47',
    'description':
        'A fourth generation butler serving the Tannor family. Gracious, and sometime a little mischievous.',
  },
  'zamari': {
    'name': 'Zamari Richards',
    'age': 28,
    'description':
        'Avid swimmer who likes to code apps on the side. Forgives, but doesn\'t forget.',
  },
  'francesca': {
    'name': 'Francesca Townsend',
    'age': 61,
    'description':
        'Moved to the US from Britain twenty years ago, and loves gardening. Dislikes drama.',
  },
  'devon': {
    'name': 'Devon Waters',
    'age': 19,
    'description':
        'Loves videogames, and dreams about what he would do in a zombie apocalpyse on a daily basis. Talks loudly.',
  },
  // '': {
  //   'name': '',
  //   'age': ,
  //   'description':,
  // },
  // '': {
  //   'name': '',
  //   'age': ,
  //   'description':,
  // },
  // '': {
  //   'name': '',
  //   'age': ,
  //   'description':,
  // },
  // '': {
  //   'name': '',
  //   'age': ,
  //   'description':,
  // },
};

getPlayerColor(player, data) {
  var colorString = data['playerColors'][player];
  return stringToColor(colorString);
}

stringToColor(colorString) {
  switch (colorString) {
    case 'green':
      return Colors.green.withAlpha(180);
      break;
    case 'blue':
      return Colors.blue.withAlpha(180);
      break;
    case 'purple':
      return Colors.purple.withAlpha(180);
      break;
    case 'orange':
      return Colors.orange.withAlpha(180);
      break;
    case 'lime':
      return Colors.lime.withAlpha(180);
      break;
    case 'pink':
      return Colors.pink.withAlpha(180);
      break;
    case 'red':
      return Colors.red.withAlpha(180);
      break;
    case 'brown':
      return Colors.brown.withAlpha(180);
      break;
    case 'cyan':
      return Colors.cyan.withAlpha(180);
      break;
    case 'teal':
      return Colors.teal.withAlpha(180);
      break;
    case 'black':
      return Colors.black.withAlpha(180);
      break;
  }
  return Colors.green[700];
}
