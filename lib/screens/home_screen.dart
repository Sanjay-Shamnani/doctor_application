import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:doctor_partner/constants/constants.dart';
import 'package:doctor_partner/services/api_urls.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  String patientReview;
  TextEditingController patientReviewController = TextEditingController();
  String displayTime = "00:00:00";
  var swatch = Stopwatch();
  final dur = const Duration(seconds: 1);

  decrementNQ() async {
    CollectionReference collectionReference =
        FirebaseFirestore.instance.collection(parameters);
    QuerySnapshot querySnapshot = await collectionReference.get();
    Map tempData = querySnapshot.docs[0].data();
    Map updatedData = tempData;
    updatedData['nq'] = tempData['nq'] - 1;
    querySnapshot.docs[0].reference.update(updatedData);
  }

  void startTimer() {
    Timer(dur, () {
      if (swatch.isRunning) {
        startTimer();
      }
      setState(() {
        var sec = swatch.elapsed.inSeconds % 60;
        var min = swatch.elapsed.inMinutes % 60;
        var hours = swatch.elapsed.inHours % 24;

        displayTime = hours.toString().padLeft(2, "0") +
            ":" +
            min.toString().padLeft(2, "0") +
            ":" +
            sec.toString().padLeft(2, "0");
      });
    });
  }

  showSuccessDialogBox() {
    showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('SUCCESS'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Container(
                    width: MediaQuery.of(context).size.width * 0.7,
                    child: Text("DETAILS SUBMITTED SUCCESSFULLY")),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('OKAY'),
              onPressed: () {
                patientReviewController.clear();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  convertTimeinMin(int hours, int min, int sec) {
    return (hours * 60) + min;
  }

  submitRecordedTime() {
    CollectionReference doctorCollectionReference =
        FirebaseFirestore.instance.collection(doctor);

    var timeInMin = convertTimeinMin(swatch.elapsed.inHours,
        swatch.elapsed.inMinutes, swatch.elapsed.inSeconds);

    Map<String, dynamic> consultingTimeMap = {"consultingTime": timeInMin};

    doctorCollectionReference.add(consultingTimeMap);
    showSuccessDialogBox();
  }

  sendFeedback() async {
    var timeInMin = convertTimeinMin(swatch.elapsed.inHours,
        swatch.elapsed.inMinutes, swatch.elapsed.inSeconds);

    String feedback = patientReviewController.text;

    Map<String, String> feedbackMap = {
      "duration": "$timeInMin",
      "feedback": "$feedback"
    };

    String url = ApiUrls().feedbackUrl();

    final response = await http.post(url, body: feedbackMap);

    if (response.statusCode == 200) {
      print("FeedbackSubmitted Successfully");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Partner App'),
      ),
      body: Container(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            Expanded(
              flex: 6,
              child: Container(
                alignment: Alignment.center,
                child: Text(
                  displayTime,
                  style: TextStyle(fontSize: 50, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            Expanded(
              flex: 4,
              child: Container(
                margin: EdgeInsets.only(bottom: 35),
                child: SingleChildScrollView(
                  child: Container(
                    
                    height: MediaQuery.of(context).size.height * 0.33,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Container(
                              width: MediaQuery.of(context).size.width * 0.4,
                              height: 40,
                              child: RaisedButton(
                                child: Text('START'),
                                onPressed: () {
                                  decrementNQ();
                                  swatch.start();
                                  startTimer();
                                },
                                color: Colors.green,
                              ),
                            ),
                            Container(
                              width: MediaQuery.of(context).size.width * 0.4,
                              height: 40,
                              child: RaisedButton(
                                onPressed: () {
                                  swatch.stop();
                                },
                                child: Text('STOP'),
                                color: Colors.red,
                              ),
                            )
                          ],
                        ),
                        Container(
                          child: TextField(
                            style: TextStyle(
                              fontSize: 22.5
                            ),
                            controller: patientReviewController,
                            onSubmitted: (value) {
                              setState(() {
                                patientReview = value;
                              });
                            },
                            decoration: InputDecoration(
                              labelText: "Enter Patient Feedback",
                              hintText: "Feedback",
                            ),
                          ),
                        ),
                        Container(
                          width: double.infinity,
                          height: 60,
                          child: RaisedButton(
                            onPressed: () {
                              sendFeedback();
                              submitRecordedTime();
                              swatch.reset();
                              setState(() {
                                displayTime = "00:00:00";
                              });
                            },
                            child: Text('SUBMIT'),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
