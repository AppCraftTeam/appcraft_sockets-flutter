import 'package:example/presentation/bloc/auth/auth_cubit.dart';
import 'package:example/presentation/bloc/login/login_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:responsive_builder/responsive_builder.dart';

class RightSideWidget extends StatefulWidget {
  final SizingInformation sizingInformation;

  const RightSideWidget({Key? key, required this.sizingInformation}) : super(key: key);

  @override
  _RightSideWidgetState createState() => _RightSideWidgetState();
}

class _RightSideWidgetState extends State<RightSideWidget> {
  late TextEditingController _nameController;

  @override
  void initState() {
    _nameController = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<LoginCubit, LoginState>(
      builder: (context, state) {
        if (state is LoginLoading) {
          return _loadingWidget();
        }
        return _bodyWidget();
      },
      listener: (context, state) {
        if (state is LoginSuccess) {
          BlocProvider.of<AuthCubit>(context).loggedIn();
        }
      },
    );
  }

  Widget _loadingWidget() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      height: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _imageWidget(),
          const SizedBox(
            height: 15,
          ),
          _fromWidget(),
          const SizedBox(
            height: 15,
          ),
          _buttonWidget(),
        ],
      ),
    );
  }

  Widget _bodyWidget() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      height: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _imageWidget(),
          const SizedBox(
            height: 15,
          ),
          _fromWidget(),
          const SizedBox(
            height: 15,
          ),
          _buttonWidget(),
        ],
      ),
    );
  }

  Widget _imageWidget() {
    return SizedBox(
      height: 60,
      width: 60,
      child: Image.asset("assets/profile.png"),
    );
  }

  Widget _fromWidget() {
    return Container(
      height: 60,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(40)),
        border: Border.all(color: Colors.grey, width: 1.0),
      ),
      child: TextField(
        controller: _nameController,
        decoration: const InputDecoration(
          border: InputBorder.none,
          hintText: "User Name",
          prefixIcon: Icon(Icons.person_outline),
        ),
      ),
    );
  }

  Widget _buttonWidget() {
    return InkWell(
      onTap: () {
        _submitLogin();
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10),
        width: widget.sizingInformation.screenSize.width,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: const BoxDecoration(
          color: Colors.indigo,
          borderRadius: BorderRadius.all(Radius.circular(50)),
        ),
        child: const Text(
          "LOGIN",
          style: TextStyle(fontSize: 18, color: Colors.white),
        ),
      ),
    );
  }

  void _submitLogin() {
    if (_nameController.text.isNotEmpty) {
      BlocProvider.of<LoginCubit>(context).submitLogin(
        login: _nameController.text,
      );
    }
  }
}
