import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'moderation_service.dart';
import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp( //initialize firebase
    options: DefaultFirebaseOptions.currentPlatform, //Set the default configuration for current platform
  );
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    // Constrain viewport to mobile dimensions (430x932) on desktop/web browsers
    builder: (context, child) {
      return Container(
        color: const Color(0xFFE5E7EB),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 430,
              maxHeight: 932,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: child,
            ),
          ),
        ),
      );
    },
    home: const ChatScreen(), // Set ChatScreen as the main screen when the app starts
  ));
}

// ----------------- Data Model -----------------
class ChatMessage {
  final String sender;
  final String text;
  final String timestamp;
  final bool isRead;

  ChatMessage({
    required this.sender,
    required this.text,
    required this.timestamp,
    required this.isRead,
  });
}


// ----------------- Frontend -----------------
// Define the ChatScreen as a StatefulWidget
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState(); //crete and => return _ChatScreenState object to manage state and UI
}

// Manages the state and UI of the ChatScreen.
class _ChatScreenState extends State<ChatScreen> { // _ private
  String currentRole = 'investor';
  final TextEditingController _controller = TextEditingController(); //TextEditingController() = controller class provided by Flutter to manage TextField or TextFormField 
  bool _isLoading = false;

  // Initializes the audio players using the audioplayers package API
  final AudioPlayer _audioPlayer = AudioPlayer();
  final AudioPlayer _bgMusicPlayer = AudioPlayer();
  bool _isMusicPlaying = false; // Default muted state so the mute icon is visible initially

  //get current time
  String _getCurrentTime() {
    final now = DateTime.now();
    final hour = now.hour.toString().padLeft(2, '0'); //If string length < 2, pad it with 0 on the left
    final minute = now.minute.toString().padLeft(2, '0');
    return "$hour:$minute"; //$ inserts variable's value into a String.
  }

  //get today date D/M/YYYY
  String _getTodayDate() {
    final now = DateTime.now();
    return "${now.day}/${now.month}/${now.year}";
  }

  // Releases the audio player resources
  @override
  void dispose() {
    _audioPlayer.dispose(); // Calls the parent class dispose method
    _bgMusicPlayer.dispose();
    _controller.dispose();
    super.dispose();
  }

  // Toggles looping background audio playback when tapping the top GIF display
  Future<void> _toggleItemMusic() async {
    try {
      if (_isMusicPlaying) {
        await _bgMusicPlayer.pause();
        setState(() {
          _isMusicPlaying = false;
        });
      } else {
        await _bgMusicPlayer.setReleaseMode(ReleaseMode.loop);
        await _bgMusicPlayer.play(AssetSource('audio/item_music.mp3'));
        setState(() {
          _isMusicPlaying = true;
        });
      }
    } catch (e) {
      debugPrint("Music Playback Error: $e");
    }
  }

  // Plays a sound effect when a message is sent successfully (Audio API).
  Future<void> _playSendSound() async {
    try {
      await _audioPlayer.play(AssetSource('audio/send.mp3')); // Wait for audio player to load and start playing the MP3 asset.
    } catch (e) {
      debugPrint("Audio Playback Error (Send): $e");
    }
  }

  // Plays a warning sound when a message is blocked by moderation (Audio API).
  Future<void> _playBlockedSound() async {
    try {
      await _audioPlayer.play(AssetSource('audio/alert.mp3'));
    } catch (e) {
      debugPrint("Audio Playback Error (Blocked): $e");
    }
  }

  // 1. Displays a custom rounded alert dialog with Visual Scale Animation & Audio feedback
  void _showBlockedDialog(String reason, String detail) {
    _playBlockedSound(); // 1. Audio Technique (Audio Player API)

    String displayReason = "Policy Violation";

    if (reason.contains("contact_info") || reason.contains("phone") || reason.contains("email")) {
      displayReason = "Contact Info Sharing";
    } else if (reason.contains("price") || reason.contains("loan") || reason.contains("negotiation")) {
      displayReason = "Private Price/Loan Terms Negotiation";
    } else if (reason.contains("off_topic")) {
      displayReason = "Off-Topic Communication";
    } else if (reason.isNotEmpty && reason != "none") {
      displayReason = reason
          .replaceAll('_', ' ')
          .replaceAll('/', ' / ')
          .split(' ')
          .map((word) => word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1)}' : '')
          .join(' ');
    }

