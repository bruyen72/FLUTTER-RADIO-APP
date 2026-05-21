import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../utils/constants.dart';

class FotoPicker extends StatelessWidget {
  final List<String> fotosUrl;
  final List<File> fotosLocais;
  final void Function(File) onFotoAdicionada;
  final void Function(int index)? onFotoUrlRemovida;
  final void Function(int index)? onFotoLocalRemovida;

  const FotoPicker({
    super.key,
    required this.fotosUrl,
    required this.fotosLocais,
    required this.onFotoAdicionada,
    this.onFotoUrlRemovida,
    this.onFotoLocalRemovida,
  });

  Future<void> _capturar(BuildContext context, ImageSource source) async {
    // Câmera: pede permissão explícita
    if (source == ImageSource.camera) {
      final perm = await Permission.camera.request();
      if (!perm.isGranted) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Permissão de câmera negada')),
          );
        }
        return;
      }
    }
    // Galeria: image_picker usa o seletor do sistema no Android 13+
    // e gerencia as permissões internamente — não precisa pedir aqui.

    try {
      final picker = ImagePicker();
      final xfile = await picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1280,
      );
      if (xfile != null) {
        onFotoAdicionada(File(xfile.path));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao capturar foto: $e')),
        );
      }
    }
  }

  void _mostrarOpcoes(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: kCardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              margin: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: kBorderColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: kPrimaryLight),
              title: const Text('Tirar foto', style: TextStyle(color: kTextColor)),
              onTap: () {
                Navigator.pop(context);
                _capturar(context, ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: kPrimaryLight),
              title: const Text('Escolher da galeria', style: TextStyle(color: kTextColor)),
              onTap: () {
                Navigator.pop(context);
                _capturar(context, ImageSource.gallery);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final total = fotosUrl.length + fotosLocais.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Fotos',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: kTextColor2)),
            const Spacer(),
            TextButton.icon(
              onPressed: () => _mostrarOpcoes(context),
              icon: const Icon(Icons.add_a_photo, size: 16, color: kPrimaryLight),
              label: const Text('Adicionar',
                  style: TextStyle(color: kPrimaryLight, fontSize: 13)),
              style: TextButton.styleFrom(padding: EdgeInsets.zero),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (total > 0)
          SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: total,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                if (i < fotosUrl.length) {
                  return _fotoItem(
                    child: CachedNetworkImage(
                      imageUrl: fotosUrl[i],
                      width: 100, height: 100,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => _placeholder(),
                      errorWidget: (_, __, ___) => _placeholder(error: true),
                    ),
                    onRemover: onFotoUrlRemovida != null
                        ? () => onFotoUrlRemovida!(i)
                        : null,
                  );
                }
                final li = i - fotosUrl.length;
                return _fotoItem(
                  child: Image.file(fotosLocais[li],
                      width: 100, height: 100, fit: BoxFit.cover),
                  onRemover: onFotoLocalRemovida != null
                      ? () => onFotoLocalRemovida!(li)
                      : null,
                );
              },
            ),
          )
        else
          GestureDetector(
            onTap: () => _mostrarOpcoes(context),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: const Color(0x05FFFFFF),
                border: Border.all(color: kBorderColor),
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Column(
                children: [
                  Icon(Icons.add_photo_alternate_outlined, color: kPrimaryLight, size: 28),
                  SizedBox(height: 6),
                  Text('Toque para adicionar foto',
                      style: TextStyle(color: kPrimaryLight, fontSize: 12)),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _fotoItem({required Widget child, VoidCallback? onRemover}) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: child,
        ),
        if (onRemover != null)
          Positioned(
            top: 4, right: 4,
            child: GestureDetector(
              onTap: onRemover,
              child: Container(
                width: 22, height: 22,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.65),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 14, color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }

  Widget _placeholder({bool error = false}) => Container(
        width: 100, height: 100,
        decoration: BoxDecoration(
          color: kCardColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: kBorderColor),
        ),
        child: Icon(
          error ? Icons.broken_image_outlined : Icons.image_outlined,
          color: kTextColor3, size: 28,
        ),
      );
}
