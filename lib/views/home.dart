import 'package:flutter/material.dart';
import 'package:mego_va/controller/data.dart';
import 'package:mego_va/controller/gemini.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:geolocator/geolocator.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter_tts/flutter_tts.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  var textSpeech = "";
  SpeechToText speechToText = SpeechToText();
  var isListening = false;
  String location = "Mencari lokasi...";
  final ApiController apiController = ApiController();
  double? userLatitude;
  double? userLongitude;
  List<Parameter> closestAreaParameters = [];
  FlutterTts flutterTts = FlutterTts();

  void checkMic() async {
    bool micAvailable = await speechToText.initialize();

    if (micAvailable) {
      print("MicroPhone Available");
    } else {
      print("User Denied the use of speech micro");
    }
  }

  void getLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        location = "Location services are disabled.";
      });
      return;
    }

    // Check for location permissions
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          location = "Location permissions are denied.";
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        location = "Location permissions are permanently denied.";
      });
      return;
    }

    // Get the current location
    Position position = await Geolocator.getCurrentPosition();
    setState(() {
      userLatitude = position.latitude;
      userLongitude = position.longitude;
    });

    // Fetch and find the closest area
    await fetchAndFindClosestArea();
  }

  Future<void> fetchAndFindClosestArea() async {
    try {
      final areas = await apiController.fetchXmlData();
      if (userLatitude != null && userLongitude != null) {
        final closestArea =
            apiController.findClosestArea(areas, userLatitude!, userLongitude!);
        setState(() {
          location = '${closestArea.name}';
          closestAreaParameters = closestArea.parameters;
        });
      }
    } catch (e) {
      print('Error fetching or processing data: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    checkMic();
    getLocation();
    flutterTts
        .setLanguage("id-ID"); // Set the language for TTS to Bahasa Indonesia
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          alignment: Alignment.topLeft,
          child: Padding(
            padding: EdgeInsets.all(30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.location_on),
                    Text(location),
                  ],
                ),
                SizedBox(height: 10),
                Text(
                  'Ada yang bisa\nMego bantu?',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 20),
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Saran',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Icon(Icons.star, size: 16),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Terdapat peringatan dini hujan nanti sore, pastikan bawa payung, ya!',
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                AutoSizeText(
                  textSpeech,
                  style: TextStyle(fontSize: 41),
                  maxLines: 13,
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.large(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(80.0),
          side: BorderSide(color: Colors.black),
        ),
        onPressed: () async {
          if (!isListening) {
            bool micAvailable = await speechToText.initialize();

            if (micAvailable) {
              setState(() {
                isListening = true;
              });

              speechToText.listen(
                  listenFor: Duration(seconds: 20),
                  onResult: (result) async {
                    setState(() {
                      textSpeech = result.recognizedWords;
                      isListening = false;
                    });

                    print('Recognized words: $textSpeech');

                    // Process with Gemini
                    try {
                      final xmlData = await apiController
                          .fetchXmlDataAsString(); // Fetch XML data as string
                      final response = await processWithGemini(
                          textSpeech, location, closestAreaParameters, xmlData);
                      setState(() {
                        textSpeech = response;
                      });
                      print('Gemini response: $response');

                      // Speak out the response in Bahasa Indonesia
                      await flutterTts.speak(response);
                    } catch (e) {
                      print('Error processing with Gemini: $e');
                    }
                  });
            }
          } else {
            setState(() {
              isListening = false;

              speechToText.stop();
            });
          }
        },
        child: isListening ? Icon(Icons.record_voice_over) : Icon(Icons.mic),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
