import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart';

import 'Helper/AppBtn.dart';
import 'Helper/Color.dart';
import 'Helper/Constant.dart';
import 'Helper/Session.dart';
import 'Helper/String.dart';
import 'Home.dart';
import 'Privacy_Policy.dart';
import 'Send_Otp.dart';

class Login extends StatefulWidget {
  const Login({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<Login> with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  TextEditingController mobileController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  String? countryName;
  FocusNode? passFocus, monoFocus = FocusNode();

  final GlobalKey<FormState> formkey = GlobalKey<FormState>();
  bool visible = false;
  String? password, mobile, username, email, id, mobileNo;
  bool _isNetworkAvail = true;
  Animation? buttonSqueezeAnimation;

  AnimationController? buttonController;

  @override
  void initState() {
    super.initState();
    buttonController = AnimationController(
        duration: const Duration(milliseconds: 2000), vsync: this);

    buttonSqueezeAnimation = Tween(
      begin: deviceWidth! * 0.7,
      end: 50.0,
    ).animate(CurvedAnimation(
      parent: buttonController!,
      curve: const Interval(
        0.0,
        0.150,
      ),
    ));
  }

  @override
  void dispose() {
    buttonController!.dispose();
    super.dispose();
  }

  void validateAndSubmit() async {
    if (validateAndSave()) {
      _playAnimation();
      checkNetwork();
    }
  }

  Future<void> _playAnimation() async {
    try {
      await buttonController!.forward();
    } on TickerCanceled {}
  }

  Future<void> checkNetwork() async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      getLoginUser();
    } else {
      Future.delayed(const Duration(seconds: 2)).then((_) async {
        await buttonController!.reverse();
        setState(() {
          _isNetworkAvail = false;
        });
      });
    }
  }

  Future<void> getLoginUser() async {
//////////  remove this


    var data = {MOBILE: mobile, PASSWORD: password};
    try {
      var response = await post(getUserLoginApi, body: data, headers: headers)
          .timeout(const Duration(seconds: timeOut));

      if (response.statusCode == 200) {
        var getdata = json.decode(response.body);

        bool error = getdata["error"];
        String? msg = getdata["message"];
        await buttonController!.reverse();
        if (!error) {
          setSnackBar(msg!);
          var i = getdata["data"];
          id = i[ID];
          username = i[USERNAME];
          email = i[EMAIL];
          mobile = i[MOBILE];

          CUR_USERID = id;
          CUR_USERNAME = username;

          saveUserDetail(id!, username!, email!, mobile!);
          setPrefrenceBool(isLogin, true);
          Navigator.pushReplacement(
              context,
              CupertinoPageRoute(
                builder: (context) => const Home(),
              ));
        } else {
          setSnackBar(msg!);
        }
      } else {
        await buttonController!.reverse();
      }
    } on TimeoutException catch (_) {
      await buttonController!.reverse();
      setSnackBar(somethingMSg);
    }
  }

  bool validateAndSave() {
    final form = formkey.currentState!;
    form.save();
    if (form.validate()) {
      return true;
    }
    return false;
  }

  setSnackBar(String msg) {

    ScaffoldMessenger.of(context).showSnackBar( SnackBar(
      content: Text(
        msg,
        textAlign: TextAlign.center,
        style: const TextStyle(color: fontColor),
      ),
      backgroundColor: lightWhite,
      elevation: 1.0,
    ));
  }


  @override
  Widget build(BuildContext context) {
    deviceHeight = MediaQuery.of(context).size.height;
    deviceWidth = MediaQuery.of(context).size.width;

    return Scaffold(
        key: _scaffoldKey,
        body: _isNetworkAvail
            ? Container(
                color: lightWhite,
                padding: const EdgeInsets.only(
                  bottom: 20.0,
                ),
                child: Column(
                  children: <Widget>[
                    _subLogo(),
                    _expandedBottomView(),
                  ],
                ))
            : noInternet(context));
  }

  _subLogo() {
    return Expanded(
      flex: 4,
      child: Center(
        child: Image.asset(
          'assets/images/homelogo.png',
          color: primary,
        ),
      ),
    );
  }

