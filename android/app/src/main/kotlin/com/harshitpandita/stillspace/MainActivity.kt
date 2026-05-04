package com.harshitpandita.stillspace

import com.ryanheise.audioservice.AudioServiceActivity

// Extends AudioServiceActivity (required by just_audio_background) instead of
// FlutterActivity. AudioServiceActivity is itself a FlutterActivity subclass,
// so all Flutter behavior is preserved.
class MainActivity : AudioServiceActivity()
