const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp(functions.config().firebase);

exports.addSession = functions.https.onCall((data, context) => {
    const sessions = admin.firestore().collection('sessions');
    sessions.add({
        game: data['game'],
        rules: data['rules'],
        password: data['password'],
        roomCode: data['roomCode'],
        playerIds: data['playerIds'],
        state: data['lobby']
    });
    return {result: 'OK'};
});