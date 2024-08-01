import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:mego_va/controller/data.dart';
import 'package:xml/xml.dart'; // Add this import for XML parsing

// Load environment variables

Future<String> processWithGemini(String prompt, String location,
    List<Parameter> parameters, String xmlData) async {
  // Access your API key as an environment variable
  final apiKey = dotenv.env['API_KEY'] ?? '';
  // Initialize the GenerativeModel
  final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: apiKey);

  // Parse the XML data
  final document = XmlDocument.parse(xmlData);
  final xmlContent = document.toXmlString(pretty: true);

  // Construct the content
  final content = [
    Content.text('Prompt: $prompt'),
    Content.text('Lokasi: $location'),
    Content.text(
        'Parameter Cuaca: ${parameters.map((param) => param.description).join(', ')}'),
    Content.text('XML Data: $xmlContent'),
    Content.text(
        'Kamu adalah asisten bernama Mego yang bertugas memberi tahu cuaca berdasarkan data XML cuaca dan prompt yang diberikan. Kamu akan memberikan informasi cuaca dengan baik dan jelas dalam bentuk paragraf dengan mengatakan data dari BMKG bukan XML.')
  ];

  // Generate content using the model
  final response = await model.generateContent(content);

  return response.text ?? '';
}