  _expandedBottomView() {
    return Expanded(
      flex: 6,
      child: Container(
        alignment: Alignment.bottomCenter,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Form(
            key: formkey,
            child: Card(
              elevation: 0.5,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              margin: const EdgeInsets.only(left: 20.0, right: 20.0, top: 20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  signInTxt(),
                  setMobileNo(),
                  setPass(),
                  forgetPass(),
                  loginBtn(),
                  termAndPolicyTxt(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  signInTxt() {
    return Padding(
        padding: const EdgeInsets.only(
          top: 30.0,
        ),
        child: Align(
          alignment: Alignment.center,
          child: Text(
            SIGNIN_LBL,
            style: Theme.of(context)
                .textTheme
                .subtitle1!
                .copyWith(color: fontColor, fontWeight: FontWeight.bold),
          ),
        ));
  }

  setMobileNo() {
    return Container(
      width: deviceWidth! * 0.7,
      padding: const EdgeInsets.only(
        top: 30.0,
      ),
      child: TextFormField(
        onFieldSubmitted: (v) {
          FocusScope.of(context).requestFocus(passFocus);
        },
        keyboardType: TextInputType.number,
        controller: mobileController,
        style: const TextStyle(color: fontColor, fontWeight: FontWeight.normal),
        focusNode: monoFocus,
        textInputAction: TextInputAction.next,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        validator: validateMob,
        onSaved: (String? value) {
          mobile = value;
        },
        decoration: InputDecoration(
          prefixIcon: const Icon(
            Icons.call_outlined,
            color: fontColor,
            size: 17,
          ),
          hintText: MOBILEHINT_LBL,
          hintStyle: Theme.of(context)
              .textTheme
              .subtitle2!
              .copyWith(color: fontColor, fontWeight: FontWeight.normal),
          filled: true,
          fillColor: lightWhite,
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          prefixIconConstraints: const BoxConstraints(minWidth: 40, maxHeight: 20),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: fontColor),
            borderRadius: BorderRadius.circular(7.0),
          ),
          enabledBorder: UnderlineInputBorder(
            borderSide: const BorderSide(color: lightWhite),
            borderRadius: BorderRadius.circular(7.0),
          ),
        ),
      ),
    );
  }

  setPass() {
    return Container(
        width: deviceWidth! * 0.7,
        padding: const EdgeInsets.only(top: 20.0),
        child: TextFormField(
          keyboardType: TextInputType.text,
          obscureText: true,
          focusNode: passFocus,
          style: const TextStyle(color: fontColor),
          controller: passwordController,
          validator: validatePass,
          onSaved: (String? value) {
            password = value;
          },
          decoration: InputDecoration(
            prefixIcon: const Icon(
              Icons.lock_outline,
              color: fontColor,
              size: 17,
            ),
            hintText: PASSHINT_LBL,
            hintStyle: Theme.of(context)
                .textTheme
                .subtitle2!
                .copyWith(color: fontColor, fontWeight: FontWeight.normal),
            filled: true,
            fillColor: lightWhite,
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            prefixIconConstraints: const BoxConstraints(minWidth: 40, maxHeight: 25),
            focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: fontColor),
              borderRadius: BorderRadius.circular(10.0),
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide: const BorderSide(color: lightWhite),
              borderRadius: BorderRadius.circular(10.0),
            ),
          ),
        ));
  }

  forgetPass() {
    return Padding(
        padding: const EdgeInsets.only(left: 25.0, right: 25.0, top: 10.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            InkWell(
              onTap: () {
                Navigator.push(
                    context,
                    CupertinoPageRoute(
                        builder: (context) => SendOtp(
                          title: FORGOT_PASS_TITLE,
                        )));
              },
              child: Text(FORGOT_PASSWORD_LBL,
                  style: Theme.of(context).textTheme.subtitle2!.copyWith(
                      color: fontColor, fontWeight: FontWeight.normal)),
            ),
          ],
        ));
  }

  loginBtn() {
    return AppBtn(
      title: SIGNIN_LBL,
      btnAnim: buttonSqueezeAnimation,
      btnCntrl: buttonController,
      onBtnSelected: () async {
        ////// remove this navigator here
        Navigator.pushReplacement(
            context,
            CupertinoPageRoute(
              builder: (context) => const Home(),
            ));

        // validateAndSubmit();
      },
    );
  }

  termAndPolicyTxt() {
    return Padding(
      padding:
      const EdgeInsets.only(bottom: 30.0, left: 25.0, right: 25.0, top: 10.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Text(CONTINUE_AGREE_LBL,
              style: Theme.of(context)
                  .textTheme
                  .caption!
                  .copyWith(color: fontColor, fontWeight: FontWeight.normal)),
          const SizedBox(
            height: 3.0,
          ),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            InkWell(
                onTap: () {
                  Navigator.push(
                      context,
                      CupertinoPageRoute(
                          builder: (context) => const PrivacyPolicy(
                            title: TERM,
                          )));
                },
                child: Text(
                  TERMS_SERVICE_LBL,
                  style: Theme.of(context).textTheme.caption!.copyWith(
                      color: fontColor,
                      decoration: TextDecoration.underline,
                      fontWeight: FontWeight.normal),
                )),
            const SizedBox(
              width: 5.0,
            ),
            Text(AND_LBL,
                style: Theme.of(context)
                    .textTheme
                    .caption!
                    .copyWith(color: fontColor, fontWeight: FontWeight.normal)),
            const SizedBox(
              width: 5.0,
            ),
            InkWell(
                onTap: () {
                  Navigator.push(
                      context,
                      CupertinoPageRoute(
                          builder: (context) => const PrivacyPolicy(
                            title: PRIVACY,
                          )));
                },
                child: Text(
                  PRIVACY_POLICY_LBL,
                  style: Theme.of(context).textTheme.caption!.copyWith(
                      color: fontColor,
                      decoration: TextDecoration.underline,
                      fontWeight: FontWeight.normal),
                )),
          ]),
        ],
      ),
    );
  }


  Widget noInternet(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(top: kToolbarHeight),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          noIntImage(),
          noIntText(context),
          noIntDec(context),
          AppBtn(
            title: TRY_AGAIN_INT_LBL,
            btnAnim: buttonSqueezeAnimation,
            btnCntrl: buttonController,
            onBtnSelected: () async {
              _playAnimation();

              Future.delayed(const Duration(seconds: 2)).then((_) async {
                _isNetworkAvail = await isNetworkAvailable();
                if (_isNetworkAvail) {
                  Navigator.pushReplacement(
                      context,
                      CupertinoPageRoute(
                          builder: (BuildContext context) => super.widget));
                } else {
                  await buttonController!.reverse();
                  setState(() {});
                }
              });
            },
          )
        ]),
      ),
    );
  }

}
