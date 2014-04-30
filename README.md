Google-Flite-TTS-iOS
====================

Google TTS / Flite TTS (Safely degrading based on network) for iOS.

If you have a network connection, and the string is short enough for Google to be happy, it will use Googles TTS engine. If that fails, it uses a built-in TTS Engine called Flite, which does not require network. It doesn't sound as good though.

How to use
====================
Include AVFoundation into your project
Drag the Classes folder into your project
Do something like this:
```
#import "TTSEngine.h"
```

```
[[TTSEngine tts] speakText:@"To use this class, include AVFoundation and the Classes folder."];
[[TTSEngine tts] speakText:@"This is Flite Speaking. Thank you for trying out this text to speech engine. It supports Google's Translate TTS via Network, but if it is unable to use the network it defaults to the Flite TTS Engine. It does not sound as good, but it is great for offline."];
[[TTSEngine tts] speakText:@"This is Google Speaking. Google has text length limits, sadly. "];
[[TTSEngine tts] speakText:@"Queued text is supported."];
```

Credits:
https://bitbucket.org/sfoster/iphone-tts/overview
https://bitbucket.org/sfoster/iphone-tts/pull-request/1/fix-for-playing-the-soundobj-without/diff
http://pastebin.com/uD5fRJPh

With some of my additions (Added queueing, singleton)
