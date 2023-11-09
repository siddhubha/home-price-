import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() => runApp(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: MyHomePage(title: 'Welcome'),
      ),
    );

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<String> bhkOptions = ['1', '2', '3', '4', '5'];
  String? selectedAddress;
  List<String> addressOptions = [];

  final TextEditingController squareFeetController = TextEditingController();
  final TextEditingController bathController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: bhkOptions.length, vsync: this);
    fetchLocationNames(); // Fetch location names from API
  }

  @override
  void dispose() {
    _tabController.dispose();
    squareFeetController.dispose();
    bathController.dispose();
    super.dispose();
  }

  // Helper method to configure input restrictions
  InputDecoration getNumericInputDecoration(String labelText, Icon prefixIcon) {
    return InputDecoration(
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(
          color: Colors.green,
          width: 2,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(
          color: Colors.black,
          width: 2,
        ),
      ),
      labelText: labelText,
      prefixIcon: prefixIcon,
    );
  }

  Future<void> fetchLocationNames() async {
    final response =
        await http.get(Uri.parse('http://192.168.1.161:5000//locations'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      List<dynamic> locations = data['locations'];
      setState(() {
        addressOptions = List<String>.from(locations);
      });
    }
  }

  bool validateFields() {
    if (selectedAddress == null ||
        squareFeetController.text.isEmpty ||
        bathController.text.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Validation Error'),
          content: const Text('Please fill in all fields.'),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return false;
    }
    return true;
  }

  Future<String> fetchPredictedPrice() async {
    final response = await http.post(
      Uri.parse('http://192.168.1.161:5000//predict'),
      body: {
        'total_sqft': squareFeetController.text,
        'location': selectedAddress!,
        'bhk': _tabController.index.toString(),
        'bath': bathController.text,
      },
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['estimated_price'].toString();
    }
    return '';
  }

  void navigateToResultScreen(String predictedPrice) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ResultScreen(predictedPrice: predictedPrice),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Real Estate Price Prediction'),
        centerTitle: true,
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        child: Container(
          child: Center(
            child: Container(
              width: 300,
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    decoration: getNumericInputDecoration(
                      'Select Address',
                      const Icon(Icons.location_on),
                    ),
                    value: selectedAddress,
                    onChanged: (value) {
                      setState(() {
                        selectedAddress = value;
                      });
                    },
                    items: addressOptions
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'BHK',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TabBar(
                    controller: _tabController,
                    labelColor: Colors.black,
                    unselectedLabelColor: Colors.black,
                    indicatorColor: Colors.black,
                    indicatorWeight: 2,
                    indicator: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      color: Colors.blue,
                    ),
                    tabs:
                        bhkOptions.map((option) => Tab(text: option)).toList(),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: squareFeetController,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    keyboardType: TextInputType.number,
                    decoration: getNumericInputDecoration(
                      'Square Feet',
                      const Icon(Icons.area_chart),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: bathController,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    keyboardType: TextInputType.number,
                    decoration: getNumericInputDecoration(
                      'Bath',
                      const Icon(Icons.bathtub),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () async {
                      if (validateFields()) {
                        String predictedPrice = await fetchPredictedPrice();
                        navigateToResultScreen(predictedPrice);
                      }
                    },
                    child: const Text('Predict'),
                  ),
                  const SizedBox(height: 20), // Add extra spacing at the bottom
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ResultScreen extends StatelessWidget {
  final String predictedPrice;

  const ResultScreen({required this.predictedPrice});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prediction Result'),
        centerTitle: true,
        backgroundColor: Colors.blue,
      ),
      body: Center(
        child: Text(
          'Predicted Price in Lakhs: $predictedPrice',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
