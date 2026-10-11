import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xterm/xterm.dart';

/// What a tap on the console does about the software keyboard.
///
/// Focus is the whole of it: `CustomTextEdit` opens the platform input
/// connection from its focus listener, so a tap that takes focus has raised a
/// keyboard whether or not it meant to. That is right for a terminal you are
/// typing into and wrong for one you are reading, which is the trade
/// [TerminalView.tapToShowKeyboard] takes.
void main() {
  Future<FocusNode> tapAndFocus(
    WidgetTester tester, {
    required bool tapToShowKeyboard,
    bool mouse = false,
  }) async {
    final focus = FocusNode();
    addTearDown(focus.dispose);
    final terminal = Terminal(onOutput: (_) {});
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 800,
            height: 600,
            child: TerminalView(
              terminal,
              focusNode: focus,
              tapToShowKeyboard: tapToShowKeyboard,
            ),
          ),
        ),
      ),
    );
    // Without this the mouse report is not wanted, so what a tap writes to the
    // program is nothing either way and could not be told apart.
    if (mouse) terminal.write('\x1b[?1000h\x1b[?1006h');
    await tester.pump();
    await tester.tapAt(const Offset(400, 200));
    await tester.pump();
    return focus;
  }

  testWidgets('a tap raises the keyboard, which is the default', (tester) async {
    final focus = await tapAndFocus(tester, tapToShowKeyboard: true);
    expect(focus.hasFocus, isTrue);
  });

  testWidgets('and it does not when the tap is only a tap', (tester) async {
    expect(
      (await tapAndFocus(tester, tapToShowKeyboard: false)).hasFocus,
      isFalse,
    );
  });

  testWidgets('the tap still reaches the program either way', (tester) async {
    final out = <String>[];
    final focus = FocusNode();
    addTearDown(focus.dispose);
    final terminal = Terminal(onOutput: out.add);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 800,
            height: 600,
            child: TerminalView(
              terminal,
              focusNode: focus,
              tapToShowKeyboard: false,
            ),
          ),
        ),
      ),
    );
    terminal.write('\x1b[?1000h\x1b[?1006h');
    await tester.pump();
    out.clear();
    await tester.tapAt(const Offset(400, 200));
    await tester.pump();

    // A multiplexer whose interface is read by tapping it cannot tell a tap
    // from no tap, and that is the whole cost of not raising a keyboard.
    expect(focus.hasFocus, isFalse);
    expect(out, isNotEmpty);
    expect(out.first, startsWith('\x1B[<0;'));
  });
}
