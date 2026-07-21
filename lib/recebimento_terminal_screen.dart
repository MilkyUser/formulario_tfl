import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

// Importacao dos pacotes instalados
import 'package:archive/archive_io.dart';
import 'package:url_launcher/url_launcher.dart';
//import 'package:file_picker/file_picker.dart';

// Importacoes especificas para Mobile
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:image_picker/image_picker.dart';

// Importacao condicional para nao quebrar no Mobile devido ao 'dart:html'
import 'package:universal_html/html.dart' as html;
import 'dart:io' as io;

class RecebimentoTerminalScreen extends StatefulWidget {
  const RecebimentoTerminalScreen({super.key});

  @override
  State<RecebimentoTerminalScreen> createState() =>
      _RecebimentoTerminalScreenState();
}

class _RecebimentoTerminalScreenState extends State<RecebimentoTerminalScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();
  final _numeroSerieController = TextEditingController();

  final _numeroReqController = TextEditingController();

  String? _modeloSelecionado;
  final List<String> _modelosDisponiveis = [
    '4020',
    '4020A',
    '4020B',
    '4020-001',
    '4020-002',
    '4020-003',
    '4020-004',
  ];

  // --- VARIAVEIS PARA OS ANEXOS PRINCIPAIS ---
  List<String> _etiquetaNomes = [];
  List<List<int>> _etiquetaBytes = [];

  List<String> _kitCompletoNomes = [];
  List<List<int>> _kitCompletoBytes = [];

  final List<Map<String, dynamic>> _perifericos = [
    {
      'nome': 'Gabinete/Chassi',
      'possui': true,
      'obs': TextEditingController(),
      'fotos_nomes': <String>[],
      'fotos_bytes': <List<int>>[],
    },
    {
      'nome': 'Monitor',
      'possui': true,
      'obs': TextEditingController(),
      'fotos_nomes': <String>[],
      'fotos_bytes': <List<int>>[],
    },
    {
      'nome': 'Pinpad',
      'possui': false,
      'obs': TextEditingController(),
      'fotos_nomes': <String>[],
      'fotos_bytes': <List<int>>[],
      'modelo': null,
    },
    {
      'nome': 'Leitor Biometrico',
      'possui': false,
      'obs': TextEditingController(),
      'fotos_nomes': <String>[],
      'fotos_bytes': <List<int>>[],
      'minex_iii': null,
    },
    {
      'nome': 'Leitor de Codigo de Barras e Suporte',
      'possui': false,
      'obs': TextEditingController(),
      'fotos_nomes': <String>[],
      'fotos_bytes': <List<int>>[],
    },
    {
      'nome': 'Impressora',
      'possui': false,
      'obs': TextEditingController(),
      'fotos_nomes': <String>[],
      'fotos_bytes': <List<int>>[],
    },
    {
      'nome': 'Teclado',
      'possui': false,
      'obs': TextEditingController(),
      'fotos_nomes': <String>[],
      'fotos_bytes': <List<int>>[],
    },
    {
      'nome': 'Nobreak',
      'possui': false,
      'obs': TextEditingController(),
      'fotos_nomes': <String>[],
      'fotos_bytes': <List<int>>[],
    },
  ];

  final List<String> _modelosPinpad = [
    'PPC920',
    'PPC930',
    'PPP100-2023',
    'PPP100-2025',
  ];

  @override
  void dispose() {
    _numeroSerieController.dispose();
    _numeroReqController.dispose();
    for (var p in _perifericos) {
      p['obs'].dispose();
    }
    super.dispose();
  }

