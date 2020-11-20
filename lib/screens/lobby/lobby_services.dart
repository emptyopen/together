joinTeam(data, teamIndex, userId, T) async {
  // remove player from current team
  data['teams'].asMap().forEach((i, v) {
    if (v['players'].contains(userId)) {
      data['teams'][i]['players'].remove(userId);
    }
  });
  // add player to team
  data['teams'][teamIndex]['players'].add(userId);

  T.transact(data);
}

claimThrone(data, userId, T) async {
  data['teams'].asMap().forEach((i, v) {
    if (v['players'].contains(userId)) {
      data['teams'][i]['players'].remove(userId);
      data['teams'][i]['players'].insert(0, userId);
    }
  });

  T.transact(data);
}

kickPlayer(data, String playerId, T) async {
  // remove playerId from session
  data['playerIds'].removeWhere((item) => item == playerId);

  // remove playerId from teams
  data['teams'].asMap().forEach((i, v) {
    if (v['players'].contains(playerId)) {
      data['teams'][i]['players'].remove(playerId);
    }
  });

  T.transact(data);
}

kickSpectator(data, String spectatorId, T) async {
  data['spectatorIds'].removeWhere((item) => item == spectatorId);

  T.transact(data);
}

List distributePlayers(data, playerIds) {
  var teams = data['teams'];

  int teamCounter = 0;
  int currLength = data['teams'][0]['players'].length;
  data['teams'].asMap().forEach((i, v) {
    if (data['teams'][i]['players'].length < currLength) {
      currLength = data['teams'][i]['players'].length;
      teamCounter = i;
    }
  });
  for (int i = 0; i < playerIds.length; i++) {
    teams[teamCounter]['players'].add(playerIds[i]);
    teamCounter++;
    if (teamCounter > data['rules']['numTeams'] - 1) {
      teamCounter = 0;
    }
  }

  return teams;
}

shuffleTeams(data, T) async {
  // get all playerIds, then distribute evenly amongst existing teams
  var playerOrder = data['playerIds'];
  playerOrder.shuffle();

  data['teams'] = [];
  for (int i = 0; i < data['rules']['numTeams']; i++) {
    data['teams'].add({'players': []});
  }

  data['teams'] = distributePlayers(data, playerOrder);

  T.transact(data);
}

addPlayer(data, playerId, T) async {
  // check if max number of players has been reached. if so, add a team
  bool isFull = false;
  if (data['rules']['maxPlayers'] != 0) {
    isFull = true;
    data['teams'].forEach((v) {
      if (v['players'].length + 1 <= data['rules']['maxTeamSize']) {
        isFull = false;
      }
    });
  }
  if (isFull) {
    print('was full, adding team');
    data['teams'].add({
      'players': [playerId]
    });
    data['rules']['numTeams'] += 1;
  } else {
    data['teams'] = distributePlayers(data, [playerId]);
  }
  data['playerIds'].add(playerId);

  T.transact(data);
}

addPlayers(data, playerIds, T) async {
  playerIds.forEach((playerId) {
    addPlayer(data, playerId, T);
  });

  T.transact(data);
}

addTheGang(data, T) {
  addPlayers(
      data,
      [
        'F3cbzZifAqWWM2eyab6x6WvdkyL2',
        'LoTLbkqfQWcFMzjrYGEne1JhN7j2',
        'h4BrcG93XgYsBcGpH7q2WySK8rd2',
        'z5SqbMUvLVb7CfSxQz4OEk9VyDE3',
        'djawU3QzVCXkLq32mlmd6W81CqK2',
      ],
      T);
}
