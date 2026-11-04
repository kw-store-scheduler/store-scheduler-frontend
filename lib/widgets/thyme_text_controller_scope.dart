import 'package:flutter/material.dart';

/// 시트·다이얼로그 안 입력칸의 TextEditingController 를 이 위젯이 만들고 치운다.
///
/// 함수 안에서 만든 controller 를 `await showModalBottomSheet(...)` 직후 dispose 하면,
/// 입력칸에 포커스가 있는 채로 닫을 때 닫히는 애니메이션 중에 'used after being disposed' 오류가 난다.
/// 여기서는 시트가 화면에서 완전히 빠질 때(State.dispose) 치운다 (P08 매장 정보 시트와 같은 방식)
class ThymeTextControllerScope extends StatefulWidget {
  const ThymeTextControllerScope({super.key, this.text, required this.builder});

  final String? text;
  final Widget Function(BuildContext context, TextEditingController controller) builder;

  @override
  State<ThymeTextControllerScope> createState() => _ThymeTextControllerScopeState();
}

class _ThymeTextControllerScopeState extends State<ThymeTextControllerScope> {
  late final _controller = TextEditingController(text: widget.text);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _controller);
}
