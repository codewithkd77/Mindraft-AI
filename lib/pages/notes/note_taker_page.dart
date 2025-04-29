import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import '../../config/theme_provider.dart';
import '../../config/api_keys.dart';
import '../../pages/note_detail_page.dart';
import 'note_generation_loading_page.dart';
import '../../pages/settings_screen.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'dart:async';
import '../../widgets/shimmer_button.dart';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class NoteTakerHome extends StatefulWidget {
  //original11
  const NoteTakerHome({super.key});

  @override
  State<NoteTakerHome> createState() => _NoteTakerHomeState();
}

class _NoteTakerHomeState extends State<NoteTakerHome> {
  final TextEditingController _topicController = TextEditingController();
  final TextEditingController _folderController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final List<Map<String, dynamic>> _notes = [];
  final List<String> _folders = ['All Notes'];
  bool _isLoading = false;
  String _currentResponse = '';
  final _prefs = SharedPreferences.getInstance();
  String _selectedFilter = 'All Notes';
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  double _generateProgress = 0.0;
  Timer? _progressTimer;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadNotes();
    _loadFolders();
  }

  Future<void> _loadFolders() async {
    final prefs = await _prefs;
    final savedFolders = prefs.getStringList('folders') ?? ['All Notes'];
    setState(() {
      _folders.clear();
      _folders.addAll(savedFolders);
    });
  }

  Future<void> _saveFolders() async {
    final prefs = await _prefs;
    await prefs.setStringList('folders', _folders);
  }

  Future<void> _loadNotes() async {
    final prefs = await _prefs;
    final savedNotes = prefs.getStringList('notes') ?? [];
    setState(() {
      _notes.clear();
      for (final note in savedNotes) {
        try {
          final parts = note.split('|');
          if (parts.length >= 3) {
            DateTime? timestamp;
            try {
              timestamp = DateTime.parse(parts[2]);
            } catch (e) {
              timestamp = DateTime.now();
            }

            _notes.add({
              'topic': parts[0],
              'content': parts[1],
              'timestamp': timestamp,
              'folder': parts.length > 3 ? parts[3] : 'All Notes',
              'source': parts.length > 4 ? parts[4] : 'text',
            });
          }
        } catch (e) {
          print('Error loading note: $e');
        }
      }

      _notes.sort((a, b) {
        final aTime = a['timestamp'] as DateTime;
        final bTime = b['timestamp'] as DateTime;
        return bTime.compareTo(aTime);
      });
    });
  }

  Future<void> _saveNotes() async {
    final prefs = await _prefs;
    final notesToSave = _notes
        .map((note) =>
            '${note['topic']}|${note['content']}|${note['timestamp'].toIso8601String()}|${note['folder']}|${note['source']}')
        .toList();
    await prefs.setStringList('notes', notesToSave);
  }

  Future<void> _generateResponse() async {
    if (_topicController.text.isEmpty) return;

    setState(() {
      _isLoading = true;
      _currentResponse = '';
      _generateProgress = 0.0; // Reset progress
    });

    // Start a timer to simulate progress
    _progressTimer = Timer.periodic(Duration(milliseconds: 300), (timer) {
      setState(() {
        // Gradually increase progress up to 90%
        if (_generateProgress < 0.9) {
          _generateProgress += 0.01;
        }
      });
    });

    try {
      final apiKey = await ApiKeys.geminiApiKey;
      final model = GenerativeModel(
        model: 'gemini-2.0-flash',
        apiKey: apiKey,
      );

      try {
        final prompt = '''
Generate clear, concise, and well-organized short notes for the topic: ${_topicController.text}

🎯 Guidelines:
1. Use short paragraphs with **clear headings**
2. Structure ALL information using:
   - Bullet points (•)
   - Numbered lists (1, 2, 3)
   - Nested indentation for sub-points
   - DO NOT use tables or grid formats
   
3. For comparisons and structured data:
   - Use bullet points with categories
   - Example:
     • Category A:
       - Point 1
       - Point 2
     • Category B:
       - Point 1
       - Point 2

4. Add **relevant emojis** to enhance readability
5. Include:
   - 📚 Definitions as bullet points
   - ✅ Advantages as a numbered list
   - ❌ Disadvantages as a numbered list
   - 💡 Examples as indented bullet points

6. please Keep language simple and informative
7. Format for easy mobile reading with clear spacing

Make the notes look like a smart summary created by a top student!
''';

        final content = [Content.text(prompt)];
        final response = await model.generateContent(content);

        // Cancel the timer and set progress to 100%
        _progressTimer?.cancel();

        setState(() {
          _generateProgress = 1.0;
          _currentResponse = response.text ?? 'No response generated';
          _notes.insert(0, {
            'topic': _topicController.text,
            'content': _currentResponse,
            'timestamp': DateTime.now(),
            'source': 'text',
          });
          _saveNotes();
          _topicController.clear();
        });

        // Give users a moment to see the 100% complete state before closing
        await Future.delayed(Duration(seconds: 1));

        // Navigate to the detail page for the newly created note
        if (context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NoteDetailPage(
                topic: _notes[0]['topic'],
                content: _notes[0]['content'],
                timestamp: _notes[0]['timestamp'],
                folder: _notes[0]['folder'] ?? 'All Notes',
              ),
            ),
          );
        }
      } catch (e) {
        _progressTimer?.cancel();
        setState(() {
          _generateProgress = 0.0;
          _currentResponse =
              'Error: $e\n\nPlease ensure you have access to the Gemini API and your API key is valid.';
        });
      }
    } catch (e) {
      _progressTimer?.cancel();
      setState(() {
        _generateProgress = 0.0;
        _currentResponse =
            'Error: $e\n\nPlease check your API key and ensure you have access to the Gemini API.';
      });
    } finally {
      _progressTimer?.cancel();
      _progressTimer = null;

      setState(() {
        _isLoading = false;
      });
    }
  }

  // Method to delete a note
  void _deleteNote(int index) {
    setState(() {
      _notes.removeAt(index);
      _saveNotes();
    });
  }

  // Add this method to the _NoteTakerHomeState class

  Future<void> _generateResponseFromImage() async {
    if (_selectedImage == null) return;

    setState(() {
      _isLoading = true;
      _currentResponse = '';
      _generateProgress = 0.0;
    });

    // Start a timer to simulate progress
    _progressTimer = Timer.periodic(Duration(milliseconds: 300), (timer) {
      setState(() {
        if (_generateProgress < 0.9) {
          _generateProgress += 0.01;
        }
      });
    });

    try {
      final apiKey = await ApiKeys.geminiApiKey;
      final model = GenerativeModel(
        model: 'gemini-2.0-flash',
        apiKey: apiKey,
      );

      try {
        // Read the image file
        final bytes = await _selectedImage!.readAsBytes();

        // Create a MimeType for the image
        String mimeType;
        if (_selectedImage!.path.toLowerCase().endsWith('.jpg') ||
            _selectedImage!.path.toLowerCase().endsWith('.jpeg')) {
          mimeType = 'image/jpeg';
        } else if (_selectedImage!.path.toLowerCase().endsWith('.png')) {
          mimeType = 'image/png';
        } else {
          mimeType = 'image/jpeg';
        }

        // Create the content with the image
        final prompt =
            '''Create concise, well-structured notes from this image. Focus on the main points and key information.

Please structure the notes with emojis for better visual organization:

1. 🎯 Main Points
   - Key information
   - Important details

2. 📝 Detailed Notes
   - Clear headings
   - Important points
   - Examples or explanations

3. 💡 Summary
   - Key takeaways
   - Final thoughts

Keep the notes concise and well-organized. Use markdown formatting and relevant emojis.''';

        final content = [
          Content.multi([
            TextPart(prompt),
            DataPart(mimeType, bytes),
          ])
        ];

        final response = await model.generateContent(content);

        _progressTimer?.cancel();

        setState(() {
          _generateProgress = 1.0;
          _currentResponse = response.text ?? 'No response generated';

          // Create a topic name
          final now = DateTime.now();
          final formattedDate = DateFormat('MMM d, h:mm a').format(now);
          final topic = _topicController.text.isNotEmpty
              ? _topicController.text
              : '📸 Image Notes - $formattedDate';

          _notes.insert(0, {
            'topic': topic,
            'content': _currentResponse,
            'timestamp': now,
            'source': 'image',
          });
          _saveNotes();
          _selectedImage = null;
        });

        // Navigate to detail page
        if (context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NoteDetailPage(
                topic: _notes[0]['topic'],
                content: _notes[0]['content'],
                timestamp: _notes[0]['timestamp'],
                folder: _selectedFilter,
              ),
            ),
          );
        }
      } catch (e) {
        _progressTimer?.cancel();
        setState(() {
          _generateProgress = 0.0;
          _currentResponse = 'Error processing image: $e';
        });
      }
    } catch (e) {
      _progressTimer?.cancel();
      setState(() {
        _generateProgress = 0.0;
        _currentResponse = 'Error: $e';
      });
    } finally {
      _progressTimer?.cancel();
      _progressTimer = null;
      setState(() {
        _isLoading = false;
        _selectedImage = null;
      });
    }
  }

  Future<void> _handlePdfUpload() async {
    try {
      // Pick PDF file
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null) {
        // Get the file
        File file = File(result.files.single.path!);

        if (result.files.single.size > 10 * 1024 * 1024) {
          // 10MB limit
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('PDF file size should be less than 10MB')),
          );
          return;
        }

        // Read PDF content
        final bytes = await file.readAsBytes();
        final PdfDocument document = PdfDocument(inputBytes: bytes);

        // Extract text from PDF
        String text = '';
        for (int i = 0; i < document.pages.count; i++) {
          PdfTextExtractor extractor = PdfTextExtractor(document);
          text += extractor.extractText(startPageIndex: i);
        }

        // Dispose the document
        document.dispose();

        // Generate note from PDF content
        setState(() {
          _isLoading = true;
          _currentResponse = '';
          _generateProgress = 0.0;
        });

        // Start progress timer
        _progressTimer = Timer.periodic(Duration(milliseconds: 300), (timer) {
          setState(() {
            if (_generateProgress < 0.9) {
              _generateProgress += 0.01;
            }
          });
        });

        try {
          final apiKey = await ApiKeys.geminiApiKey;
          final model = GenerativeModel(
            model: 'gemini-2.0-flash',
            apiKey: apiKey,
          );

          // Updated prompt to request emojis
          final prompt = '''Create concise notes from this text. 
          Please include relevant emojis for each section to make it visually appealing.
          Format the response with clear sections and bullet points.
          Text: $text''';

          final content = [Content.text(prompt)];
          final response = await model.generateContent(content);

          _progressTimer?.cancel();

          setState(() {
            _generateProgress = 1.0;
            _currentResponse = response.text ?? 'No response generated';
            _notes.insert(0, {
              'topic': '📚 PDF Notes - ${DateTime.now().toString()}',
              'content': _currentResponse,
              'timestamp': DateTime.now(),
              'source': 'pdf',
            });
            _saveNotes();
          });

          // Navigate to detail page
          if (context.mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => NoteDetailPage(
                  topic: _notes[0]['topic'],
                  content: _notes[0]['content'],
                  timestamp: _notes[0]['timestamp'],
                  folder: _selectedFilter,
                ),
              ),
            );
          }
        } catch (e) {
          _progressTimer?.cancel();
          setState(() {
            _generateProgress = 0.0;
            _currentResponse = 'Error processing PDF: $e';
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading PDF: $e')),
      );
    } finally {
      _progressTimer?.cancel();
      _progressTimer = null;
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showThemeModeSelector(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Theme Mode'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.brightness_auto),
              title: const Text('System'),
              onTap: () {
                themeProvider.setThemeMode(ThemeMode.system);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.light_mode),
              title: const Text('Light'),
              onTap: () {
                themeProvider.setThemeMode(ThemeMode.light);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.dark_mode),
              title: const Text('Dark'),
              onTap: () {
                themeProvider.setThemeMode(ThemeMode.dark);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateFolderDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Create New Folder'),
          content: TextField(
            controller: _folderController,
            decoration: const InputDecoration(
              hintText: 'Enter folder name',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (_folderController.text.isNotEmpty) {
                  setState(() {
                    _folders.add(_folderController.text);
                    _saveFolders();
                  });
                  _folderController.clear();
                  Navigator.pop(context);
                }
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }

  void _moveNoteToFolder(int noteIndex, String folder) {
    setState(() {
      _notes[noteIndex]['folder'] = folder;
      _saveNotes();
    });
  }

  void _showMoveToFolderDialog(int noteIndex) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Move to Folder'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: _folders
                  .map((folder) => ListTile(
                        title: Text(folder),
                        onTap: () {
                          _moveNoteToFolder(noteIndex, folder);
                          Navigator.pop(context);
                        },
                      ))
                  .toList(),
            ),
          ),
        );
      },
    );
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
      }
    });
  }

  List<Map<String, dynamic>> _getFilteredNotes() {
    var notes = _selectedFilter == 'All Notes'
        ? _notes
        : _notes.where((note) => note['folder'] == _selectedFilter).toList();

    if (_isSearching && _searchController.text.isNotEmpty) {
      final searchQuery = _searchController.text.toLowerCase();
      notes = notes.where((note) {
        final title = (note['topic'] ?? '').toLowerCase();
        return title.contains(searchQuery);
      }).toList();
    }

    return notes;
  }

  Future<void> _generateNotesFromYouTube(String videoUrl) async {
    if (videoUrl.isEmpty) return;

    // Validate YouTube URL
    if (!videoUrl.contains('youtube.com/watch?v=') &&
        !videoUrl.contains('youtu.be/')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid YouTube video URL'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _currentResponse = '';
      _generateProgress = 0.0;
    });

    // Start progress timer
    _progressTimer = Timer.periodic(Duration(milliseconds: 300), (timer) {
      setState(() {
        if (_generateProgress < 0.9) {
          _generateProgress += 0.01;
        }
      });
    });

    try {
      final yt = YoutubeExplode();

      // Get video information
      final video = await yt.videos.get(videoUrl);
      final videoTitle = video.title;
      final videoDescription = video.description;
      final videoDuration = video.duration?.toString() ?? 'Unknown duration';
      final videoAuthor = video.author;
      final videoThumbnail = video.thumbnails.highResUrl;

      // Close the YouTube client
      yt.close();

      // Generate notes using Gemini
      final apiKey = await ApiKeys.geminiApiKey;
      final model = GenerativeModel(
        model: 'gemini-2.0-flash',
        apiKey: apiKey,
      );

      final prompt = '''Create detailed notes from this YouTube video:

Title: $videoTitle
Author: $videoAuthor
Duration: $videoDuration
Description: $videoDescription

Please structure the notes with emojis for better visual organization:

1. 🎥 Video Overview
   - 📌 Title and author
   - 🎯 Main topic
   - 💡 Key takeaways

2. 📝 Detailed Notes
   - 📚 Clear headings and subheadings
   - ⭐ Key points and main ideas
   - 💬 Important quotes or references
   - 📋 Examples or explanations

3. 📊 Summary
   - 🔑 Main points
   - 💎 Key insights
   - 🎯 Final thoughts

Use these emojis as section markers and add relevant emojis throughout the content to make it more engaging and visually appealing.
Make sure the notes are specific to this video and its content.
Format the response with markdown for better readability.''';

      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);

      _progressTimer?.cancel();

      final responseText = response.text ?? 'No response generated';

      setState(() {
        _generateProgress = 1.0;
        _currentResponse = responseText;
        _notes.insert(0, {
          'topic': '🎥 YouTube Notes - $videoTitle',
          'content': _currentResponse,
          'timestamp': DateTime.now(),
          'source': 'youtube',
          'thumbnail': videoThumbnail,
        });
        _saveNotes();
      });

      // Navigate to detail page
      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => NoteDetailPage(
              topic: _notes[0]['topic'],
              content: _notes[0]['content'],
              timestamp: _notes[0]['timestamp'],
              folder: _selectedFilter,
              thumbnail: videoThumbnail,
            ),
          ),
        );
      }
    } catch (e) {
      _progressTimer?.cancel();
      setState(() {
        _generateProgress = 0.0;
        _currentResponse = 'Error processing YouTube video: $e';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      _progressTimer?.cancel();
      _progressTimer = null;
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showYouTubeInputDialog() {
    final TextEditingController urlController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('YouTube Video'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Enter YouTube video URL:'),
              const SizedBox(height: 16),
              TextField(
                controller: urlController,
                decoration: const InputDecoration(
                  hintText: 'https://www.youtube.com/watch?v=...',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                if (urlController.text.isNotEmpty) {
                  _generateNotesFromYouTube(urlController.text);
                }
              },
              child: const Text('Generate Notes'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode(context);

    final filteredNotes = _getFilteredNotes();

    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      if (!_isSearching) ...[
                        Expanded(
                          child: DropdownButton<String>(
                            value: _selectedFilter,
                            icon: const Icon(Icons.keyboard_arrow_down),
                            isExpanded: true,
                            underline: Container(),
                            items: _folders.map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Row(
                                  children: [
                                    const Icon(Icons.folder_outlined),
                                    const SizedBox(width: 8),
                                    Text(value),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                setState(() {
                                  _selectedFilter = newValue;
                                });
                              }
                            },
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.create_new_folder),
                          onPressed: _showCreateFolderDialog,
                        ),
                      ],
                      IconButton(
                        icon: Icon(_isSearching ? Icons.close : Icons.search),
                        onPressed: _toggleSearch,
                      ),
                      if (!_isSearching) ...[
                        IconButton(
                          icon: Icon(
                            isDarkMode ? Icons.light_mode : Icons.dark_mode,
                          ),
                          onPressed: () => _showThemeModeSelector(context),
                        ),
                        IconButton(
                          icon: const Icon(Icons.settings),
                          onPressed: () {
                            final user =
                                Supabase.instance.client.auth.currentUser;
                            if (user?.email != null) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SettingsScreen(
                                    userEmail: user!.email!,
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ],
                  ),
                ),
                if (_isSearching)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search notes...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  setState(() {
                                    _searchController.clear();
                                  });
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {});
                      },
                    ),
                  ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    'Home',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  child: filteredNotes.isEmpty
                      ? Center(
                          child: Text(
                            _isSearching && _searchController.text.isNotEmpty
                                ? 'No notes found matching "${_searchController.text}"'
                                : 'No notes in this folder. Create your first note!',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 16,
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredNotes.length,
                          itemBuilder: (context, index) {
                            final note = filteredNotes[index];
                            final timestamp = note['timestamp'] as DateTime? ??
                                DateTime.now();
                            return Card(
                              elevation: 1,
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                leading: Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: _getSourceColor(note['source']),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    _getSourceIcon(note['source']),
                                    color: Colors.white,
                                  ),
                                ),
                                title: Text(
                                  note['topic'] ?? '',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w500),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text(
                                  DateFormat('dd MMM yyyy, hh:mm a')
                                      .format(timestamp),
                                  style: const TextStyle(color: Colors.grey),
                                ),
                                trailing: PopupMenuButton<String>(
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'move',
                                      child: Text('Move to Folder'),
                                    ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Text('Delete'),
                                    ),
                                  ],
                                  onSelected: (value) {
                                    if (value == 'move') {
                                      _showMoveToFolderDialog(index);
                                    } else if (value == 'delete') {
                                      _deleteNote(index);
                                    }
                                  },
                                ),
                                onTap: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => NoteDetailPage(
                                        topic: note['topic'] ?? '',
                                        content: note['content'] ?? '',
                                        timestamp: timestamp,
                                        folder: _selectedFilter,
                                      ),
                                    ),
                                  );

                                  if (result == true) {
                                    _deleteNote(index);
                                  }
                                },
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            NoteGenerationLoadingPage(
              progress: _generateProgress,
              onCancel: () {
                setState(() {
                  _isLoading = false;
                  _progressTimer?.cancel();
                  _progressTimer = null;
                });
              },
            ),
        ],
      ),
      bottomNavigationBar: _isLoading
          ? null
          : Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ShimmerButton(
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        shape: const RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(20)),
                        ),
                        builder: (BuildContext context) {
                          return Container(
                            padding: const EdgeInsets.all(20),
                            height: MediaQuery.of(context).size.height * 0.7,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Create Note',
                                      style: TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.close),
                                      onPressed: () => Navigator.pop(context),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),

                                // Record Audio (Coming Soon)
                                ListTile(
                                  leading: Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: Colors.red[400],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.mic,
                                        color: Colors.white),
                                  ),
                                  title: const Text('Record Audio'),
                                  subtitle: const Text('Coming Soon'),
                                  trailing: const Icon(Icons.chevron_right),
                                  onTap: () {
                                    // Show coming soon message
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text('Coming Soon!')),
                                    );
                                  },
                                ),
                                const SizedBox(height: 10),

                                // Upload Audio (Coming Soon)
                                ListTile(
                                  leading: Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: Colors.blue[400],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.audio_file,
                                        color: Colors.white),
                                  ),
                                  title: const Text('Upload Audio'),
                                  subtitle: const Text('Coming Soon'),
                                  trailing: const Icon(Icons.chevron_right),
                                  onTap: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text('Coming Soon!')),
                                    );
                                  },
                                ),
                                const SizedBox(height: 10),

                                // Capture Image or Text (Implemented)
                                ListTile(
                                  leading: Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: Colors.blue[300],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.camera_alt,
                                        color: Colors.white),
                                  ),
                                  title: const Text('Capture Image or Text'),
                                  trailing: const Icon(Icons.chevron_right),
                                  onTap: () async {
                                    // Close the bottom sheet first
                                    Navigator.pop(context);

                                    // Directly open the camera
                                    final XFile? image =
                                        await _picker.pickImage(
                                      source: ImageSource.camera,
                                    );

                                    // If image was captured, generate the note
                                    if (image != null) {
                                      setState(() {
                                        _selectedImage = File(image.path);
                                        _topicController
                                            .clear(); // Clear any previous topic
                                      });

                                      // Generate note from the image directly
                                      _generateResponseFromImage();
                                    }
                                  },
                                ),
                                const SizedBox(height: 10),

                                // Upload Image (Direct image selection)
                                ListTile(
                                  leading: Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: Colors.green[400],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.image,
                                        color: Colors.white),
                                  ),
                                  title: const Text('Upload Image'),
                                  trailing: const Icon(Icons.chevron_right),
                                  onTap: () async {
                                    Navigator.pop(context);

                                    final XFile? image =
                                        await _picker.pickImage(
                                      source: ImageSource.gallery,
                                    );

                                    if (image != null) {
                                      setState(() {
                                        _selectedImage = File(image.path);
                                        _topicController.clear();
                                      });

                                      // Generate note from the image directly
                                      _generateResponseFromImage();
                                    }
                                  },
                                ),
                                const SizedBox(height: 10),

                                // YouTube Video (Coming Soon)
                                ListTile(
                                  leading: Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.play_arrow,
                                        color: Colors.white),
                                  ),
                                  title: const Text('YouTube Video'),
                                  trailing: const Icon(Icons.chevron_right),
                                  onTap: () {
                                    Navigator.pop(context);
                                    _showYouTubeInputDialog();
                                  },
                                ),
                                const SizedBox(height: 10),

                                // Copy Text (Implemented)
                                ListTile(
                                  leading: Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: Colors.deepOrange,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.content_copy,
                                        color: Colors.white),
                                  ),
                                  title: const Text('Copy Text'),
                                  trailing: const Icon(Icons.chevron_right),
                                  onTap: () {
                                    Navigator.pop(context);

                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return AlertDialog(
                                          title:
                                              const Text('New Note from Text'),
                                          content: SingleChildScrollView(
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                TextField(
                                                  controller: _topicController,
                                                  decoration:
                                                      const InputDecoration(
                                                    hintText: 'Enter a topic',
                                                  ),
                                                ),
                                                const SizedBox(height: 16),
                                              ],
                                            ),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context),
                                              child: const Text('Cancel'),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                Navigator.pop(context);
                                                if (_topicController
                                                    .text.isNotEmpty) {
                                                  _generateResponse();
                                                }
                                              },
                                              child: const Text('Generate'),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                ),
                                const SizedBox(height: 10),

                                // PDF Document
                                ListTile(
                                  leading: Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.picture_as_pdf,
                                        color: Colors.white),
                                  ),
                                  title: const Text('Upload PDF'),
                                  trailing: const Icon(Icons.chevron_right),
                                  onTap: () {
                                    Navigator.pop(context);
                                    _handlePdfUpload();
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.add, color: Colors.white),
                        const SizedBox(width: 8),
                        const Text(
                          'New Note',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    background: Colors.black,
                    shimmerColorFrom: const Color(0xFFFFAA40),
                    shimmerColorTo: const Color(0xFF9C40FF),
                    borderRadius: 30,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 16),
                  ),
                ],
              ),
            ),
    );
  }

  @override
  void dispose() {
    _topicController.dispose();
    _folderController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Color _getSourceColor(String? source) {
    switch (source) {
      case 'youtube':
        return Colors.red;
      case 'pdf':
        return Colors.red[700]!;
      case 'image':
        return Colors.blue[300]!;
      default:
        return Colors.orange;
    }
  }

  IconData _getSourceIcon(String? source) {
    switch (source) {
      case 'youtube':
        return Icons.play_arrow;
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'image':
        return Icons.image;
      default:
        return Icons.edit;
    }
  }
}
