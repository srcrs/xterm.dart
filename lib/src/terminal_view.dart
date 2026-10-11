import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:xterm/src/core/buffer/cell_offset.dart';
import 'package:xterm/src/core/buffer/range.dart';
import 'package:xterm/src/core/cursor_type.dart';
import 'package:xterm/src/core/input/keys.dart';
import 'package:xterm/src/core/mouse/button.dart';
import 'package:xterm/src/core/mouse/button_state.dart';
import 'package:xterm/src/core/mouse/mode.dart';
import 'package:xterm/src/terminal.dart';
import 'package:xterm/src/ui/controller.dart';
import 'package:xterm/src/ui/custom_text_edit.dart';
import 'package:xterm/src/ui/gesture/gesture_handler.dart';
import 'package:xterm/src/ui/input_map.dart';
import 'package:xterm/src/ui/keyboard_listener.dart';
import 'package:xterm/src/ui/render.dart';
import 'package:xterm/src/ui/scroll_handler.dart';
import 'package:xterm/src/ui/shortcut/actions.dart';
import 'package:xterm/src/ui/shortcut/shortcuts.dart';
import 'package:xterm/src/ui/terminal_text_style.dart';
import 'package:xterm/src/ui/terminal_theme.dart';
import 'package:xterm/src/ui/themes.dart';

class TerminalView extends StatefulWidget {
  const TerminalView(
    this.terminal, {
    super.key,
    this.controller,
    this.theme = TerminalThemes.defaultTheme,
    this.textStyle = const TerminalStyle(),
    this.textScaler,
    this.padding,
    this.scrollController,
    this.autoResize = true,
    this.backgroundOpacity = 1,
    this.focusNode,
    this.autofocus = false,
    this.onTapUp,
    this.onSecondaryTapDown,
    this.onSecondaryTapUp,
    this.mouseCursor = SystemMouseCursors.text,
    this.keyboardType = TextInputType.emailAddress,
    this.keyboardAppearance = Brightness.dark,
    this.cursorType = TerminalCursorType.block,
    this.cursorBlink = false,
    this.cursorBlinkInterval = const Duration(milliseconds: 530),
    this.alwaysShowCursor = false,
    this.deleteDetection = false,
    this.shortcuts,
    this.onKeyEvent,
    this.readOnly = false,
    this.hardwareKeyboardOnly = false,
    this.tapToShowKeyboard = true,
    this.simulateScroll = true,
    this.hideScrollBar = true,
    this.viewOffset = Offset.zero,
    this.showToolbar = true,
    this.enableSuggestions = true,
    this.scrollBehavior,
    this.toolbarBuilder,
    this.onCopied,
    this.onSelectAll,
    this.onPaste,
    this.rawMouseInput = false,
  });

  /// The underlying terminal that this widget renders.
  final Terminal terminal;

  final TerminalController? controller;

  /// The theme to use for this terminal.
  final TerminalTheme theme;

  /// The style to use for painting characters.
  final TerminalStyle textStyle;

  final TextScaler? textScaler;

  /// Padding around the inner [Scrollable] widget.
  final EdgeInsets? padding;

  /// Scroll controller for the inner [Scrollable] widget.
  final ScrollController? scrollController;

  /// Should this widget automatically notify the underlying terminal when its
  /// size changes. [true] by default.
  final bool autoResize;

  /// Opacity of the terminal background. Set to 0 to make the terminal
  /// background transparent.
  final double backgroundOpacity;

  /// An optional focus node to use as the focus node for this widget.
  final FocusNode? focusNode;

  /// True if this widget will be selected as the initial focus when no other
  /// node in its scope is currently focused.
  final bool autofocus;

  /// Callback for when the user taps on the terminal.
  final void Function(TapUpDetails, CellOffset)? onTapUp;

  /// Function called when the user taps on the terminal with a secondary
  /// button.
  final void Function(TapDownDetails, CellOffset)? onSecondaryTapDown;

  /// Function called when the user stops holding down a secondary button.
  final void Function(TapUpDetails, CellOffset)? onSecondaryTapUp;

  /// The mouse cursor for mouse pointers that are hovering over the terminal.
  /// [SystemMouseCursors.text] by default.
  final MouseCursor mouseCursor;

  /// The type of information for which to optimize the text input control.
  /// [TextInputType.emailAddress] by default.
  final TextInputType keyboardType;

  /// The appearance of the keyboard. [Brightness.dark] by default.
  ///
  /// This setting is only honored on iOS devices.
  final Brightness keyboardAppearance;

  /// The type of cursor to use. [TerminalCursorType.block] by default.
  final TerminalCursorType cursorType;

