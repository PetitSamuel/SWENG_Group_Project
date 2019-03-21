import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:datetime_picker_formfield/datetime_picker_formfield.dart';
import 'SnackBarController.dart';
import 'Verification.dart';
import 'Tokens/TokenProcessor.dart';
import 'Requests.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'Register.dart';

class FormScreen extends StatefulWidget {
  final SharedPreferences prefs;
  final bool isAdmin;

  FormScreen({Key key, @required this.prefs, this.isAdmin}) : super(key: key);
  @override
  State createState() => _FormScreen(prefs, isAdmin);
}

class _FormScreen extends State<FormScreen> {
 // list of choices on the side menu, add a line here to add another option
 final List<barButtonOptions> options = <barButtonOptions>[
   // we don't use the icons as of now
  const barButtonOptions(title: 'Log Out', icon: null)
  ];
  final SharedPreferences prefs;
  final bool isAdmin;
  _FormScreen(this.prefs, this.isAdmin);  //constructor

  String _user = "";
  String _repName = "";
  String _course = "";
  String _amount = "";
  String _receipt = "";

  String accessToken = "";
  String refreshToken = "";

  //define type of date input needed, all of them are here now because I am unsure wether we need the time or not yet :)
  final formats = {
    InputType.both: DateFormat("EEEE, MMMM d, yyyy 'at' h:mma"),
    InputType.date: DateFormat('yyyy-MM-dd'),
    InputType.time: DateFormat("HH:mm"),
  };

  // let the user pick a date
  InputType inputType = InputType.date;
  DateTime _date;

  bool _radioValue = false;
  //default value for the radio button
  String _currentPaymentMethod = "cash"; 
  
  // controllers and variables for the inputs 
  final TextEditingController _userNameController = new TextEditingController();
  final TextEditingController _courseController = new TextEditingController();
  final TextEditingController _amountController = new TextEditingController();
  final TextEditingController _receiptController = new TextEditingController();
  final TextEditingController _dateController = new TextEditingController();
  final TextEditingController _repNameController = new TextEditingController();
  
