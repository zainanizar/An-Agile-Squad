import 'package:an_agile_squad/backend/firebase_repository.dart';
import 'package:an_agile_squad/models/client.dart';
import 'package:an_agile_squad/models/message.dart';
import 'package:an_agile_squad/utils/constants.dart';
import 'package:an_agile_squad/widgets/app_bar.dart';
import 'package:an_agile_squad/widgets/modal_tile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ChatScreen extends StatefulWidget {
  final Client receiver;

  ChatScreen({this.receiver});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  TextEditingController textFieldController = TextEditingController();
  Client sender;
  String _currentUserID;
  bool isWriting = false;
  FirebaseRepository _repository = FirebaseRepository();

  @override
  void initState() {
    super.initState();

    _repository.getCurrentUser().then((user) {
      _currentUserID = user.uid;

      setState(() {
        sender = Client(
          uid: user.uid,
          name: user.displayName,
          profilePhoto: user.photoURL,
        );
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kblackColor,
      appBar: customAppBar(context),
      body: Column(
        children: <Widget>[
          Flexible(
            child: messageList(),
          ),
          chatControls(),
        ],
      ),
    );
  }

  //displays the list of messages that the user sends
  Widget messageList() {
    return StreamBuilder(
      stream: FirebaseFirestore.instance.collection('messages').doc(_currentUserID).collection(widget.receiver.uid).orderBy("timestamp",descending: true ).snapshots(),
      builder: (context,AsyncSnapshot<QuerySnapshot> snapshot) {
        if(snapshot.data==null){
          return Center(child: CircularProgressIndicator(),);
        }
        return ListView.builder(
      padding: EdgeInsets.all(10),
      itemCount: snapshot.data.docs.length,
      itemBuilder: (context, index) {
        return chatMessageItem(snapshot.data.docs[index]);
      },
    );
      },
    );
  }

 Widget chatMessageItem(DocumentSnapshot snapshot) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 15),
      child: Container(
        //aligning the messages sent and recieved
        alignment: snapshot['senderId'] == _currentUserID
            ? Alignment.centerRight
            : Alignment.centerLeft,
        child: snapshot['senderId'] == _currentUserID
            ? senderLayout(snapshot)
            : receiverLayout(snapshot),
      ),
    );
  }

//layout of messages being sent
  Widget senderLayout(DocumentSnapshot snapshot) {
    return Container(
      margin: EdgeInsets.only(top: 12),
      constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width *
              0.65), //this ensures that any message takes up a maximum of 65% of screen width only
      decoration: kMessageDisplayDecor,
      child: Padding(
        padding: EdgeInsets.all(10),
        child: getMessage(snapshot),
      ),
    );
  }

 getMessage(DocumentSnapshot snapshot) {
    return Text(
      snapshot['message'],
      style: TextStyle(
        color: Colors.white,
        fontSize: 16.0,
      ),
    );
  }

//layout of messages being received
  Widget receiverLayout(DocumentSnapshot snapshot) {
    Radius messageRadius = Radius.circular(10);

    return Container(
      margin: EdgeInsets.only(top: 12),
      constraints:
          BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.65),
      decoration: BoxDecoration(
        color: kreceiverColor,
        borderRadius: BorderRadius.only(
          bottomRight: messageRadius,
          topRight: messageRadius,
          bottomLeft: messageRadius,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(10),
        child: getMessage(snapshot),
      ),
    );
  }

  Widget chatControls() {
    setWritingTo(bool val) {
      setState(() {
        isWriting = val;
      });
    }

//function to display media options in the bottom sheet
    addMediaModal(context) {
      showModalBottomSheet(
          context: context,
          elevation: 0,
          backgroundColor: kblackColor,
          builder: (context) {
            return Column(
              children: <Widget>[
                Container(
                  padding: EdgeInsets.symmetric(vertical: 15),
                  child: Row(
                    children: <Widget>[
                      FlatButton(
                        child: Icon(
                          Icons.close,
                        ),
                        onPressed: () => Navigator.maybePop(context),
                      ),
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "Content and tools",
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: ListView(
                    children: <Widget>[
                      ModalTile(
                        title: "Media",
                        subtitle: "Share Photos and Video",
                        icon: Icons.image,
                      ),
                      ModalTile(
                          title: "File",
                          subtitle: "Share files",
                          icon: Icons.tab),
                      ModalTile(
                          title: "Contact",
                          subtitle: "Share contacts",
                          icon: Icons.contacts),
                      ModalTile(
                          title: "Location",
                          subtitle: "Share a location",
                          icon: Icons.add_location),
                      ModalTile(
                          title: "Schedule Call",
                          subtitle: "Arrange a skype call and get reminders",
                          icon: Icons.schedule),
                      ModalTile(
                          title: "Create Poll",
                          subtitle: "Share polls",
                          icon: Icons.poll)
                    ],
                  ),
                ),
              ],
            );
          });
    }

    return Container(
      padding: EdgeInsets.all(10),
      child: Row(
        children: <Widget>[
          //to display a bottom sheet on tapping the '+' icon
          GestureDetector(
            onTap: () => addMediaModal(context),
            child: Container(
              padding: EdgeInsets.all(5),
              decoration: BoxDecoration(
                gradient: kfabGradient,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.add),
            ),
          ),
          SizedBox(
            width: 5,
          ),
          Expanded(
            child: TextField(
              controller: textFieldController,
              style: TextStyle(
                color: Colors.white,
              ),
              //to display send icon to the right of the textfield when user starts typing a message
              //makes sure that user isn't sending empty messages
              onChanged: (val) {
                (val.length > 0 &&
                        val.trim() !=
                            "") //trim function trims all blank spaces typed by the user to a blank message
                    ? setWritingTo(true)
                    : setWritingTo(false);
              },
              decoration: kTextMessageInputDecor,
            ),
          ),
          //these icons are displayed only when the user is not typing
          isWriting
              ? Container()
              : Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Icon(Icons.record_voice_over),
                ),
          isWriting ? Container() : Icon(Icons.camera_alt),

          //the send button which appears when user begins typing
          isWriting
              ? Container(
                  margin: EdgeInsets.only(left: 10),
                  decoration: BoxDecoration(
                      gradient: kfabGradient, shape: BoxShape.circle),
                  child: IconButton(
                    icon: Icon(
                      Icons.send,
                      size: 15,
                    ),
                    onPressed: () => sendMessage(),
                  ))
              : Container()
        ],
      ),
    );
  }

  sendMessage() {
    var text = textFieldController.text; //gets the text being entered

    Message _message = Message(
      receiverId: widget.receiver.uid,
      senderId: sender.uid,
      message: text,
      timestamp: FieldValue.serverTimestamp(),
      type: 'text',
    );

    setState(() {
      isWriting = false;
    });

    _repository.addMessageToDb(_message, sender, widget.receiver);
  }

  CustomAppBar customAppBar(context) {
    return CustomAppBar(
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back,
        ),
        onPressed: () {
          Navigator.pop(context);
        },
      ),
      centerTitle: false,
      title: Text(
        widget.receiver.name,
      ),
      actions: <Widget>[
        IconButton(
          icon: Icon(
            Icons.video_call,
          ),
          onPressed: () {},
        ),
        IconButton(
          icon: Icon(
            Icons.phone,
          ),
          onPressed: () {},
        )
      ],
    );
  }
}