  /// Whether the cursor should blink. [false] by default to match legacy behavior.
  final bool cursorBlink;

  /// Interval used when [cursorBlink] is enabled.
  final Duration cursorBlinkInterval;

  /// Whether to always show the cursor. This is useful for debugging.
  /// [false] by default.
  final bool alwaysShowCursor;

  /// Workaround to detect delete key for platforms and IMEs that does not
  /// emit hardware delete event. Prefered on mobile platforms. [false] by
  /// default.
  final bool deleteDetection;

  /// Send pointer presses straight to the terminal, outside the gesture arena.
  ///
  /// A TUI that draws its own tabs, panes and menus is read by tapping them,
  /// and a tap has to arrive as a mouse report for that to work. The default
  /// path asks the gesture arena first and only then reports, so a tap can be
  /// consumed as a selection, a scale gesture or a long press and never reach
  /// the program at all — which reads, on a multiplexer, as "the interface is
  /// not clickable". [Terminal.mouseInput] stays the single place the report is
  /// built; this only decides who asks it and when.
  ///
  /// Off by default: with it on, selection by tap and drag stops working, which
  /// is the right trade for a full-screen application and the wrong one for an
  /// ordinary shell.
  final bool rawMouseInput;

  /// Shortcuts for this terminal. This has higher priority than input handler
  /// of the terminal If not provided, [defaultTerminalShortcuts] will be used.
  final Map<ShortcutActivator, Intent>? shortcuts;

  /// Keyboard event handler of the terminal. This has higher priority than
  /// [shortcuts] and input handler of the terminal.
  final FocusOnKeyEventCallback? onKeyEvent;

  /// True if no input should send to the terminal.
  final bool readOnly;

  /// True if only hardware keyboard events should be used as input. This will
  /// also prevent any on-screen keyboard to be shown.
  final bool hardwareKeyboardOnly;

  /// Whether a tap on the terminal brings up the software keyboard.
  ///
  /// On by default, which is what a terminal is: you tap it and type. Off,
  /// the tap is only a tap — it still reports to the program, still selects,
  /// still copies — and the only way to raise a keyboard is something that
  /// looks like an input. Reading output is the other half of what a terminal
  /// is for, and a keyboard over half the screen on every touch is the one
  /// thing in the way of reading it.
  ///
  /// Not [hardwareKeyboardOnly]: the text input connection is left alone, so
  /// this only decides who asks for the keyboard. There has to be something
  /// else to ask — a composer of the terminal's own — or the keyboard simply
  /// never comes up at all.
  final bool tapToShowKeyboard;

  /// If true, when the terminal is in alternate buffer (for example running
  /// vim, man, etc), if the application does not declare that it can handle
  /// scrolling, the terminal will simulate scrolling by sending up/down arrow
  /// keys to the application. This is standard behavior for most terminal
  /// emulators. True by default.
  final bool simulateScroll;

  final bool hideScrollBar;

  final Offset viewOffset;

  final bool showToolbar;

  /// If this is false, some Chinese Android will open safe keyboard.
  final bool enableSuggestions;

  /// Allows customizing the scroll behavior used by the terminal viewport.
  final ScrollBehavior? scrollBehavior;

  /// Optional builder to customize selection toolbar items shown by the input bridge.
  final CustomTextEditToolbarBuilder? toolbarBuilder;

  /// Callback to show toast after copy operation.
  final void Function()? onCopied;

  /// Callback to select all text in the terminal.
  final void Function()? onSelectAll;

  /// Callback to paste text from clipboard to terminal.
  final void Function()? onPaste;

  @override
  State<TerminalView> createState() => TerminalViewState();
}

