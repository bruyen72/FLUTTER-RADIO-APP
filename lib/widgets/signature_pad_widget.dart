import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/constants.dart';

class SignaturePadController extends ChangeNotifier {
  final List<List<Offset>> _strokes = [];
  List<Offset>? _stroke;
  late Size _size;
  Size? _drawSize; // tamanho real da tela onde os traços foram desenhados

  bool get isEmpty => _strokes.isEmpty;

  void setSize(Size s) => _size = s;

  void onStart(Offset p) {
    _drawSize ??= _size; // captura o tamanho na primeira pincelada
    _stroke = [p];
    _strokes.add(_stroke!);
    notifyListeners();
  }

  void onUpdate(Offset p) {
    _stroke?.add(p);
    notifyListeners();
  }

  void onEnd() => _stroke = null;

  void clear() {
    _strokes.clear();
    _stroke = null;
    _drawSize = null;
    notifyListeners();
  }

  List<List<Offset>> get strokes =>
      _strokes.map((s) => List<Offset>.from(s)).toList();

  void loadStrokes(List<List<Offset>> s) {
    _strokes.clear();
    _strokes.addAll(s.map((stroke) => List<Offset>.from(stroke)));
    _drawSize = null;
    notifyListeners();
  }

  Future<Uint8List?> toPngBytes() async {
    if (isEmpty) return null;
    final size = _drawSize ?? _size; // usa o tamanho onde os traços foram desenhados
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFFFFFFFF),
    );

    final paint = Paint()
      ..color = const Color(0xFF0A0A0A)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    for (final stroke in _strokes) {
      if (stroke.length < 2) continue;
      final path = Path()..moveTo(stroke[0].dx, stroke[0].dy);
      for (int i = 1; i < stroke.length; i++) {
        path.lineTo(stroke[i].dx, stroke[i].dy);
      }
      canvas.drawPath(path, paint);
    }

    final picture = recorder.endRecording();
    final image = await picture.toImage(size.width.toInt(), size.height.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return bytes?.buffer.asUint8List();
  }
}

// ── Widget inline ─────────────────────────────────────────────────────────────

class SignaturePadWidget extends StatefulWidget {
  final SignaturePadController controller;
  final String label;
  final double height;

  const SignaturePadWidget({
    super.key,
    required this.controller,
    required this.label,
    this.height = 140,
  });

  @override
  State<SignaturePadWidget> createState() => _SignaturePadWidgetState();
}

class _SignaturePadWidgetState extends State<SignaturePadWidget> {
  late final VoidCallback _listener;

  @override
  void initState() {
    super.initState();
    _listener = () { if (mounted) setState(() {}); };
    widget.controller.addListener(_listener);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_listener);
    super.dispose();
  }

  Future<void> _abrirTelaCheia() async {
    final backup = widget.controller.strokes;

    final confirmado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _TelaAssinatura(
          controller: widget.controller,
          label: widget.label,
          strokesBackup: backup,
        ),
      ),
    );

    if (confirmado != true) {
      widget.controller.loadStrokes(backup);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                widget.label,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 13, color: kTextColor2),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            TextButton.icon(
              onPressed: _abrirTelaCheia,
              icon: const Icon(Icons.open_in_full, size: 14),
              label: const Text('Tela cheia', style: TextStyle(fontSize: 12)),
              style: TextButton.styleFrom(
                foregroundColor: kPrimaryLight,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: const Size(0, 30),
              ),
            ),
            TextButton.icon(
              onPressed: widget.controller.clear,
              icon: const Icon(Icons.clear, size: 14),
              label: const Text('Limpar', style: TextStyle(fontSize: 12)),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: const Size(0, 30),
              ),
            ),
          ],
        ),
        GestureDetector(
          onTap: _abrirTelaCheia,
          child: LayoutBuilder(
            builder: (_, constraints) {
              final size = Size(constraints.maxWidth, widget.height);
              widget.controller.setSize(size);
              return Container(
                width: size.width,
                height: size.height,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: const Color(0x33FFFFFF)),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Stack(
                  children: [
                    CustomPaint(
                      size: size,
                      painter: _SignaturePainter(widget.controller.strokes),
                    ),
                    if (widget.controller.isEmpty)
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.draw_outlined,
                                color: Color(0xFFBBBBBB), size: 28),
                            const SizedBox(height: 4),
                            Text('Toque para assinar',
                                style: TextStyle(
                                    color: Colors.grey.shade400, fontSize: 12)),
                          ],
                        ),
                      ),
                    // Badge "Assinado" quando há traços capturados em tela cheia
                    if (!widget.controller.isEmpty)
                      Positioned(
                        top: 6, right: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF16a34a),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check, size: 11, color: Colors.white),
                              SizedBox(width: 3),
                              Text('Assinado', style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ── Tela cheia de assinatura ──────────────────────────────────────────────────

class _TelaAssinatura extends StatefulWidget {
  final SignaturePadController controller;
  final String label;
  final List<List<Offset>> strokesBackup;

  const _TelaAssinatura({
    required this.controller,
    required this.label,
    required this.strokesBackup,
  });

  @override
  State<_TelaAssinatura> createState() => _TelaAssinaturaState();
}

class _TelaAssinaturaState extends State<_TelaAssinatura> {
  late final VoidCallback _listener;

  @override
  void initState() {
    super.initState();
    _listener = () { if (mounted) setState(() {}); };
    widget.controller.addListener(_listener);
    // Força paisagem para assinar com mais espaço horizontal
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    // Restaura orientação ao sair
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    widget.controller.removeListener(_listener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: kSurfaceColor,
        foregroundColor: kTextColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancelar',
              style: TextStyle(color: kColorCancelado, fontSize: 14)),
        ),
        leadingWidth: 90,
        title: Text(widget.label,
            style: const TextStyle(color: kTextColor, fontSize: 15)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmar',
                style: TextStyle(
                    color: kPrimaryLight,
                    fontSize: 14,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8),
            color: const Color(0xFFF5F5F5),
            child: const Text(
              'Assine no espaço abaixo',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF999999), fontSize: 12),
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (_, constraints) {
                final size = Size(constraints.maxWidth, constraints.maxHeight);
                widget.controller.setSize(size);
                return GestureDetector(
                  onPanStart: (d) => widget.controller.onStart(d.localPosition),
                  onPanUpdate: (d) => widget.controller.onUpdate(d.localPosition),
                  onPanEnd: (_) => widget.controller.onEnd(),
                  child: CustomPaint(
                    size: size,
                    painter: _SignaturePainter(widget.controller.strokes),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            color: const Color(0xFFF5F5F5),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: widget.controller.clear,
                icon: const Icon(Icons.clear, size: 16),
                label: const Text('Limpar assinatura'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Painter ───────────────────────────────────────────────────────────────────

class _SignaturePainter extends CustomPainter {
  final List<List<Offset>> strokes;
  _SignaturePainter(this.strokes);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF0A0A0A)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    for (final stroke in strokes) {
      if (stroke.length < 2) continue;
      final path = Path()..moveTo(stroke[0].dx, stroke[0].dy);
      for (int i = 1; i < stroke.length; i++) {
        path.lineTo(stroke[i].dx, stroke[i].dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_SignaturePainter old) => true;
}
