import 'package:an_agile_squad/backend/local%20db/repository/log_repository.dart';
import 'package:an_agile_squad/constants/constants.dart';
import 'package:an_agile_squad/constants/strings.dart';
import 'package:an_agile_squad/models/log.dart';
import 'package:an_agile_squad/utils/utilities.dart';
import 'package:an_agile_squad/widgets/chat%20widgets/cached_image.dart';
import 'package:an_agile_squad/widgets/chat%20widgets/custom_tile.dart';
import 'package:an_agile_squad/widgets/info%20providers/quiet_box.dart';
import 'package:flutter/material.dart';

class LogListContainer extends StatefulWidget {
  @override
  _LogListContainerState createState() => _LogListContainerState();
}

class _LogListContainerState extends State<LogListContainer> {
  getIcon(String callStatus) {
    Icon _icon;
    double _iconSize = 15;

//logo displayed according the category of calls - dialled, received, missed.
    switch (callStatus) {
      case kCallStatusDialled:
        _icon = Icon(
          Icons.call_made,
          size: _iconSize,
          color: Colors.green,
        );
        break;

      case kCallStatusMissed:
        _icon = Icon(
          Icons.call_missed,
          color: Colors.red,
          size: _iconSize,
        );
        break;

      default:
        _icon = Icon(
          Icons.call_received,
          size: _iconSize,
          color: Colors.grey,
        );
        break;
    }

    return Container(
      margin: EdgeInsets.only(right: 5),
      child: _icon,
    );
  }

  @override
  Widget build(BuildContext context) {
    //retrieves the information of the user/s at the other end of the call that had been missed/dialled/received and displays it
    return FutureBuilder<dynamic>(
      future: LogRepository.getLogs(),
      builder: (BuildContext context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
              child: CircularProgressIndicator(
            backgroundColor: kdarkBlueColor,
            valueColor: new AlwaysStoppedAnimation<Color>(klightBlueColor),
          ));
        }

        if (snapshot.hasData) {
          List<dynamic> logList = snapshot.data;

          if (logList.isNotEmpty) {
            return ListView.builder(
              itemCount: logList.length,
              itemBuilder: (context, i) {
                Log _log = logList[i];
                bool hasDialled = _log.callStatus == kCallStatusDialled;

                return CustomTile(
                  leading: CachedImage(
                    hasDialled ? _log.receiverPic : _log.callerPic,
                    isRound: true,
                    radius: 45,
                  ),
                  mini: false,
                  onLongPress: () => showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text("Delete this Log?"),
                      content:
                          Text("Are you sure you wish to delete this log?"),
                      actions: [
                        FlatButton(
                          child: Text("YES"),
                          onPressed: () async {  //deletes a call log and updates the state so that the changes are reflected
                            Navigator.maybePop(context);
                            await LogRepository.deleteLogs(i);
                            if (mounted) {
                              setState(() {});
                            }
                          },
                        ),
                        FlatButton(
                          child: Text("NO"),
                          onPressed: () => Navigator.maybePop(context),
                        ),
                      ],
                    ),
                  ),
                  title: Text(
                    hasDialled ? _log.receiverName : _log.callerName,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 17,
                    ),
                  ),
                  icon: getIcon(_log.callStatus),
                  subtitle: Text(
                    Utils.formatDateString(_log.timestamp),
                    style: TextStyle(
                      fontSize: 13,
                    ),
                  ),
                );
              },
            );
          }
          return QuietBox(
            "This is where all your call logs are listed",
            "Calling people all over the world with just one click!",
          );
        }

        return QuietBox(
          "This is where all your call logs are listed",
          "Calling people all over the world with just one click!",
        );
      },
    );
  }
}
