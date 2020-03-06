import 'dart:async';
import 'dart:developer';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:rflutter_alert/rflutter_alert.dart';

void main() => runApp(MyApp());

//global variable
double maxDistance = 0.0006;

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Google Maps Demo',
      home: MapSample(),
    );
  }
}

class MapSample extends StatefulWidget {
  @override
  State<MapSample> createState() => MapSampleState();
}

class NewMarker {

  String title;
  LatLng location;
  bool turnon;

  NewMarker(String title, LatLng location) {
    this.title = title; this.location = location; this.turnon = true;
  }
}

class MapSampleState extends State<MapSample> {
  Completer<GoogleMapController> _controller = Completer();

  List<NewMarker> marketSetStr = new List(); 
  CameraPosition currentPosition = initPosition;
  CameraPosition userPosition = initPosition;

  // set up init update position
  Geolocator geolocator = Geolocator();
  LocationOptions locationOptions = LocationOptions(accuracy: LocationAccuracy.high, distanceFilter: 0);

  static final CameraPosition initPosition = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746,
  );

  // calculate distance between LatLng
  double newDistance(double lat1,double lon1,double lat2,double lon2) {
    return sqrt((lat2 - lat1) * (lat2 - lat1) + (lon2 - lon1) * (lon2 - lon1));
  }

  // go to position
  Future<void> _gotoPosition(Position position) async {
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(
      CameraPosition(
        target: LatLng(position.latitude, position.longitude),
        zoom: 14.4746,
      )
    ));
  }

  @override
  Widget build(BuildContext context) {
    
    // get user position and go to that position
    geolocator
        .getCurrentPosition(desiredAccuracy: LocationAccuracy.high)
        .then((Position position) {
          _gotoPosition(position);
    }).catchError((e) {
      print(e);
    });

    // center marker that show where to place marker
    Set<Marker> centerMarker = {
      Marker(
        markerId: MarkerId('centralmarker'), 
        position: currentPosition.target,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure))};

    // set up update position
    StreamSubscription<Position> positionStream = geolocator.getPositionStream(locationOptions).listen(
    (Position position) {
        
        if (position != null) userPosition = CameraPosition(target: LatLng(position.latitude, position.longitude));
        // check all marker position
        for (int i = 0; i < marketSetStr.length; i++) {
          
          NewMarker newmaker = marketSetStr[i];
          double distance = newDistance(position.latitude, position.longitude, newmaker.location.latitude, newmaker.location.longitude);
          // check if user near the marker
          if (distance < maxDistance && newmaker.turnon) {
            // set false to stop alert comming
            newmaker.turnon = false;
            // set alert with turn on, turn off or delete marker options.
            Alert(
              context: context,
              type: AlertType.error,
              title: "Alert",
              desc: newmaker.title,
              buttons: [
                DialogButton(
                  child: Text(
                    "Turn on",
                    style: TextStyle(color: Colors.white, fontSize: 20),
                  ),
                  onPressed: () {
                    setState(() {
                      newmaker.turnon = true;
                    });
                    Navigator.pop(context);
                  },
                  width: 120,
                ),
                DialogButton(
                  child: Text(
                    "Turn off",
                    style: TextStyle(color: Colors.white, fontSize: 20),
                  ),
                  onPressed: () {
                    setState(() {
                      newmaker.turnon = false;
                    });
                    Navigator.pop(context);
                  },
                  width: 120,
                ),
                DialogButton(
                  child: Text(
                    "Delete",
                    style: TextStyle(color: Colors.white, fontSize: 20),
                  ),
                  onPressed: () {
                    setState(() {
                      marketSetStr.removeAt(i);
                    });
                    Navigator.pop(context);
                  },
                  width: 120,
                )
              ],
            ).show();
          }
        }
        
    });

    return new Scaffold(
      body: GoogleMap(
        mapType: MapType.normal,
        initialCameraPosition: currentPosition,
        onMapCreated: (GoogleMapController controller) {
          _controller.complete(controller);
        },
        myLocationEnabled: true,
        onCameraMove: (CameraPosition cameraPosition) {
          setState(() {
            currentPosition = cameraPosition; // update current user location
          });
        },
        markers: marketSetStr.asMap().entries.map((MapEntry entry) {
          // create info for marker
          InfoWindow infoWindow = InfoWindow(
            title: entry.value.title,
            onTap: () {
              _pushConfigNoteScreen(entry.key);
          });
          // return new marker
          return Marker(
            markerId: MarkerId(entry.key.toString()), 
            position: entry.value.location,
            draggable: true,
            onDragEnd: (LatLng newPos) {
              entry.value.location = newPos;
            },
            infoWindow: infoWindow,
          );
        }).toSet().union(centerMarker),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _setMarker,
        label: Text('Set marker!'),
        icon: Icon(Icons.add_location),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      
    );
  }

  void _setMarker() {
    // add new marker
    setState(() {
        marketSetStr.add(
          NewMarker(
            'Enter what to do here', 
            currentPosition.target
          )
        );
    });
  }

  void changeTitle(int index, String val) {
    // change marker title
    setState(() {
      marketSetStr[index].title = val; 
    });
  }

  void _pushConfigNoteScreen(int number) {

    // Push this page onto the stack
    Navigator.of(context).push(
      // MaterialPageRoute will automatically animate the screen entry, as well
      // as adding a back button to close it
      new MaterialPageRoute(
        builder: (context) {
          return new Scaffold(
            appBar: new AppBar(
              title: new Text('Config note')
            ),
            body: Column(children: [
              new TextField(
                autofocus: true,
                onSubmitted: (val) {
                  // if empty => not change title
                  if (val.isNotEmpty) changeTitle(number,val);
                  Navigator.pop(context); // Close the add todo screen
                },
                decoration: new InputDecoration(
                  hintText: 'Enter what to do here',
                  contentPadding: const EdgeInsets.all(16.0)
                ),
              ),
              // swicher allow to turn on or off
              Row(children: [
                  new Text(
                    'Turn on this marker ?',
                  ),
                  new Switch(
                    value: marketSetStr[number].turnon,
                    onChanged: (value) {
                      marketSetStr[number].turnon = value;
                    },
                  ),
                ]
              )
          ]));
        }
      )
    );
  }
}