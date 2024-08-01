// import 'package:flutter/material.dart';
// import 'package:mego_va/controller/data.dart';
// import 'package:mego_va/controller/gemini.dart'; // Add this import
// import 'package:speech_to_text/speech_to_text.dart';
// import 'package:geolocator/geolocator.dart'; // Add this import

// class MyHomePage extends StatefulWidget {
//   const MyHomePage({super.key});

//   @override
//   State<MyHomePage> createState() => _MyHomePageState();
// }

// class _MyHomePageState extends State<MyHomePage> {
//   var textSpeech = "CLICK ON MIC TO RECORD";
//   SpeechToText speechToText = SpeechToText();
//   var isListening = false;
//   String location = "Fetching location...";
//   final ApiController apiController = ApiController();
//   double? userLatitude;
//   double? userLongitude;
//   List<Parameter> closestAreaParameters = [];

//   void checkMic() async {
//     bool micAvailable = await speechToText.initialize();

//     if (micAvailable) {
//       print("MicroPhone Available");
//     } else {
//       print("User Denied the use of speech micro");
//     }
//   }

//   void getLocation() async {
//     bool serviceEnabled;
//     LocationPermission permission;

//     // Check if location services are enabled
//     serviceEnabled = await Geolocator.isLocationServiceEnabled();
//     if (!serviceEnabled) {
//       setState(() {
//         location = "Location services are disabled.";
//       });
//       return;
//     }

//     // Check for location permissions
//     permission = await Geolocator.checkPermission();
//     if (permission == LocationPermission.denied) {
//       permission = await Geolocator.requestPermission();
//       if (permission == LocationPermission.denied) {
//         setState(() {
//           location = "Location permissions are denied.";
//         });
//         return;
//       }
//     }

//     if (permission == LocationPermission.deniedForever) {
//       setState(() {
//         location = "Location permissions are permanently denied.";
//       });
//       return;
//     }

//     // Get the current location
//     Position position = await Geolocator.getCurrentPosition();
//     setState(() {
//       userLatitude = position.latitude;
//       userLongitude = position.longitude;
//     });

//     // Fetch and find the closest area
//     await fetchAndFindClosestArea();
//   }

//   Future<void> fetchAndFindClosestArea() async {
//     try {
//       final areas = await apiController.fetchXmlData();
//       if (userLatitude != null && userLongitude != null) {
//         final closestArea =
//             apiController.findClosestArea(areas, userLatitude!, userLongitude!);
//         setState(() {
//           location = 'Closest location: ${closestArea.name}';
//           closestAreaParameters = closestArea.parameters;
//         });
//       }
//     } catch (e) {
//       print('Error fetching or processing data: $e');
//     }
//   }

//   @override
//   void initState() {
//     super.initState();
//     checkMic();
//     getLocation();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Center(
//         child: SingleChildScrollView(
//           child: Column(
//             children: [
//               Text("Lokasi saat ini : "),
//               Text(location),
//               Text(textSpeech),
//               GestureDetector(
//                 onTap: () async {
//                   if (!isListening) {
//                     bool micAvailable = await speechToText.initialize();

//                     if (micAvailable) {
//                       setState(() {
//                         isListening = true;
//                       });

//                       speechToText.listen(
//                           listenFor: Duration(seconds: 20),
//                           onResult: (result) async {
//                             setState(() {
//                               textSpeech = result.recognizedWords;
//                               isListening = false;
//                             });

//                             print('Recognized words: $textSpeech');

//                             // Process with Gemini
//                             try {
//                               final xmlData = await apiController
//                                   .fetchXmlDataAsString(); // Fetch XML data as string
//                               final response = await processWithGemini(
//                                   textSpeech,
//                                   location,
//                                   closestAreaParameters,
//                                   xmlData);
//                               setState(() {
//                                 textSpeech = response;
//                               });
//                               print('Gemini response: $response');
//                             } catch (e) {
//                               print('Error processing with Gemini: $e');
//                             }
//                           });
//                     }
//                   } else {
//                     setState(() {
//                       isListening = false;

//                       speechToText.stop();
//                     });
//                   }
//                 },
//                 child: CircleAvatar(
//                   child: isListening
//                       ? Icon(Icons.record_voice_over)
//                       : Icon(Icons.mic),
//                 ),
//               )
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