class TerminalViewState extends State<TerminalView>
    with TickerProviderStateMixin {
  var _prevIsAltBuffer = false;
  var _prevMouseMode = MouseMode.none;

  late FocusNode _focusNode;

  late final ShortcutManager _shortcutManager;

  final _customTextEditKey = GlobalKey<CustomTextEditState>();

  final _scrollableKey = GlobalKey<ScrollableState>();

  final _viewportKey = GlobalKey();

  Timer? _cursorBlinkTimer;
  final _cursorBlinkVisible = ValueNotifier<bool>(true);
  bool _previousBlinkEnabled = false;

  final _composingText = ValueNotifier<String?>(null);

  late TerminalController _controller;

  late ScrollController _scrollController;

  RenderTerminal get renderTerminal =>
      _viewportKey.currentContext!.findRenderObject() as RenderTerminal;

  /// [renderTerminal], or null while the viewport is not mounted or not yet
  /// laid out — which a widget built beside it can see: its build can run
  /// before the viewport's element exists, and in the frame it is replaced.
  RenderTerminal? get laidOutRenderTerminal {
    final render = _viewportKey.currentContext?.findRenderObject();
    return render is RenderTerminal && render.hasSize ? render : null;
  }

  late final textSizeNoti = ValueNotifier(widget.textStyle.fontSize);

  /// Slides the selection highlight from where it was to where it now is.
  ///
  /// A selection is whole cells, so dragging one out moved the highlight a
  /// cell at a time and it stepped rather than followed. Short enough that
  /// the highlight is never far behind the pointer — this is catching the eye
  /// up, not an effect, and a selection that lagged the pointer visibly would
  /// be worse than one that stepped.
  late final AnimationController _selectionAnimation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 70),
  );

  /// The selection the highlight is on its way from. Null when there is
  /// nothing to slide from — a selection that was just made, or just dropped.
  BufferRange? _selectionAnimationFrom;

  BufferRange? _lastSelection;

  void _handleSelectionChange() {
    final selection = _controller.selection;
    final previous = _lastSelection;

    // The controller notifies more than once for a single change, and the
    // repeat carries the same selection. Answering it would stop the tween a
    // moment after starting it, which is the whole animation gone.
    if (selection == previous) {
      return;
    }

    _lastSelection = selection;

    if (selection == null || previous == null) {
      // Nothing to slide from: a selection just made, or just dropped. Left
      // at the far end of the tween, which is where it is drawn from.
      _selectionAnimationFrom = null;
      _selectionAnimation.stop();
      _selectionAnimation.value = 1;
      _applySelectionAnimation();
      return;
    }

    _selectionAnimationFrom = previous;
    _selectionAnimation.forward(from: 0);
    _applySelectionAnimation();
  }

  void _applySelectionAnimation() {
    // Before the first layout there is no render object to tell, and the
    // selection it would be told about is already the one it will first draw.
    if (_viewportKey.currentContext?.findRenderObject() == null) {
      return;
    }

    renderTerminal
      ..selectionFrom = _selectionAnimationFrom
      ..selectionT = _selectionAnimation.value;
  }

  @override
  void initState() {
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_handleFocusChange);
    _controller = widget.controller ?? TerminalController();
    _scrollController = widget.scrollController ?? ScrollController();
    _shortcutManager = ShortcutManager(
      shortcuts: widget.shortcuts ?? defaultTerminalShortcuts,
    );
    widget.terminal.addListener(_handleTerminalChange);
    _controller.addListener(_handleSelectionChange);
    _selectionAnimation.addListener(_applySelectionAnimation);
    _prevIsAltBuffer = widget.terminal.isUsingAltBuffer;
    _prevMouseMode = widget.terminal.mouseMode;
    super.initState();
    _updateCursorBlink(scheduleSetState: false);
  }

  @override
  void didUpdateWidget(TerminalView oldWidget) {
    if (oldWidget.focusNode != widget.focusNode) {
      _focusNode.removeListener(_handleFocusChange);
      if (oldWidget.focusNode == null) {
        _focusNode.dispose();
      }
      _focusNode = widget.focusNode ?? FocusNode();
      _focusNode.addListener(_handleFocusChange);
      _updateCursorBlink(resetVisible: true);
    }
    if (oldWidget.terminal != widget.terminal) {
      oldWidget.terminal.removeListener(_handleTerminalChange);
      widget.terminal.addListener(_handleTerminalChange);
      _prevIsAltBuffer = widget.terminal.isUsingAltBuffer;
      _prevMouseMode = widget.terminal.mouseMode;
      _updateCursorBlink(resetVisible: true);
    }
    if (oldWidget.controller != widget.controller) {
      if (oldWidget.controller == null) {
        _controller.dispose();
      }
      _controller = widget.controller ?? TerminalController();
    }
    if (oldWidget.scrollController != widget.scrollController) {
      if (oldWidget.scrollController == null) {
        _scrollController.dispose();
      }
      _scrollController = widget.scrollController ?? ScrollController();
    }
    _shortcutManager.shortcuts = widget.shortcuts ?? defaultTerminalShortcuts;
    if (oldWidget.textStyle.fontSize != widget.textStyle.fontSize) {
      textSizeNoti.value = widget.textStyle.fontSize;
    }
    if (oldWidget.cursorBlink != widget.cursorBlink ||
        oldWidget.cursorBlinkInterval != widget.cursorBlinkInterval ||
        oldWidget.alwaysShowCursor != widget.alwaysShowCursor) {
      _updateCursorBlink(resetVisible: true);
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    stopAutoScroll();
    _selectionAnimation.dispose();
    _controller.removeListener(_handleSelectionChange);
    widget.terminal.removeListener(_handleTerminalChange);
    _focusNode.removeListener(_handleFocusChange);
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    if (widget.controller == null) {
      _controller.dispose();
    }
    if (widget.scrollController == null) {
      _scrollController.dispose();
    }
    _shortcutManager.dispose();
    textSizeNoti.dispose();
    _cursorBlinkTimer?.cancel();
    _cursorBlinkVisible.dispose();
    _composingText.dispose();
    super.dispose();
  }

  bool get _shouldSuppressScroll {
    if (widget.terminal.isUsingAltBuffer) return true;
    final mode = widget.terminal.mouseMode;
    return mode != MouseMode.none && mode.reportScroll;
  }

  @override
  Widget build(BuildContext context) {
    Widget child = ScrollConfiguration(
      behavior: widget.scrollBehavior ?? const _TerminalScrollBehavior(),
      child: Scrollable(
        key: _scrollableKey,
        controller: _scrollController,
        physics: _shouldSuppressScroll
            ? const NeverScrollableScrollPhysics()
            : const ClampingScrollPhysics(),
        viewportBuilder: (context, offset) {
          return ValueListenableBuilder(
            valueListenable: textSizeNoti,
            builder: (_, textSize, _) {
              return ValueListenableBuilder(
                valueListenable: _cursorBlinkVisible,
                builder: (_, cursorBlinkVisible, _) {
                  return ValueListenableBuilder(
                    valueListenable: _composingText,
                    builder: (_, composingText, _) {
                      return _TerminalView(
                        key: _viewportKey,
                        terminal: widget.terminal,
                        controller: _controller,
                        offset: offset,
                        padding: MediaQuery.of(context).padding,
                        autoResize: widget.autoResize,
                        textStyle: widget.textStyle.copyWith(
                          fontSize: textSize,
                        ),
                        textScaler:
                            widget.textScaler ??
                            MediaQuery.textScalerOf(context),
                        devicePixelRatio: MediaQuery.devicePixelRatioOf(
                          context,
                        ),
                        theme: widget.theme,
                        focusNode: _focusNode,
                        cursorType: widget.cursorType,
                        cursorBlinkEnabled: _cursorBlinkEnabled,
                        cursorBlinkVisible: cursorBlinkVisible,
                        alwaysShowCursor: widget.alwaysShowCursor,
                        onEditableRect: _onEditableRect,
                        composingText: composingText,
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );

    if (!widget.hideScrollBar) {
      child = Scrollbar(controller: _scrollController, child: child);
    }

    child = TerminalScrollGestureHandler(
      terminal: widget.terminal,
      simulateScroll: widget.simulateScroll,
      getCellOffset: (offset) => renderTerminal.getCellOffset(offset),
      getLineHeight: () => renderTerminal.lineHeight,
      child: child,
    );

    if (!widget.hardwareKeyboardOnly) {
      child = CustomTextEdit(
        key: _customTextEditKey,
        focusNode: _focusNode,
        autofocus: widget.autofocus,
        inputType: widget.keyboardType,
        keyboardAppearance: widget.keyboardAppearance,
        deleteDetection: widget.deleteDetection,
        enableSuggestions: widget.enableSuggestions,
        onInsert: _onInsert,
        onDelete: () {
          _scrollToBottom();
          widget.terminal.keyInput(TerminalKey.backspace);
          _updateCursorBlink(resetVisible: true);
        },
        onComposing: _onComposing,
        onAction: (action) {
          _scrollToBottom();
          // Android sends TextInputAction.newline when the user presses the virtual keyboard's enter key.
          if (action == TextInputAction.done ||
              action == TextInputAction.newline) {
            widget.terminal.keyInput(TerminalKey.enter);
            _updateCursorBlink(resetVisible: true);
          }
        },
        onKeyEvent: _handleKeyEvent,
        readOnly: widget.readOnly,
        toolbarBuilder: widget.toolbarBuilder,
        hasSelection: () => _controller.selection != null,
        getSelectedText: () => renderTerminal.selectedText ?? '',
        onCopied: widget.onCopied,
        onSelectAll: widget.onSelectAll ?? () => renderTerminal.selectAll(),
        onPaste: widget.onPaste,
        child: child,
      );
    } else if (!widget.readOnly) {
      // Only listen for key input from a hardware keyboard.
      child = CustomKeyboardListener(
        child: child,
        focusNode: _focusNode,
        autofocus: widget.autofocus,
        onInsert: _onInsert,
        onComposing: _onComposing,
        onKeyEvent: _handleKeyEvent,
      );
    }

    child = TerminalActions(
      terminal: widget.terminal,
      controller: _controller,
      child: child,
    );

    // Outside [TerminalGestureHandler] on purpose: this reports on the raw
    // pointer stream, so a tap that the arena would hand to a selection or a
    // long press still reaches the program. Wrapped in [IgnorePointer] when off
    // so the default path is untouched rather than double-reported.
    if (widget.rawMouseInput) {
      child = _RawMouseListener(
        terminal: widget.terminal,
        // Read through the owner on every event: the viewport is not mounted
        // while this builds, and only settles once it has been laid out.
        renderTerminal: () => laidOutRenderTerminal,
        child: child,
      );
    }

    child = TerminalGestureHandler(
      viewOffset: widget.viewOffset,
      showToolbar: widget.showToolbar,
      terminalView: this,
      terminalController: _controller,
      onTapUp: _onTapUp,
      onTapDown: _onTapDown,
      // The raw pointer path already reports this tap. Left out of the arena's
      // reporting rather than out of its callbacks: [_onTapDown] is also what
      // raises the keyboard, and that has to keep happening.
      suppressTapReporting: widget.rawMouseInput,
      onSecondaryTapDown: widget.onSecondaryTapDown != null
          ? _onSecondaryTapDown
          : null,
      onSecondaryTapUp: widget.onSecondaryTapUp != null
          ? _onSecondaryTapUp
          : null,
      readOnly: widget.readOnly,
      scrollController: _scrollController,
      child: child,
    );

    child = MouseRegion(cursor: widget.mouseCursor, child: child);

    child = Container(
      color: widget.theme.background.withValues(
        alpha: widget.backgroundOpacity,
      ),
      padding: widget.padding,
      child: child,
    );

    return child;
  }

  void requestKeyboard() {
    _customTextEditKey.currentState?.requestKeyboard();
  }

  /// Whether the keyboard this view raises is up.
  ///
  /// The input connection *is* the keyboard: opening it is what raised one, so
  /// a host that keeps a line of its own under the terminal asks this to know
  /// which of the two is holding the keyboard now.
  bool get hasKeyboard =>
      _customTextEditKey.currentState?.hasInputConnection ?? false;

  void closeKeyboard() {
    _customTextEditKey.currentState?.closeKeyboard();
  }

  void unFocus() {
    _focusNode.unfocus();
    _customTextEditKey.currentState?.closeKeyboard();
  }

  void showSelectionToolbar(Rect globalSelectionRect) {
    _customTextEditKey.currentState?.showToolbar(
      globalSelectionRect: globalSelectionRect,
    );
  }

  void hideSelectionToolbar() {
    _customTextEditKey.currentState?.hideToolbar();
  }

  bool get isSelectionToolbarShown =>
      _customTextEditKey.currentState?.isToolbarShown ?? false;

  void toggleFocus() {
    _customTextEditKey.currentState?.toggleKeyboard();
    if (_focusNode.hasFocus) {
      _focusNode.unfocus();
    } else {
      _focusNode.requestFocus();
    }
  }

  Rect get cursorRect {
    return renderTerminal.cursorOffset & renderTerminal.cellSize;
  }

  Rect get globalCursorRect {
    return renderTerminal.localToGlobal(renderTerminal.cursorOffset) &
        renderTerminal.cellSize;
  }

  bool get _cursorBlinkEnabled {
    return (widget.cursorBlink || widget.terminal.cursorBlinkMode) &&
        _focusNode.hasFocus &&
        !widget.alwaysShowCursor;
  }

  void _handleTerminalChange() {
    var shouldUpdate = false;

    if (_cursorBlinkEnabled != _previousBlinkEnabled) {
      _updateCursorBlink(resetVisible: true);
      shouldUpdate = true;
    }

    final isAltBuffer = widget.terminal.isUsingAltBuffer;
    final mouseMode = widget.terminal.mouseMode;
    if (_prevIsAltBuffer != isAltBuffer || _prevMouseMode != mouseMode) {
      _prevIsAltBuffer = isAltBuffer;
      _prevMouseMode = mouseMode;
      shouldUpdate = true;
    }

    if (shouldUpdate && mounted) {
      setState(() {});
    }
  }

  void _handleFocusChange() {
    widget.terminal.focusInput(_focusNode.hasFocus);
    _updateCursorBlink(resetVisible: true);
  }

  void _updateCursorBlink({
    bool resetVisible = false,
    bool scheduleSetState = true,
  }) {
    final shouldBlink = _cursorBlinkEnabled;
    final blinkChanged = shouldBlink != _previousBlinkEnabled;
    _previousBlinkEnabled = shouldBlink;

    _cursorBlinkTimer?.cancel();

    var shouldNotify = blinkChanged;

    if ((resetVisible || !shouldBlink) && !_cursorBlinkVisible.value) {
      _cursorBlinkVisible.value = true;
      shouldNotify = true;
    }

    if (shouldBlink) {
      _cursorBlinkTimer = Timer.periodic(widget.cursorBlinkInterval, (_) {
        if (!mounted) {
          return;
        }
        _cursorBlinkVisible.value = !_cursorBlinkVisible.value;
      });
    }

    if (shouldNotify && scheduleSetState && mounted) {
      setState(() {});
    }
  }

  void _onTapUp(TapUpDetails details) {
    final offset = renderTerminal.getCellOffset(details.localPosition);
    widget.onTapUp?.call(details, offset);
    if (widget.rawMouseInput) return;
    widget.terminal.mouseInput(
      TerminalMouseButton.left,
      TerminalMouseButtonState.up,
      offset,
    );
  }

  void _onTapDown(TapDownDetails details) {
    if (_controller.selection == null) {
      if (!widget.hardwareKeyboardOnly) {
        if (widget.tapToShowKeyboard) {
          _customTextEditKey.currentState?.requestKeyboard();
        }
        // Deliberately not the focus either: focus opens the input connection,
        // which is what raises the keyboard. So a tap that is not going to
        // raise one does not take it.
      } else {
        _focusNode.requestFocus();
      }
    }

    _updateCursorBlink(resetVisible: true);

    if (widget.rawMouseInput) return;
    widget.terminal.mouseInput(
      TerminalMouseButton.left,
      TerminalMouseButtonState.down,
      renderTerminal.getCellOffset(details.localPosition),
    );
  }

  void _onSecondaryTapDown(TapDownDetails details) {
    final offset = renderTerminal.getCellOffset(details.localPosition);
    widget.onSecondaryTapDown?.call(details, offset);
  }

  void _onSecondaryTapUp(TapUpDetails details) {
    final offset = renderTerminal.getCellOffset(details.localPosition);
    widget.onSecondaryTapUp?.call(details, offset);
  }

  bool get hasInputConnection {
    return _customTextEditKey.currentState?.hasInputConnection == true;
  }

  void _onInsert(String text) {
    final key = charToTerminalKey(text.trim());

    // On mobile platforms there is no guarantee that virtual keyboard will
    // generate hardware key events. So we need first try to send the key
    // as a hardware key event. If it fails, then we send it as a text input.
    final consumed = key == null ? false : widget.terminal.keyInput(key);

    if (!consumed) {
      widget.terminal.textInput(text);
    }

    _scrollToBottom();
    _updateCursorBlink(resetVisible: true);
  }

  void _onComposing(String? text) {
    _composingText.value = text;
    _updateCursorBlink(resetVisible: true);
  }

  KeyEventResult _handleKeyEvent(FocusNode focusNode, KeyEvent event) {
    final resultOverride = widget.onKeyEvent?.call(focusNode, event);
    if (resultOverride != null && resultOverride != KeyEventResult.ignored) {
      return resultOverride;
    }

    // ignore: invalid_use_of_protected_member
    final shortcutResult = _shortcutManager.handleKeypress(
      focusNode.context!,
      event,
    );

    if (shortcutResult != KeyEventResult.ignored) {
      return shortcutResult;
    }

    if (event is KeyUpEvent) {
      return KeyEventResult.ignored;
    }

    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }

    final key = keyToTerminalKey(event.logicalKey);
    if (key == null) {
      return KeyEventResult.ignored;
    }

    final handled = _sendTerminalKey(key);

    if (!handled) {
      return KeyEventResult.ignored;
    }

    return KeyEventResult.handled;
  }

  bool _sendTerminalKey(TerminalKey key) {
    final handled = widget.terminal.keyInput(
      key,
      ctrl: HardwareKeyboard.instance.isControlPressed,
      alt: HardwareKeyboard.instance.isAltPressed,
      shift: HardwareKeyboard.instance.isShiftPressed,
    );

    if (handled) {
      _scrollToBottom();
      _updateCursorBlink(resetVisible: true);
    }

    return handled;
  }

  void _onEditableRect(Rect rect, Rect caretRect) {
    _customTextEditKey.currentState?.setEditableRect(rect, caretRect);
  }

  void _scrollToBottom() {
    final position = _scrollableKey.currentState?.position;
    if (position != null) {
      position.animateTo(
        position.maxScrollExtent,
        duration: const Duration(milliseconds: 377),
        curve: Curves.fastEaseInToSlowEaseOut,
      );
    }
  }

  /// How far from an edge a pointer starts dragging the view, and also the
  /// distance past that point at which it reaches [_autoScrollMaxLines].
  double get _autoScrollBand => renderTerminal.lineHeight * 3;

  /// Lines a second at full deflection. Fast enough to cross a screen while
  /// the eye is still on the pointer, slow enough to stop on a line.
  static const _autoScrollMaxLines = 15.0;

  Ticker? _autoScrollTicker;
  Duration _autoScrollLastTick = Duration.zero;

  /// Logical pixels a second, signed. Zero means the pointer is not in either
  /// band and the ticker has nothing to do.
  double _autoScrollVelocity = 0;

  /// Run after each tick has scrolled, so whatever is following the pointer
  /// can follow the content that moved under it. Without it a selection stops
  /// growing the moment the pointer stops moving, which is the whole case this
  /// exists for.
  VoidCallback? _autoScrollOnTick;

  /// Drives the view from a pointer held near or past an edge.
  ///
  /// Called on every pointer move, but the scrolling itself is on a ticker
  /// rather than on those events: a pointer held still outside the edge sends
  /// no more of them, and stopping there is exactly what a drag past the end
  /// of the buffer must not do.
  void updateAutoScroll(Offset localPointerPosition, {VoidCallback? onTick}) {
    final band = _autoScrollBand;
    final dy = localPointerPosition.dy;

    // Deflection past the inner edge of each band, clamped so that a pointer
    // dragged far outside the widget is not faster than one just outside it.
    final past = dy < band
        ? -(band - dy)
        : dy > renderTerminal.size.height - band
        ? dy - (renderTerminal.size.height - band)
        : 0.0;

    _autoScrollVelocity =
        (past / band).clamp(-1.0, 1.0) *
        _autoScrollMaxLines *
        renderTerminal.lineHeight;
    _autoScrollOnTick = onTick;

    if (_autoScrollVelocity == 0) {
      stopAutoScroll();
      return;
    }

    if (_autoScrollTicker == null) {
      _autoScrollLastTick = Duration.zero;
      _autoScrollTicker = createTicker(_onAutoScrollTick)..start();
    }
  }

  void stopAutoScroll() {
    _autoScrollTicker?.dispose();
    _autoScrollTicker = null;
    _autoScrollVelocity = 0;
    _autoScrollOnTick = null;
  }

  void _onAutoScrollTick(Duration elapsed) {
    final position = _scrollableKey.currentState?.position;
    if (position == null) {
      stopAutoScroll();
      return;
    }

    // The first tick has no interval behind it.
    final dt = _autoScrollLastTick == Duration.zero
        ? Duration.zero
        : elapsed - _autoScrollLastTick;
    _autoScrollLastTick = elapsed;

    final target = (position.pixels +
            _autoScrollVelocity * dt.inMicroseconds / 1e6)
        .clamp(position.minScrollExtent, position.maxScrollExtent);

    // `jumpTo` rather than `animateTo`: the ticker is already the animation,
    // and starting another one per frame is what made this stutter.
    if (target != position.pixels) {
      position.jumpTo(target);
    }

    _autoScrollOnTick?.call();
  }
}

class _TerminalView extends LeafRenderObjectWidget {
  const _TerminalView({
    super.key,
    required this.terminal,
    required this.controller,
    required this.offset,
    required this.padding,
    required this.autoResize,
    required this.textStyle,
    required this.textScaler,
    required this.devicePixelRatio,
    required this.theme,
    required this.focusNode,
    required this.cursorType,
    required this.cursorBlinkEnabled,
    required this.cursorBlinkVisible,
    required this.alwaysShowCursor,
    this.onEditableRect,
    this.composingText,
  });

  final Terminal terminal;

  final TerminalController controller;

  final ViewportOffset offset;

  final EdgeInsets padding;

  final bool autoResize;

  final TerminalStyle textStyle;

  final TextScaler textScaler;

  final double devicePixelRatio;

  final TerminalTheme theme;

  final FocusNode focusNode;

  final TerminalCursorType cursorType;

  final bool cursorBlinkEnabled;

  final bool cursorBlinkVisible;

  final bool alwaysShowCursor;


  final EditableRectCallback? onEditableRect;

  final String? composingText;

  @override
  RenderTerminal createRenderObject(BuildContext context) {
    return RenderTerminal(
      terminal: terminal,
      controller: controller,
      offset: offset,
      padding: padding,
      autoResize: autoResize,
      textStyle: textStyle,
      textScaler: textScaler,
      devicePixelRatio: devicePixelRatio,
      theme: theme,
      focusNode: focusNode,
      cursorType: cursorType,
      cursorBlinkEnabled: cursorBlinkEnabled,
      cursorBlinkVisible: cursorBlinkVisible,
      alwaysShowCursor: alwaysShowCursor,
      onEditableRect: onEditableRect,
      composingText: composingText,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderTerminal renderObject) {
    renderObject
      ..terminal = terminal
      ..controller = controller
      ..offset = offset
      ..padding = padding
      ..autoResize = autoResize
      ..textStyle = textStyle
      ..textScaler = textScaler
      ..devicePixelRatio = devicePixelRatio
      ..theme = theme
      ..focusNode = focusNode
      ..cursorType = cursorType
      ..cursorBlinkEnabled = cursorBlinkEnabled
      ..cursorBlinkVisible = cursorBlinkVisible
      ..alwaysShowCursor = alwaysShowCursor
      ..onEditableRect = onEditableRect
      ..composingText = composingText;
  }
}

/// Reports taps to the terminal straight from the pointer stream.
///
/// [TerminalGestureHandler] is built around the gesture arena: a tap is first
/// offered to selection, scale and long-press recognisers, and only what they
/// leave over reaches [Terminal.mouseInput]. That is the right default for a
/// shell, and the wrong one for a full-screen program that draws its own tabs
/// and panes — there, the tap *is* the click, and losing it to a selection
/// means the interface looks dead.
///
/// So this listens to [PointerDownEvent]/[PointerUpEvent] directly and asks
/// [Terminal.mouseInput] the moment they arrive. The report itself is still
/// built by [Terminal.mouseInput], which is what decides whether the program
/// asked for mouse events at all and which encoding to use.
class _RawMouseListener extends StatefulWidget {
  const _RawMouseListener({
    required this.terminal,
    required this.renderTerminal,
    required this.child,
  });

  final Terminal terminal;

  /// The laid-out viewport, or null before the first frame that has one.
  final RenderTerminal? Function() renderTerminal;

  final Widget child;

  @override
  State<_RawMouseListener> createState() => _RawMouseListenerState();
}

class _RawMouseListenerState extends State<_RawMouseListener> {
  int _activePointers = 0;
  Offset? _lastLocal;

  @override
  Widget build(BuildContext context) {
    return Listener(
      // `deferToChild` would drop every event wherever the child has no
      // recogniser of its own; the whole point here is to hear the pointer
      // either way.
      behavior: HitTestBehavior.translucent,
      onPointerDown: _onDown,
      onPointerUp: _onUp,
      onPointerCancel: _onCancel,
      onPointerSignal: _onSignal,
      child: widget.child,
    );
  }

  void _onDown(PointerDownEvent event) {
    _activePointers++;
    _lastLocal = _localOf(event);
    _report(TerminalMouseButton.left, TerminalMouseButtonState.down);
  }

  void _onUp(PointerUpEvent event) {
    _activePointers = (_activePointers - 1).clamp(0, 1 << 30);
    _lastLocal = _localOf(event);
    _report(TerminalMouseButton.left, TerminalMouseButtonState.up);
  }

  void _onCancel(PointerCancelEvent event) {
    if (_activePointers > 0) _activePointers--;
    // The program is left holding a button down otherwise, and a TUI that
    // waits for the release to finish a click never fires.
    _report(TerminalMouseButton.left, TerminalMouseButtonState.up);
  }

  void _onSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent) return;
    // A wheel is two reports: whichever button this platform calls up/down.
    // Buttons 4/5 in X11 terms are what [TerminalMouseButton.wheelUp/Down]
    // encode as, and both terminals that matter accept those.
    // By the sign of the delta, the way the scroll handler reads it: a
    // Flutter 3.47 no longer exposes the per-platform direction on this
    // event, and the delta is the direction that survived.
    final button = event.scrollDelta.dy < 0
        ? TerminalMouseButton.wheelUp
        : TerminalMouseButton.wheelDown;
    final pos = _localOf(event);
    final render = widget.renderTerminal();
    if (pos == null || render == null) return;
    final cell = render.getCellOffset(pos);
    widget.terminal.mouseInput(button, TerminalMouseButtonState.down, cell);
    widget.terminal.mouseInput(button, TerminalMouseButtonState.up, cell);
  }

  Offset? _localOf(PointerEvent event) {
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return _lastLocal;
    return box.globalToLocal(event.position);
  }

  void _report(TerminalMouseButton button, TerminalMouseButtonState state) {
    final pos = _lastLocal;
    final render = widget.renderTerminal();
    if (pos == null || render == null) return;
    widget.terminal.mouseInput(button, state, render.getCellOffset(pos));
  }
}

class _TerminalScrollBehavior extends ScrollBehavior {
  const _TerminalScrollBehavior();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}

