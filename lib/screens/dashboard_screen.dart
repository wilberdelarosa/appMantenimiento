import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/data_service.dart';
import '../models/mantenimiento.dart';
import '../models/equipo.dart';
import '../utils/app_theme.dart';
import '../widgets/menu_drawer.dart';
import '../desktop/desktop_layout.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDesktop = !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);

    if (isDesktop) {
      return DesktopLayout(
        title: 'Panel de Control',
        child: _DashboardContent(),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Control'),
      ),
      drawer: const MenuDrawer(),
      body: _DashboardContent(),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final dataService = Provider.of<DataService>(context);
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 1200;

    // Obtener todos los mantenimientos programados activos
    final mantenimientosProgramados = dataService.mantenimientosProgramados.where((m) => m.activo).toList();

    // Filtrar mantenimientos pendientes (Vencidos o Próximos)
    final mantenimientosPendientes = mantenimientosProgramados
        .where((m) => m.status == MantenimientoStatus.Vencido || m.status == MantenimientoStatus.Proximo)
        .toList();

    // Ordenar para mostrar vencidos primero, luego por urgencia
    mantenimientosPendientes.sort((a, b) {
      if (a.status == MantenimientoStatus.Vencido && b.status != MantenimientoStatus.Vencido) return -1;
      if (a.status != MantenimientoStatus.Vencido && b.status == MantenimientoStatus.Vencido) return 1;
      return (a.horasKmRestante ?? double.maxFinite).compareTo(b.horasKmRestante ?? double.maxFinite);
    });

    // Calcular estadísticas
    final totalEquipos = dataService.equipos.length;
    final equiposActivos = dataService.equipos.where((e) => e.activo).length;
    final totalMantenimientos = dataService.mantenimientosRealizados.length;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isSmallScreen ? 16.0 : 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resumen General',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Tarjetas de estadísticas
          _buildStatsCards(context, totalEquipos, equiposActivos, totalMantenimientos, mantenimientosPendientes.length),

          const SizedBox(height: 24),

          // Sección de mantenimientos pendientes
          Text(
            'Mantenimientos Pendientes',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.warning,
            ),
          ),
          const SizedBox(height: 8),

          // Mostrar TODOS los mantenimientos pendientes
          mantenimientosPendientes.isEmpty
              ? _buildEmptyState('No hay mantenimientos pendientes')
              : Column(
            children: mantenimientosPendientes
                .map((m) => _buildMantenimientoCard(context, m, dataService))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards(BuildContext context, int totalEquipos, int equiposActivos, int totalMantenimientos, int mantenimientosPendientes) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;
    final isMediumScreen = screenSize.width >= 600 && screenSize.width < 1200;

    if (isSmallScreen) {
      // Diseño para pantallas pequeñas (móviles)
      return Column(
        children: [
          _buildStatCard(context, 'Total Equipos', totalEquipos.toString(), Icons.construction, AppColors.primaryYellow),
          const SizedBox(height: 8),
          _buildStatCard(context, 'Equipos Activos', equiposActivos.toString(), Icons.check_circle, AppColors.success),
          const SizedBox(height: 8),
          _buildStatCard(context, 'Mantenimientos Realizados', totalMantenimientos.toString(), Icons.build, AppColors.info),
          const SizedBox(height: 8),
          _buildStatCard(context, 'Mantenimientos Pendientes', mantenimientosPendientes.toString(), Icons.warning, AppColors.warning),
        ],
      );
    } else if (isMediumScreen) {
      // Diseño para pantallas medianas (tablets)
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildStatCard(context, 'Total Equipos', totalEquipos.toString(), Icons.construction, AppColors.primaryYellow)),
              const SizedBox(width: 8),
              Expanded(child: _buildStatCard(context, 'Equipos Activos', equiposActivos.toString(), Icons.check_circle, AppColors.success)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _buildStatCard(context, 'Mantenimientos Realizados', totalMantenimientos.toString(), Icons.build, AppColors.info)),
              const SizedBox(width: 8),
              Expanded(child: _buildStatCard(context, 'Mantenimientos Pendientes', mantenimientosPendientes.toString(), Icons.warning, AppColors.warning)),
            ],
          ),
        ],
      );
    } else {
      // Diseño para pantallas grandes (escritorio)
      return Row(
        children: [
          Expanded(child: _buildStatCard(context, 'Total Equipos', totalEquipos.toString(), Icons.construction, AppColors.primaryYellow)),
          const SizedBox(width: 16),
          Expanded(child: _buildStatCard(context, 'Equipos Activos', equiposActivos.toString(), Icons.check_circle, AppColors.success)),
          const SizedBox(width: 16),
          Expanded(child: _buildStatCard(context, 'Mantenimientos Realizados', totalMantenimientos.toString(), Icons.build, AppColors.info)),
          const SizedBox(width: 16),
          Expanded(child: _buildStatCard(context, 'Mantenimientos Pendientes', mantenimientosPendientes.toString(), Icons.warning, AppColors.warning)),
        ],
      );
    }
  }

  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 24,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMantenimientoCard(BuildContext context, MantenimientoProgramado mantenimiento, DataService dataService) {
    final equipo = dataService.obtenerEquipoPorFicha(mantenimiento.ficha);
    final status = mantenimiento.status;
    final statusInfo = _getStatusInfo(status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: statusInfo['color']!,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: statusInfo['color']!.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    statusInfo['icon']!,
                    color: statusInfo['color']!,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        equipo?.nombre ?? 'Equipo desconocido',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Ficha: ${mantenimiento.ficha}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusInfo['color']!.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    statusInfo['text']!,
                    style: TextStyle(
                      color: statusInfo['color']!,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            _buildInfoRow('Tipo de Mantenimiento:', mantenimiento.tipoMantenimiento),
            _buildInfoRow('Valor Actual:', '${mantenimiento.horasKmActuales.toStringAsFixed(1)} ${mantenimiento.tipoMantenimiento}'),
            _buildInfoRow('Próximo Mantenimiento:', '${mantenimiento.proximoMantenimiento?.toStringAsFixed(1) ?? 'N/A'} ${mantenimiento.tipoMantenimiento}'),
            _buildInfoRow(
              'Restante:',
              '${mantenimiento.horasKmRestante?.toStringAsFixed(1) ?? 'N/A'} ${mantenimiento.tipoMantenimiento}',
              highlight: true,
              highlightColor: statusInfo['color']!,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.build),
                  label: const Text('Realizar'),
                  onPressed: () {
                    // Navegar a la pantalla de realizar mantenimiento
                    Navigator.pushNamed(
                      context,
                      '/realizar-mantenimiento',
                      arguments: {
                        'ficha': mantenimiento.ficha,
                        'idMantenimiento': mantenimiento.id,
                      },
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryYellow,
                    side: BorderSide(color: AppColors.primaryYellow),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _getStatusInfo(MantenimientoStatus status) {
    switch (status) {
      case MantenimientoStatus.Vencido:
        return {'text': 'Vencido', 'color': AppColors.error, 'icon': Icons.error};
      case MantenimientoStatus.Proximo:
        return {'text': 'Próximo', 'color': AppColors.warning, 'icon': Icons.warning_amber};
      case MantenimientoStatus.AlDia:
        return {'text': 'Al Día', 'color': AppColors.success, 'icon': Icons.check_circle};
      default:
        return {'text': 'No Calculado', 'color': Colors.grey, 'icon': Icons.help_outline};
    }
  }

  Widget _buildInfoRow(String label, String value, {bool highlight = false, Color highlightColor = Colors.black}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(
            value,
            style: TextStyle(
              fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
              color: highlight ? highlightColor : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      padding: const EdgeInsets.all(24),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
