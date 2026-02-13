import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';

void main() {
  runApp(const AttendanceApp());
}

class AttendanceApp extends StatelessWidget {
  const AttendanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Attendance System',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const LoginPage(),
    );
  }
}

// ============== CONFIGURATION ==============
const String API_BASE = 'https://attendance-system-backend-z1wl.onrender.com';
// ============== CONFIGURATION ==============

// ============== API SERVICE ==============
class ApiService {
  static String? _token;

  static Future<bool> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$API_BASE/api/token/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      _token = data['access'];
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', _token!);
      return true;
    }
    return false;
  }

  static Future<String?> _getToken() async {
    if (_token != null) return _token;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<List<dynamic>> getCourses() async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('$API_BASE/api/courses/'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return [];
  }

  static Future<bool> markAttendance(int courseId, double lat, double lng) async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse('$API_BASE/api/attendance/mark/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'course_id': courseId,
        'latitude': lat,
        'longitude': lng,
      }),
    );
    return response.statusCode == 200;
  }

  static Future<void> logout() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }
}
// ============== API SERVICE ==============

// ============== PAGES ==============
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    setState(() => _isLoading = true);
    
    final success = await ApiService.login(
      _usernameController.text,
      _passwordController.text,
    );
    
    setState(() => _isLoading = false);
    
    if (mounted) {
      if (success) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Login failed')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.school, size: 80, color: Colors.blue),
            const SizedBox(height: 24),
            const Text(
              'Attendance System',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Username',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _login,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Login', style: TextStyle(fontSize: 18)),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                // Demo login
                _usernameController.text = 'Gygas';
                _passwordController.text = 'ptolemy123';
              },
              child: const Text('Use demo credentials'),
            ),
          ],
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<dynamic> _courses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  Future<void> _loadCourses() async {
    final courses = await ApiService.getCourses();
    if (mounted) {
      setState(() {
        _courses = courses;
        _isLoading = false;
      });
    }
  }

  Future<void> _markAttendance(dynamic course) async {
    // Get location
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enable location services')),
      );
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    final position = await Geolocator.getCurrentPosition();
    
    final success = await ApiService.markAttendance(
      course['id'],
      position.latitude,
      position.longitude,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Attendance marked!' : 'Failed to mark attendance'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  void _logout() async {
    await ApiService.logout();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Courses'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _courses.isEmpty
              ? const Center(child: Text('No courses found'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _courses.length,
                  itemBuilder: (context, index) {
                    final course = _courses[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: const Icon(Icons.book, color: Colors.blue),
                        title: Text(course['name'] ?? course['course_name'] ?? 'Course'),
                        subtitle: Text(course['code'] ?? course['course_code'] ?? ''),
                        trailing: ElevatedButton(
                          onPressed: () => _markAttendance(course),
                          child: const Text('Mark Attendance'),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
