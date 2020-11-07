import 'dart:async';

import 'package:rxdart/rxdart.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

class SpeechRecognitionService {
  final SpeechToText speech = SpeechToText();

  var errors = StreamController<SpeechRecognitionError>();
  var statuses = BehaviorSubject<String>();
  var words = StreamController<SpeechRecognitionResult>();

  var _localeId = '';

  Future<bool> initSpeech() async {
    bool hasSpeech = await speech.initialize(
      onError: errorListener,
      onStatus: statusListener,
    );

    if (hasSpeech) {
      var systemLocale = await speech.systemLocale();
      _localeId = systemLocale.localeId;
    }

    return hasSpeech;
  }

  void startListening() {
    speech.stop();
    speech.listen(
        onResult: resultListener,
        listenFor: Duration(minutes: 1),
        localeId: _localeId,
        onSoundLevelChange: null,
        cancelOnError: true,
        partialResults: true);
  }

  void errorListener(SpeechRecognitionError error) {
    errors.add(error);
  }

  void statusListener(String status) {
    statuses.add(status);
  }

  void resultListener(SpeechRecognitionResult result) {
    words.add(result);
  }

  void stopListening() {
    speech.stop();
  }

  void cancelListening() {
    speech.cancel();
  }
}
