import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:holding_gesture/holding_gesture.dart';
import 'package:lottie/lottie.dart';
import '../generative_model_view_model.dart';
import '../generative_model_view_model.dart';

class VoiceAssistantView extends ConsumerStatefulWidget {
  @override
  _VoiceAssistantViewState createState() => _VoiceAssistantViewState();
}

class _VoiceAssistantViewState extends ConsumerState<VoiceAssistantView>
    with TickerProviderStateMixin {
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  String _wordsSpoken = "";
  final TextEditingController _aiResponseController = TextEditingController();

  late final AnimationController _controller =
      AnimationController(vsync: this, duration: Duration(seconds: 15));
  late final AnimationController _colorController =
      AnimationController(vsync: this, duration: Duration(seconds: 1));
  late final Animation<Color?> colorAnimation;

  bool isAnimating = false;
  String headerQuestion = 'Questions will appear here!';
  double innerCirclePadding = 0;

  @override
  void initState() {
    super.initState();
    initSpeech();
    colorAnimation =
        ColorTween(begin: Colors.deepPurple, end: Colors.purple.shade900)
            .animate(_colorController)
          ..addListener(() {
            setState(() {});
          });
  }

  void initSpeech() async {
    _speechEnabled = await _speechToText.initialize();
    setState(() {});
  }

  void _startListening() {
    setState(() {
      _speechToText.listen(onResult: _onSpeechResult);
      _wordsSpoken = "";
    });
  }

  void _stopListening() async {
    await _speechToText.stop();
    setState(() {});
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    setState(() {
      _wordsSpoken = result.recognizedWords;
    });
  }

  void _getAiResponse(String query) async {
    if (query.isEmpty) return;

    setState(() {
      _aiResponseController.text = "Fetching AI response...";
    });

    try {
      final response = await ref.read(chatProvider.notifier).sendMessage(query);
      setState(() {
        _aiResponseController.text = response;
      });
    } catch (e) {
      setState(() {
        _aiResponseController.text = "Error: $e";
      });
    }
  }

  void startAnimation() {
    if (_controller.isAnimating) {
      isAnimating = false;
      _controller.stop();
      _colorController.reverse();
    } else {
      isAnimating = true;
      _controller.forward();
      _controller.repeat();
      _colorController.forward();
    }
  }

  void resetAnimation() {
    if (_controller.isAnimating) {
      _controller.reset();
      _colorController.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _colorController.dispose();
    _aiResponseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Column(
          children: [
            Stack(
              children: [
                ClipPath(
                  clipper:
                      CustomCurvedEdge(), // Assuming you have a custom clipper
                  child: Container(
                    height: 500,
                    padding: EdgeInsets.all(0),
                    color: colorAnimation.value,
                  ),
                ),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 50.0),
                    child: Stack(
                      children: [
                        RotationTransition(
                          turns:
                              Tween(begin: 0.0, end: 1.0).animate(_controller),
                          child: DottedBorder(
                            color: Colors.white,
                            dashPattern: [5, 12],
                            strokeWidth: 12,
                            strokeCap: StrokeCap.butt,
                            borderType: BorderType.Circle,
                            child: Container(
                              width: 300,
                              height: 300,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                              ),
                              child: AnimatedPadding(
                                padding: EdgeInsets.all(innerCirclePadding),
                                duration: Duration(milliseconds: 700),
                                child: HoldTimeoutDetector(
                                  holdTimeout: Duration(seconds: 10),
                                  onTap: () {
                                    print('press');
                                    resetAnimation();
                                    innerCirclePadding = 0;
                                    headerQuestion =
                                        'Questions will appear here';
                                    setState(() {});
                                  },
                                  onTimeout: () {
                                    setState(() {
                                      print('timeout');
                                      startAnimation();
                                      headerQuestion =
                                          'Questions will appear here';
                                      innerCirclePadding = 0;
                                      _stopListening();
                                    });
                                  },
                                  onCancel: () {
                                    setState(() {
                                      print('Released');
                                      startAnimation();
                                      headerQuestion = 'Ask your Question';
                                      innerCirclePadding = 0;
                                      _stopListening();
                                    });
                                  },
                                  onTimerInitiated: () {
                                    setState(() {
                                      print('holding');
                                      resetAnimation();
                                      startAnimation();
                                      headerQuestion = 'Recording...';
                                      innerCirclePadding = 45;
                                      _startListening();
                                    });
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.deepPurple,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 95,
                          top: 95,
                          child: isAnimating
                              ? Lottie.asset(
                                  'animations/waveAnimation.json',
                                  repeat: true,
                                  fit: BoxFit.cover,
                                  width: 110,
                                  height: 100,
                                )
                              : Hero(
                                  tag: 'voice',
                                  child: Icon(
                                    Icons.mic,
                                    color: Colors.white,
                                    size: 110,
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 400.0),
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: AnimatedSwitcher(
                      duration: Duration(seconds: 2),
                      child: Text(
                        headerQuestion,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                        ),
                        key: ValueKey<String>(headerQuestion),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: AnimatedContainer(
                  duration: Duration(seconds: 3),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: _aiResponseController,
                    readOnly: true,
                    cursorColor: Colors.transparent,
                    maxLines: null,
                    decoration: InputDecoration(
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                            color: Color.fromARGB(255, 35, 77, 203),
                            width: 1.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      border: InputBorder.none,
                      labelText: 'Response',
                    ),
                    style: TextStyle(fontSize: 15),
                  ),
                ),
              ),
            ),
            Container(
              alignment: Alignment.bottomLeft,
              margin: EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: () {
                  _getAiResponse(_wordsSpoken);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color.fromARGB(255, 7, 14, 94),
                ),
                child: Text(
                  'Get  Response',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CustomCurvedEdge extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    // Add your custom clipping path logic here
    return Path();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) {
    return false;
  }
}