    // 2. Visual Technique using Standard Flutter Animation API (Scale & Fade Transitions)
    showGeneralDialog(
      context: context,
      barrierDismissible: true, //clicking outside of dialog can close it
      barrierLabel: 'Dismiss message blocked dialog',
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, animation1, animation2) {
        return Container();
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        // CurvedAnimation for the visual elastic bounce effect
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.elasticOut, // Applies a bouncy elastic animation effect when reaching the target
        );

        return ScaleTransition(
          scale: curvedAnimation, // Apply a scaling animation to the dialog.
          child: FadeTransition(
            opacity: animation, // Apply a fade-in and fade-out effect to the dialog.
            child: Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
              backgroundColor: const Color(0xFFFFF9E6),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Column( //Child widgets arranged from top to bottom.
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [ //Block Text
                    const Text(
                      "Message Blocked",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFFB8860B),
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text( //Text
                      "This message violates the platform\ncommunication policy and cannot be sent.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: Color(0xFF333333),
                        height: 1.4,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      "Reason: $displayReason",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF444444),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 28),
                    ElevatedButton( //create button
                      onPressed: () => Navigator.pop(context), //close dialog
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFE599),
                        foregroundColor: const Color(0xFF2C2C2C),
                        elevation: 4,
                        shadowColor: Colors.black.withValues(alpha: 0.2),
                        shape: const StadiumBorder(),
                        padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 12),
                      ),
                      child: const Text(
                        "Got it",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

 // 3. Handles message sending and backend moderation
  Future<void> _sendMessage() async {
    String text = _controller.text.trim(); //remove whitespace
    if (text.isEmpty || _isLoading) return; //end function

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await ModerationService.checkMessage(text); //Call the checkMessage() method within the ModerationService class
      
      //mounted: true=page running, false=page closed
      //!mounted: if page is closed, end the function
      if (!mounted) return; 

      if (!result.allowed) { //message not allowed, display block dialog
        _showBlockedDialog(
          result.reason,
          result.detail?.toString() ?? '', // If result.detail has content, converted to String; if it is null, use empty string ''
        );
      } else {
        _playSendSound(); // message allowed, play send sound
        
        // Write data into database
        await FirebaseFirestore.instance.collection('messages').add({
          'text': text,
          'sender': currentRole,
          'timestamp': FieldValue.serverTimestamp(),
          'isRead': false,
        });

        _controller.clear(); //clear input text field
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error connecting to moderation backend: $e")),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) { //to construct the ChatScreen UI
    return Scaffold(  // Return a Scaffold widget to provide the basic page layout
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar( //layout: [ leading ]  [ title ]  [ actions ]
        elevation: 0, //shadow
        backgroundColor: const Color(0xFFF7F7F7),
        leading: const Icon(Icons.arrow_back_ios_new, color: Colors.black87, size: 20), 
        title: Text(
          "KAWS Figure - ${currentRole == 'borrower' ? 'Borrower' : 'Investor'}",
          style: const TextStyle(color: Color(0xFF2C2C2C), fontSize: 18, fontWeight: FontWeight.bold),
        ),
        actions: [
          // Role toggle button for dual-window testing
          IconButton(
            icon: const Icon(Icons.swap_horiz, color: Colors.black87),
            tooltip: 'Switch Role',
            onPressed: () {
              setState(() {
                currentRole = (currentRole == 'borrower') ? 'investor' : 'borrower';
              });
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top centered rotating GIF display with top-right mute badge
            // Top centered transparent rotating GIF display with top-right mute badge
            Padding(
              padding: const EdgeInsets.only(top: 4.0, bottom: 2.0),
              child: GestureDetector(
                onTap: _toggleItemMusic,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // No border or background box — pure transparent floating item
                    SizedBox(
                      width: 145, // Enlarged size (previously 110)
                      height: 145,
                      child: Image.asset(
                        'assets/images/kaws.gif',
                        fit: BoxFit.contain, // Ensures the entire figure is visible without cropping
                      ),
                    ),

                    // Top-right mute icon (shown when muted, disappears when playing)
                    if (!_isMusicPlaying)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.volume_off_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // today date
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0), //EdgeInsets: A utility class in Flutter for defining margins/spacing
              child: Text(
                _getTodayDate(),
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ),
            
            Expanded( //Fill the remaining available space in the parent Row or Column. (Safe Area-column)
              child: StreamBuilder<QuerySnapshot>( 
                //StreamBuilder: Listen to a stream ('messages' collection) and rebuild the UI whenever new data arrives.
                stream: FirebaseFirestore.instance
                    .collection('messages')
                    .orderBy('timestamp', descending: false)
                    .snapshots(), // Returns a continuous Stream of QuerySnapshot to automatically trigger UI rebuilds when Firestore data updates
                // 'snapshot': snapshot of latest data and connection state received from the Firestore stream
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        "Error loading messages: ${snapshot.error}",
                        style: const TextStyle(color: Colors.red),
                      ),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator()); //loading circle
                  }

                  //Retrieves list of DocumentSnapshots from the query snapshot
                  final docs = snapshot.data?.docs ?? []; //?? [] (Null-coalescing Operator)

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    // 1. Sets the total loop count equal to the number of Firestore documents.
                    itemCount: docs.length,
                    // 2. Flutter automatically increments 'index' (index++) internally behind the scenes, repeatedly invoking this itemBuilder callback until 'index' reaches 'itemCount'.
                    // When database update: StreamBuilder recalculates the list logic upon data updates, but Flutter's underlying Diffing algorithm reuses unchanged elements, ensuring near-zero-latency rendering.
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final data = doc.data() as Map<String, dynamic>;
                      // String key = dynamic data
                      String text = data['text'] ?? ''; // ??Null-coalescing operator: Defaults to an empty string if null
                      String sender = data['sender'] ?? '';
                      bool isRead = data['isRead'] ?? false;

                      // 1. Dynamic alignment: Check if sender matches current window's role
                      bool isMe = (sender == currentRole);

                      // 2. Automatic read receipt: If it's an incoming unread message, update Firestore
                      if (!isMe && !isRead) { //message not from me & haven't read
                        Future.microtask(() { // Schedules a microtask to update state right after the current build phase completes, avoiding build-phase errors.
                          FirebaseFirestore.instance
                              .collection('messages')
                              .doc(doc.id)
                              .update({'isRead': true});
                        });
                      }

                      // Timestamp formatting
                      Timestamp? ts = data['timestamp'] as Timestamp?;
                      String timestampStr = _getCurrentTime();
                      if (ts != null) {
                        DateTime dt = ts.toDate();
                        timestampStr =
                            "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
                      }

                      return Column(
                        crossAxisAlignment:
                            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start, //end: msg right-aligned; start: msg left-aligned
                        children: [
                          // Chat bubble container
                          Container(
                            constraints: const BoxConstraints(
                              maxWidth: 300,
                            ),
                            margin: const EdgeInsets.only(top: 8, bottom: 2),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isMe
                                  ? const Color(0xFFB5840A)
                                  : const Color(0xFFFFF3C4),
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(16),
                                topRight: const Radius.circular(16),
                                bottomLeft: Radius.circular(isMe ? 16 : 4), //message box的角的方向
                                bottomRight: Radius.circular(isMe ? 4 : 16),
                              ),
                            ),
                            child: Text(
                              text,
                              style: TextStyle(
                                color: isMe ? Colors.white : const Color(0xFF2C2C2C),
                                fontSize: 15,
                                height: 1.3,
                              ),
                            ),
                          ),

                          // Timestamp and blue double check status row
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6.0, top: 2.0),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  timestampStr,
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                                if (isMe) ...[
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.done_all,
                                    size: 16,
                                    color: isRead ? Colors.blue : Colors.grey,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
            
            // input field
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: const Color(0xFFF7F7F7),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: TextField(
                        controller: _controller,
                        onSubmitted: (_) => _sendMessage(),
                        decoration: const InputDecoration(
                          hintText: "Ask about the item...",
                          hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12), //distance between two widgets
                  GestureDetector( //Detect user gestures, such as tapping, double tapping, dragging and long pressing.
                    onTap: _isLoading ? null : _sendMessage,
                    child: Container(
                      width: 44,
                      height: 44,
                      // Define the visual decoration of the container.
                      decoration: const BoxDecoration(
                        color: Color(0xFFB5840A),
                        shape: BoxShape.circle, //send button
                      ),
                      child: _isLoading
                          ? const Padding( //if is loading, show loading circle
                              padding: EdgeInsets.all(12.0),
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Icon(Icons.arrow_forward, color: Colors.white, size: 20), //not loading, show normal button
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}