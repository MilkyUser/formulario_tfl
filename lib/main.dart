import 'package:flutter/material.dart';
import 'package:formulario_tfl/recebimento_terminal_screen.dart';
// Importa a tela que criamos! (Se o nome do seu projeto for diferente de 'local_mail_app', altere aqui)

void main() {
  runApp(const MeuAppMailer());
}

class MeuAppMailer extends StatelessWidget {
  const MeuAppMailer({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mailer App',
      debugShowCheckedModeBanner: false, // Remove a faixinha de debug do canto
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey),
      ),
      // Define a nossa tela de formulário como a página inicial
      home: const RecebimentoTerminalScreen(),
    );
  }
}