// --- FLUXO DE SELEÇÃO CORRIGIDO ---

  // Método auxiliar que gerencia a escolha do usuário e retorna uma lista de XFile
  Future<List<XFile>> _escolherOrigemImagensMultiplas() async {
    final ImageSource? fonte = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.indigo),
              title: const Text('Tirar Foto (Câmera)'),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.indigo),
              title: const Text('Escolher da Galeria (Múltiplas)'),
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (fonte == ImageSource.camera) {
      // Se for câmera, tira uma foto única e retorna em uma lista de um elemento
      final XFile? foto = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
      return foto != null ? [foto] : [];
    } else if (fonte == ImageSource.gallery) {
      // Se for galeria, permite selecionar várias imagens de uma vez só!
      return await _picker.pickMultiImage(
        imageQuality: 85,
      );
    }
    return [];
  }

  Future<void> _abrirSeletorFoto(int index) async {
    // Busca a lista de fotos (seja a única da câmera ou as várias da galeria)
    final List<XFile> fotosSelecionadas = await _escolherOrigemImagensMultiplas();

    if (fotosSelecionadas.isNotEmpty) {
      List<String> nomesAtualizados = List<String>.from(_perifericos[index]['fotos_nomes']);
      List<List<int>> bytesAtualizados = List<List<int>>.from(_perifericos[index]['fotos_bytes']);

      for (var foto in fotosSelecionadas) {
        final bytes = await foto.readAsBytes();
        nomesAtualizados.add(foto.name);
        bytesAtualizados.add(bytes);
      }

      setState(() {
        _perifericos[index]['fotos_nomes'] = nomesAtualizados;
        _perifericos[index]['fotos_bytes'] = bytesAtualizados;
      });
    }
  }

  Future<void> _abrirSeletorFotoPrincipal(bool esEtiqueta) async {
    // Busca a lista de fotos (seja a única da câmera ou as várias da galeria)
    final List<XFile> fotosSelecionadas = await _escolherOrigemImagensMultiplas();

    if (fotosSelecionadas.isNotEmpty) {
      List<String> nomesNovos = [];
      List<List<int>> bytesNovos = [];

      for (var foto in fotosSelecionadas) {
        final bytes = await foto.readAsBytes();
        nomesNovos.add(foto.name);
        bytesNovos.add(bytes);
      }

      setState(() {
        if (esEtiqueta) {
          _etiquetaNomes = List<String>.from(_etiquetaNomes)..addAll(nomesNovos);
          _etiquetaBytes = List<List<int>>.from(_etiquetaBytes)..addAll(bytesNovos);
        } else {
          _kitCompletoNomes = List<String>.from(_kitCompletoNomes)..addAll(nomesNovos);
          _kitCompletoBytes = List<List<int>>.from(_kitCompletoBytes)..addAll(bytesNovos);
        }
      });
    }
  }

  // --- NOVA INTERFACE DE VISUALIZAÇÃO DE IMAGEM AMPLIADA (MODAL) ---
  void _visualizarImagemGrande(Uint8List imageBytes, String nome) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(15),
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              panEnabled: true,
              boundaryMargin: const EdgeInsets.all(20),
              minScale: 0.5,
              maxScale: 4.0,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.memory(
                  imageBytes,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: CircleAvatar(
                backgroundColor: Colors.black54,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
            Positioned(
              bottom: 15,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  nome,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- COMPONENTE VISUAL PARA GERENCIAR A LISTA DE FOTOS ---
  Widget _buildGerenciadorFotos({
    required List<String> nomes,
    required List<List<int>> bytesList,
    required VoidCallback onRemoverTodas,
    required Function(int) onRemoverUnica,
  }) {
    if (bytesList.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${nomes.length} foto(s) anexada(s):',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.indigo),
            ),
            TextButton.icon(
              onPressed: onRemoverTodas,
              icon: const Icon(Icons.delete_sweep, size: 16, color: Colors.red),
              label: const Text('Limpar todas', style: TextStyle(fontSize: 12, color: Colors.red)),
              style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
            ),
          ],
        ),
        const SizedBox(height: 5),
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: bytesList.length,
            itemBuilder: (context, idx) {
              final imgBytes = Uint8List.fromList(bytesList[idx]);
              final nomeImg = nomes[idx];

              return Container(
                margin: const EdgeInsets.only(right: 10),
                width: 80,
                child: Stack(
                  children: [
                    GestureDetector(
                      onTap: () => _visualizarImagemGrande(imgBytes, nomeImg),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.indigo.withValues(alpha: 0.3)),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(7),
                          child: Image.memory(
                            imgBytes,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 2,
                      right: 2,
                      child: GestureDetector(
                        onTap: () => onRemoverUnica(idx),
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }


  // --- MODAL INSTRUTIVO EXCLUSIVO PARA O AMBIENTE WEB ---
  void _mostrarAvisoAnexoWeb(String nomeArquivo, VoidCallback onConfirmar) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
              SizedBox(width: 10),
              Text('Atencao: Proximo Passo!'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'O arquivo de vistoria foi gerado e o download iniciou automaticamente com o nome:',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Text(
                  nomeArquivo,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                    color: Colors.indigo,
                  ),
                ),
              ),
              const SizedBox(height: 15),
              const Text(
                'Ao clicar no botao abaixo, seu e-mail sera aberto. Voce DEVE anexar este arquivo manualmente antes de enviar.',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                onConfirmar();
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
              child: const Text(
                'Entendi, abrir E-mail',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

    String _gerarConteudoCSV() {
    final String serie = _numeroSerieController.text;
    final String req = _numeroReqController.text.trim();
    final String modelo = _modeloSelecionado ?? '';

    StringBuffer csvBuffer = StringBuffer();
    csvBuffer.writeln('série;req;modelo terminal;tipo foto;endereço foto;observações');

    // 1. Fotos da Etiqueta
    for (var nome in _etiquetaNomes) {
      csvBuffer.writeln('$serie;$req;$modelo;Etiqueta;imagens/${serie}_etiqueta_$nome;');
    }

    // 2. Fotos do Kit Completo
    for (var nome in _kitCompletoNomes) {
      csvBuffer.writeln('$serie;$req;$modelo;Kit Completo;imagens/${serie}_kit_$nome;');
    }

    // 3. Periféricos
    for (var p in _perifericos) {
      if (p['possui'] == true) {
        List<String> nomesFotos = List<String>.from(p['fotos_nomes']);
        String obs = p['obs'].text.replaceAll(';', ',').replaceAll('\n', ' '); 

        if (nomesFotos.isEmpty) {
          csvBuffer.writeln('$serie;$req;$modelo;${p['nome']};;$obs');
        } else {
          for (var nome in nomesFotos) {
            csvBuffer.writeln('$serie;$req;$modelo;${p['nome']};imagens/${serie}_$nome;$obs');
          }
        }
      }
    }
    return csvBuffer.toString();
  }

Future<void> _exportarZipComCSV() async {
    if (!_formKey.currentState!.validate()) return;

    // Garante que as fotos obrigatórias estão presentes antes de gerar o pacote
    if (_etiquetaBytes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, anexe a foto da etiqueta.')),
      );
      return;
    }
    if (_kitCompletoBytes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, anexe a foto do kit completo.')),
      );
      return;
    }

    final String serie = _numeroSerieController.text;
    var encoder = Archive();

    // 1. 📊 Gera o conteúdo do CSV e adiciona na raiz do ZIP
    String csvString = _gerarConteudoCSV();
    List<int> csvBytes = utf8.encode(csvString);
    encoder.addFile(ArchiveFile('obs.csv', csvBytes.length, csvBytes));

    // 2. 🖼️ Adiciona as fotos da Etiqueta
    for (int i = 0; i < _etiquetaNomes.length; i++) {
      encoder.addFile(
        ArchiveFile(
          'imagens/${serie}_etiqueta_${_etiquetaNomes[i]}',
          _etiquetaBytes[i].length,
          _etiquetaBytes[i],
        ),
      );
    }

    // 3. 🖼️ Adiciona as fotos do Kit Completo
    for (int i = 0; i < _kitCompletoNomes.length; i++) {
      encoder.addFile(
        ArchiveFile(
          'imagens/${serie}_kit_${_kitCompletoNomes[i]}',
          _kitCompletoBytes[i].length,
          _kitCompletoBytes[i],
        ),
      );
    }

    // 4. 🖼️ Adiciona as fotos dos Periféricos ativos
    for (var p in _perifericos) {
      if (p['possui'] == true) {
        List<String> nomes = p['fotos_nomes'] as List<String>;
        List<List<int>> bytesList = p['fotos_bytes'] as List<List<int>>;
        for (int i = 0; i < nomes.length; i++) {
          String nomeArquivo = "${serie}_${nomes[i]}";
          encoder.addFile(
            ArchiveFile(
              'imagens/$nomeArquivo',
              bytesList[i].length,
              bytesList[i],
            ),
          );
        }
      }
    }

    // 📦 Codifica tudo em um arquivo ZIP físico temporário
    List<int> zipData = ZipEncoder().encode(encoder);
    String nomeArquivoZip = "fotos_e_relatorio_$serie.zip";

    if (kIsWeb) {
      // Fluxo Web: Download direto do arquivo ZIP no navegador
      final blob = html.Blob([zipData], 'application/zip');
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute("download", nomeArquivoZip)
        ..click();
      html.Url.revokeObjectUrl(url);
    } else {
      // Fluxo Mobile: Salva temporariamente e abre a folha de compartilhamento nativo
      final directory = await getTemporaryDirectory();
      final stringPath = '${directory.path}/$nomeArquivoZip';
      final file = io.File(stringPath);
      await file.writeAsBytes(zipData);

      if (!mounted) return;

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(stringPath)],
          subject: 'Relatório e Fotos - Terminal $serie',
          text: 'Seguem em anexo as fotos e o relatório de vistoria do terminal $serie.',
        ),
      );
    }
  }
  // --- PROCESSAMENTO PRINCIPAL COM REGRAS DE COMPARTILHAMENTO HIBRIDO ---
  Future<void> _processarEEnviar() async {
    if (!_formKey.currentState!.validate()) return;

    if (_etiquetaBytes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, anexe a foto da etiqueta.')),
      );
      return;
    }
    if (_kitCompletoBytes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, anexe a foto do kit completo.'),
        ),
      );
      return;
    }

    for (var p in _perifericos) {
      if (p['possui'] == true) {
        if ((p['fotos_bytes'] as List).isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Anexe pelo menos uma foto de: ${p['nome']}'),
            ),
          );
          return;
        }
        if (p['nome'] == 'Pinpad' && p['modelo'] == null) return;
        if (p['nome'] == 'Leitor Biometrico' && p['minex_iii'] == null) return;
      }
    }

    Map<String, dynamic> dadosFormulario = {
      "data_registro": DateTime.now().toIso8601String(),
      "numero_serie": int.parse(_numeroSerieController.text),
      "numero_req": _numeroReqController.text.trim().isNotEmpty
          ? _numeroReqController.text.trim()
          : null,
      "modelo_terminal": _modeloSelecionado,
      "fotos_etiqueta": _etiquetaNomes
          .map(
            (nome) => "imagens/${_numeroSerieController.text}_etiqueta_$nome",
          )
          .toList(),
      "fotos_kit_completo": _kitCompletoNomes
          .map((nome) => "imagens/${_numeroSerieController.text}_kit_$nome")
          .toList(),
      "perifericos": _perifericos.map((p) {
        Map<String, dynamic> info = {"nome": p['nome'], "possui": p['possui']};
        if (p['possui'] == true) {
          info["observacoes"] = p['obs'].text;
          List<String> nomes = p['fotos_nomes'] as List<String>;
          info["caminhos_fotos"] = nomes
              .map((nome) => "imagens/${_numeroSerieController.text}_$nome")
              .toList();
          if (p['nome'] == 'Pinpad') info["modelo_especifico"] = p['modelo'];
          if (p['nome'] == 'Leitor Biometrico') {
            info["minex_iii"] = p['minex_iii'];
          }
        }
        return info;
      }).toList(),
    };

    String jsonString = const JsonEncoder.withIndent(
      '  ',
    ).convert(dadosFormulario);

    var encoder = Archive();
    List<int> jsonBytes = utf8.encode(jsonString);
    encoder.addFile(ArchiveFile('dados.json', jsonBytes.length, jsonBytes));

    String csvString = _gerarConteudoCSV();
    List<int> csvBytes = utf8.encode(csvString);
    encoder.addFile(ArchiveFile('obs.csv', csvBytes.length, csvBytes));

    for (int i = 0; i < _etiquetaNomes.length; i++) {
      encoder.addFile(
        ArchiveFile(
          'imagens/${_numeroSerieController.text}_etiqueta_${_etiquetaNomes[i]}',
          _etiquetaBytes[i].length,
          _etiquetaBytes[i],
        ),
      );
    }

    for (int i = 0; i < _kitCompletoNomes.length; i++) {
      encoder.addFile(
        ArchiveFile(
          'imagens/${_numeroSerieController.text}_kit_${_kitCompletoNomes[i]}',
          _kitCompletoBytes[i].length,
          _kitCompletoBytes[i],
        ),
      );
    }

    for (var p in _perifericos) {
      if (p['possui'] == true) {
        List<String> nomes = p['fotos_nomes'] as List<String>;
        List<List<int>> bytesList = p['fotos_bytes'] as List<List<int>>;
        for (int i = 0; i < nomes.length; i++) {
          String nomeArquivo = "${_numeroSerieController.text}_${nomes[i]}";
          encoder.addFile(
            ArchiveFile(
              'imagens/$nomeArquivo',
              bytesList[i].length,
              bytesList[i],
            ),
          );
        }
      }
    }

    List<int> zipData = ZipEncoder().encode(encoder);

    String nomeArquivoZip = "recebimento_${_numeroSerieController.text}.zip";

    const String emailDestinopadrao = "ciaussp07@caixa.gov.br";
    final String assuntoPadrao =
        "Vistoria Tecnica - TFL Serial: ${_numeroSerieController.text}";
    final String reqDigitada = _numeroReqController.text.trim();
    final String linhaCorpoReq = reqDigitada.isNotEmpty
        ? "REQ: $reqDigitada\n\n"
        : "";
    final String corpoMensagemBase =
        "Ola,\n\n"
        "A vistoria de recebimento técnico do terminal de numero de serie ${_numeroSerieController.text} (Modelo: $_modeloSelecionado) foi concluida.\n\n"
        "$linhaCorpoReq" // <--- A linha da REQ entra magicamente aqui (apenas se não for vazia)
        "Os dados brutos e fotos comprimidas seguem empacotados no arquivo: $nomeArquivoZip.\n\n"
        "Att,\n"
        "Equipe de Triagem em Campo.";

    if (kIsWeb) {
      final blob = html.Blob([zipData], 'application/zip');
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute("download", nomeArquivoZip)
        ..click();
      html.Url.revokeObjectUrl(url);

      _mostrarAvisoAnexoWeb(nomeArquivoZip, () async {
        final Uri emailUri = Uri.parse(
          "mailto:$emailDestinopadrao"
          "?subject=${Uri.encodeComponent(assuntoPadrao)}"
          "&body=${Uri.encodeComponent(corpoMensagemBase)}",
        );
        if (await canLaunchUrl(emailUri)) {
          await launchUrl(emailUri);
        }
      });
    } else {
      // 1. Salva o arquivo ZIP na memoria temporaria do celular
      final directory = await getTemporaryDirectory();
      final stringPath = '${directory.path}/$nomeArquivoZip';

      final file = io.File(stringPath);
      await file.writeAsBytes(zipData);

      // 2. Cria a estrutura direcionada estritamente para o App de E-mail
      final Email email = Email(
        body: corpoMensagemBase,
        subject: assuntoPadrao,
        recipients: [
          emailDestinopadrao,
        ], // <--- O destinatario fixo entra aqui!
        attachmentPaths: [stringPath], // <--- O arquivo ZIP entra preso aqui!
        isHTML: false,
      );

      try {
        // 3. Dispara diretamente o Gmail/Outlook com tudo preenchido
        await FlutterEmailSender.send(email);
      } catch (error) {
        if (!mounted) return;
        // Caso ocorra falha (ex: celular sem nenhum app de e-mail configurado), usa o plano B
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Erro ao abrir app de e-mail. Usando compartilhamento padrao...',
            ),
          ),
        );
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(stringPath)],
            subject: assuntoPadrao,
            text: corpoMensagemBase,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recebimento Técnico de Terminais'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Dados do Terminal',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo,
                  ),
                ),
                const Divider(),
                const SizedBox(height: 10),

                TextFormField(
                  controller: _numeroSerieController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Numero de Serie (Apenas Numeros) *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.pin),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty){
                      return 'Campo obrigatorio';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _numeroReqController,
                  keyboardType: TextInputType
                      .text, // Permite letras e números se necessário
                  decoration: const InputDecoration(
                    labelText: 'Número de REQ',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(
                      Icons.receipt_long,
                    ), // Ícone bonitinho de relatório/recibo
                  ),
                  validator: (value) => null,
                ),
                const SizedBox(height: 15),
                DropdownButtonFormField<String>(
                  initialValue: _modeloSelecionado,
                  decoration: const InputDecoration(
                    labelText: 'Modelo do Terminal *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.devices),
                  ),
                  items: _modelosDisponiveis
                      .map(
                        (model) =>
                            DropdownMenuItem(value: model, child: Text(model)),
                      )
                      .toList(),
                  onChanged: (val) => setState(() => _modeloSelecionado = val),
                  validator: (value) =>
                      value == null ? 'Selecione um modelo' : null,
                ),

                const SizedBox(height: 20),

                // --- GERENCIAMENTO DE FOTOS: ETIQUETA ---
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _abrirSeletorFotoPrincipal(true),
                      icon: const Icon(Icons.qr_code),
                      label: const Text('Foto Etiqueta *'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[200],
                        foregroundColor: Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Text(
                        _etiquetaNomes.isEmpty
                            ? 'Nenhuma foto da etiqueta (Sem anexo)'
                            : '${_etiquetaNomes.length} foto(s) da etiqueta',
                        style: TextStyle(
                          color: _etiquetaBytes.isNotEmpty
                              ? Colors.green
                              : Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                _buildGerenciadorFotos(
                  nomes: _etiquetaNomes,
                  bytesList: _etiquetaBytes,
                  onRemoverTodas: () {
                    setState(() {
                      _etiquetaNomes.clear();
                      _etiquetaBytes.clear();
                    });
                  },
                  onRemoverUnica: (idx) {
                    setState(() {
                      _etiquetaNomes.removeAt(idx);
                      _etiquetaBytes.removeAt(idx);
                    });
                  },
                ),
                const SizedBox(height: 15),

                // --- GERENCIAMENTO DE FOTOS: KIT COMPLETO ---
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _abrirSeletorFotoPrincipal(false),
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Foto Kit Completo *'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[200],
                        foregroundColor: Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Text(
                        _kitCompletoNomes.isEmpty
                            ? 'Nenhuma foto do kit completo (Sem anexo)'
                            : '${_kitCompletoNomes.length} foto(s) do kit',
                        style: TextStyle(
                          color: _kitCompletoBytes.isNotEmpty
                              ? Colors.green
                              : Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                _buildGerenciadorFotos(
                  nomes: _kitCompletoNomes,
                  bytesList: _kitCompletoBytes,
                  onRemoverTodas: () {
                    setState(() {
                      _kitCompletoNomes.clear();
                      _kitCompletoBytes.clear();
                    });
                  },
                  onRemoverUnica: (idx) {
                    setState(() {
                      _kitCompletoNomes.removeAt(idx);
                      _kitCompletoBytes.removeAt(idx);
                    });
                  },
                ),

                const SizedBox(height: 35),
                const Text(
                  'Peças e Periféricos',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo,
                  ),
                ),
                const Divider(),

                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _perifericos.length,
                  itemBuilder: (context, index) {
                    final peri = _perifericos[index];

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SwitchListTile(
                              title: Text(
                                peri['nome'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                              subtitle: Text(
                                peri['possui']
                                    ? 'Status: Possui'
                                    : 'Status: Nao possui',
                              ),
                              value: peri['possui'],
                              activeThumbColor: Colors.indigo,
                              onChanged: (bool value) {
                                setState(() {
                                  peri['possui'] = value;
                                  if (!value) {
                                    peri['obs'].clear();
                                    peri['fotos_nomes'] = <String>[];
                                    peri['fotos_bytes'] = <List<int>>[];
                                    if (peri.containsKey('modelo')){
                                      peri['modelo'] = null;
                                    }
                                    if (peri.containsKey('minex_iii')){
                                      peri['minex_iii'] = null;
                                    }
                                  }
                                });
                              },
                            ),

                            if (peri['possui'] == true) ...[
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                child: Divider(height: 1),
                              ),
                              const SizedBox(height: 12),

                              if (peri['nome'] == 'Pinpad') ...[
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 5,
                                  ),
                                  child: DropdownButtonFormField<String>(
                                    initialValue: peri['modelo'],
                                    decoration: const InputDecoration(
                                      labelText: 'Modelo do Pinpad *',
                                      border: OutlineInputBorder(),
                                    ),
                                    items: _modelosPinpad
                                        .map(
                                          (m) => DropdownMenuItem(
                                            value: m,
                                            child: Text(m),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (val) =>
                                        setState(() => peri['modelo'] = val),
                                  ),
                                ),
                                const SizedBox(height: 10),
                              ],

                              if (peri['nome'] == 'Leitor Biometrico') ...[
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  child: Row(
                                    children: [
                                      const Text(
                                        'E padrao MINEX III? * ',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      ChoiceChip(
                                        label: const Text('Sim'),
                                        selected: peri['minex_iii'] == true,
                                        onSelected: (val) => setState(
                                          () => peri['minex_iii'] = true,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      ChoiceChip(
                                        label: const Text('Não'),
                                        selected: peri['minex_iii'] == false,
                                        onSelected: (val) => setState(
                                          () => peri['minex_iii'] = false,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 15),
                              ],

                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: TextFormField(
                                  controller: peri['obs'],
                                  // Ativa a expansão dinâmica:
                                  minLines:
                                      1, // Começa bonitinho ocupando apenas 1 linha
                                  maxLines:
                                      5, // Cresce de forma fluida até o limite de 5 linhas (parágrafos)
                                  keyboardType: TextInputType
                                      .multiline, // Permite que a tecla "Enter" quebre a linha no teclado do celular
                                  decoration: const InputDecoration(
                                    labelText: 'Observacoes da peça/periférico',
                                    border: OutlineInputBorder(),
                                    alignLabelWithHint:
                                        true, // Garante que o texto de dica/rótulo comece no topo quando o campo expandir
                                  ),
                                ),
                              ),

                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: Row(
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: () => _abrirSeletorFoto(index),
                                      icon: const Icon(Icons.camera_alt),
                                      label: const Text('Anexar Fotos *'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.grey[200],
                                        foregroundColor: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(width: 15),
                                    Expanded(
                                      child: Text(
                                        (peri['fotos_nomes'] as List).isEmpty
                                            ? 'Nenhuma foto anexada (Falta anexo)'
                                            : '${(peri['fotos_nomes'] as List).length} foto(s) selecionada(s)',
                                        style: TextStyle(
                                          color:
                                              (peri['fotos_bytes'] as List)
                                                  .isNotEmpty
                                              ? Colors.green
                                              : Colors.red,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // --- GERENCIAMENTO DE FOTOS: PERIFÉRICOS ---
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: _buildGerenciadorFotos(
                                  nomes: List<String>.from(peri['fotos_nomes']),
                                  bytesList: List<List<int>>.from(peri['fotos_bytes']),
                                  onRemoverTodas: () {
                                    setState(() {
                                      peri['fotos_nomes'] = <String>[];
                                      peri['fotos_bytes'] = <List<int>>[];
                                    });
                                  },
                                  onRemoverUnica: (idx) {
                                    setState(() {
                                      (peri['fotos_nomes'] as List).removeAt(idx);
                                      (peri['fotos_bytes'] as List).removeAt(idx);
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(height: 10),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 30),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _processarEEnviar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      'Compactar dados e enviar e-mail',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Novo Botão: Apenas o relatório CSV
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _exportarZipComCSV,
                    icon: const Icon(Icons.table_chart, color: Colors.green),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.green, width: 2),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    label: const Text(
                      'Exportar Relatório',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}