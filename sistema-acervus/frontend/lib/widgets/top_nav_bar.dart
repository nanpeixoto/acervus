import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

const _primary = Color(0xFF82265C);
const _lightBg = Color(0xFFF7F3FA);

class TopNavBar extends StatelessWidget {
  const TopNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 900;

        return Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              // LOGO
              Image.asset(
                'assets/images/logo-cide.png',
                height: 40,
              ),
              const SizedBox(width: 16),

              if (!isMobile)
                const Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _MenuLink(text: 'ESTUDANTE', route: '/login/candidato/2'),
                      SizedBox(width: 24),
                      _MenuLink(text: 'JOVEM APRENDIZ', route: '/login/candidato/1'),
                      SizedBox(width: 24),
                      _MenuLink(text: 'EMPRESA', route: '/login/empresa'),
                      SizedBox(width: 24),
                      _MenuLink(text: 'INSTITUIÇÃO', route: '/login/instituicao'),
                    ],
                  ),
                )
              else
                const Spacer(),

              // Login
              ElevatedButton.icon(
                onPressed: () => context.go('/login'),
                icon: const Icon(Icons.login, size: 16),
                label: const Text('Login'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2F3C45),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  elevation: 0,
                ),
              ),

              if (isMobile) ...[
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.menu),
                  onSelected: (value) => context.go(value),
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: '/login/candidato/2', child: Text('ESTUDANTE')),
                    PopupMenuItem(value: '/login/candidato/1', child: Text('JOVEM APRENDIZ')),
                    PopupMenuItem(value: '/login/empresa', child: Text('EMPRESA')),
                    PopupMenuItem(value: '/login/instituicao', child: Text('INSTITUIÇÃO')),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _MenuLink extends StatefulWidget {
  final String text;
  final String route;
  const _MenuLink({required this.text, required this.route});

  @override
  State<_MenuLink> createState() => _MenuLinkState();
}

class _MenuLinkState extends State<_MenuLink> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => context.go(widget.route),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            border: _hover
                ? const Border(bottom: BorderSide(color: _primary, width: 2))
                : null,
          ),
          child: Text(
            widget.text,
            style: TextStyle(
              color: _hover ? _primary : Colors.black87,
              fontWeight: _hover ? FontWeight.w700 : FontWeight.w500,
              fontSize: 15,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
    );
  }
}