  static final GlobalKey<ScaffoldState> _formKey = new GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _loadTokensAndRepName();
    if (this.isAdmin) {
      options.add(const barButtonOptions(title: 'Add new user', icon: null));
    }
  }


  @override
  Widget build(BuildContext context) {
    return new WillPopScope(
      onWillPop: () => Future.value(false),
      child: Scaffold(
        key: _formKey,
        appBar: AppBar(
          title: Text('Transaction Details'),
          automaticallyImplyLeading: false,
          actions: <Widget>[
            PopupMenuButton<barButtonOptions>(
              onSelected: _select,
              itemBuilder: (BuildContext context) {
                return options.map((barButtonOptions options) {
                  return PopupMenuItem<barButtonOptions>(
                    value: options,
                    child: Text(options.title),
                  );
                }).toList();
              },
            ),
          ],
        ),
        body: SafeArea(
            child: ListView(
              padding: EdgeInsets.symmetric(horizontal: 24.0),
              children: <Widget>[
                SizedBox(height: 12.0),
                Column(
                  children: <Widget>[
                    SizedBox(height: 30.0),
                    TextField(
                      decoration: InputDecoration(
                        labelText: "Rep Name",
                        filled: true,
                      ),
                      controller: _repNameController,
                    ),
                    SizedBox(height: 12.0),
                    TextField(
                      decoration: InputDecoration(
                        labelText: "Customer Username",
                        filled: true,
                      ),
                      controller: _userNameController,
                    ),
                    SizedBox(height: 12.0),       
                    TextField(
                      decoration: InputDecoration(
                        labelText: "Course",
                        filled: true,
                      ),
                      controller: _courseController,
                    ),
                    SizedBox(height: 12.0),
                    DateTimePickerFormField(
                      inputType: inputType,
                      format: formats[inputType],
                      editable: false,
                      controller: _dateController,
                      decoration: InputDecoration(
                        labelText: 'Date/Time', hasFloatingPlaceholder: false),
                        onChanged: (dt) => setState(() => _date = dt),
                    ),
                    SizedBox(height: 12.0),
                    Text("Payment Method: "),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        new Radio(
                          value: false,
                          groupValue: _radioValue,
                          onChanged: _handleRadioChange,
                        ),
                        new Text(
                          'Cash',
                          style: new TextStyle(fontSize: 16.0),
                        ),
                        new Radio(
                          value: true,
                          groupValue: _radioValue,
                          onChanged: _handleRadioChange,
                        ),
                        new Text(
                          'Cheque',
                          style: new TextStyle(
                            fontSize: 16.0,
                          ),
                        ),
                      ]
                    ),
                    SizedBox(height: 12.0),
                    TextField(
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: "Amount",
                        filled: true,
                        prefixText: '€',
                      ),
                      controller: _amountController,
                    ),
                    SizedBox(height: 12.0),
                    TextField(
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: "Receipt No",
                        filled: true,
                      ),
                      controller: _receiptController,
                    ),
                    ButtonBar(
                      children: <Widget>[
                        FlatButton(
                          child: Text('SUBMIT'),
                          onPressed: () async {
                            _user =_userNameController.text.trim();
                            _repName =_repNameController.text.trim();
                            _course =_courseController.text.trim();
                            _amount =_amountController.text.trim();
                            _receipt =_receiptController.text.trim();
                            double _amountValue = Verification.checkForMoneyAmountInput(_amount);
                            String printErrorMessage = Verification.validateFormSubmission(_user, _repName, _course, _amount, _amountValue, _receipt, _date);
                            if (printErrorMessage != null) {
                              SnackBarController.showSnackBarErrorMessage(_formKey, printErrorMessage);
                              return;
                            }
                            handleSubmitForm(_user, _repName, _course, _amountValue, _receipt, _date, _currentPaymentMethod);
                          },
                        )
                      ],
                    )
                  ],
                ),
              ],
            )
        )
      )
    );
  }
  void _handleRadioChange(bool value) {
    setState(() {
      _radioValue = value;
      _currentPaymentMethod = (_radioValue ? "cheque" : "cash");
    });
  }

  void handleSubmitForm(String user, String repName, String course, double amount, String receipt, DateTime date, String paymentMethod) async {
    if ((accessToken = await TokenParser.checkTokens(accessToken, refreshToken, this.prefs)) == null) {
      // an error occured with the tokens, means the user no longer has valid tokens 
      // redirect to login page
      Navigator.pop(context);
      return;
    }

    int requestId = await Requests.postForm(accessToken, user, repName, course, amount, receipt, date, paymentMethod);
    if (requestId == 0) {
      SnackBarController.showSnackBarErrorMessage(_formKey, "An error occured. Please try again later.");
      return;
    } 
    
    // success, clear the fields & show message 
    _showDialog(requestId);
    _userNameController.clear();
    _repNameController.clear();
    _courseController.clear();
    _amountController.clear();
    _receiptController.clear();
    _dateController.clear();
    setState(() => _date = null);
  }

  void _select(barButtonOptions options) {
    switch (options.title) {
      case "Log Out":
        _showLogOutDialog();
        break;
      case "Add new user":
        Navigator.push(context, new MaterialPageRoute(builder: (context) => new Register(prefs:prefs)));
        print("executed");
        break;
      default:
        // shoudln't come here
    }
  }

  void _loadTokensAndRepName() async {
    _repName = await (this.prefs.get('username') ?? '');
    refreshToken = await (this.prefs.get('refresh') ?? '');
    accessToken = await (this.prefs.get('access' ?? ''));
    setState(() {
      _repNameController.text =_repName;
    });
  }

  void _logout() async {
    // delete tokens if they are valid
    if (TokenParser.validateToken(accessToken) && ! (await Requests.deleteToken(accessToken))) {
      // if we go here, the access token is valid but the call to delete it failed (probably a backend error)
      print("access token deletion failed");
    }

    if (TokenParser.validateToken(refreshToken) && !(await Requests.deleteToken(refreshToken))) {
      // if we go here, the refresh token is valid but the call to delete it failed (probably a backend error)
      print("refresh token deletion failed");
    }

    // remove them from local storage
    await this.prefs.remove('access');
    await this.prefs.remove('refresh');
    await this.prefs.remove('is_admin');

    // pop popup message
    Navigator.of(context).pop();
    // pop form screen
    Navigator.of(context).pop();
  }

  void _showDialog(int id) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // return object of type Dialog
        return AlertDialog(
          title: new Text("Success"),
          content: new Text("The form has been sent successfully! id: $id"),
          actions: <Widget>[
            new FlatButton(
              child: new Text("Close"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

   void _showLogOutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // return object of type Dialog
        return AlertDialog(
          title: new Text("Do you want to log out ?"),
          actions: <Widget>[
            new FlatButton(
              child: new Text("Confirm"),
              onPressed: () {
                _logout();
              },
            ),
            new FlatButton(
              child: new Text("Close"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}

// class used to represent buttons
class barButtonOptions {
  const barButtonOptions({this.title, this.icon});

  final String title;
  final IconData icon;
}