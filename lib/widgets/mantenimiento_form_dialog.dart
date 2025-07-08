import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../services/data_service.dart';
import '../utils/app_theme.dart';
import '../models/mantenimiento.dart';
import '../models/inventario.dart';
import '../models/equipo.dart';

Future<void> showMantenimientoFormDialog(BuildContext context, MantenimientoProgramado mantenimiento) async {
  final formKey = GlobalKey<FormState>();
  final TextEditingController horasKmController = TextEditingController(
    text: mantenimiento.horasKmActuales.toString(),
  );
  final TextEditingController observacionesController = TextEditingController();
  final TextEditingController empleadoManualController = TextEditingController();
  int? selectedEmpleadoId;
  final List<FiltroUtilizado> filtrosSeleccionados = [];
  DateTime fechaMantenimiento = DateTime.now();

  return showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        return AlertDialog(
          title: const Text('Registrar Mantenimiento'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ficha: ${mantenimiento.ficha}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text('Equipo: ${mantenimiento.nombreEquipo}'),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: horasKmController,
                    decoration: InputDecoration(
                      labelText: '${mantenimiento.tipoMantenimiento} al momento',
                      suffixText: mantenimiento.tipoMantenimiento == 'Horas' ? 'hr' : 'km',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingrese las ${mantenimiento.tipoMantenimiento.toLowerCase()}';
                      }
                      final numero = double.tryParse(value);
                      if (numero == null || numero < 0) {
                        return 'Ingrese un número válido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    title: const Text('Fecha de Mantenimiento'),
                    subtitle: Text(
                      DateFormat('dd/MM/yyyy').format(fechaMantenimiento),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: () async {
                        final fecha = await showDatePicker(
                          context: context,
                          initialDate: fechaMantenimiento,
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                        );
                        if (fecha != null) {
                          setState(() {
                            fechaMantenimiento = fecha;
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  Consumer<DataService>(
                    builder: (context, dataService, child) {
                      final empleados = dataService.empleados.where((e) => e.activo).toList();

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Empleado que realizó el mantenimiento'),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<int?>(
                            value: selectedEmpleadoId,
                            decoration: const InputDecoration(
                              labelText: 'Seleccionar empleado',
                              border: OutlineInputBorder(),
                            ),
                            items: [
                              const DropdownMenuItem<int?>(
                                value: null,
                                child: Text('Sin empleado'),
                              ),
                              ...empleados.map((empleado) {
                                return DropdownMenuItem<int?>(
                                  value: empleado.id,
                                  child: Text('${empleado.nombreCompleto} (${empleado.categoria})'),
                                );
                              }).toList(),
                            ],
                            onChanged: (value) {
                              setState(() {
                                selectedEmpleadoId = value;
                                if (value != null) {
                                  empleadoManualController.text = '';
                                }
                              });
                            },
                          ),
                          const SizedBox(height: 8),
                          const Text('O ingrese manualmente:'),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: empleadoManualController,
                            decoration: const InputDecoration(
                              labelText: 'Nombre del empleado o empresa',
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (value) {
                              if (value.isNotEmpty) {
                                setState(() {
                                  selectedEmpleadoId = null;
                                });
                              }
                            },
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Filtros utilizados:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Consumer<DataService>(
                    builder: (context, dataService, child) {
                      final equipo = dataService.obtenerEquipoPorFicha(mantenimiento.ficha);
                      if (equipo == null) {
                        return const Text('No se encontró el equipo');
                      }

                      final filtrosDisponibles = dataService.inventarios
                          .where((i) => i.activo && i.categoriaEquipo == equipo.categoria)
                          .toList();

                      if (filtrosDisponibles.isEmpty) {
                        return const Text('No hay filtros disponibles para este equipo');
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (filtrosSeleccionados.isNotEmpty) ...[
                            Card(
                              color: AppColors.primaryYellow.withAlpha(30),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Filtros seleccionados:',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 8),
                                    ...filtrosSeleccionados.map((filtro) {
                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 4.0),
                                        child: Row(
                                          children: [
                                            Text('${filtro.nombre}: ${filtro.cantidad}'),
                                            const Spacer(),
                                            IconButton(
                                              icon: const Icon(Icons.delete_outline, size: 18),
                                              onPressed: () {
                                                setState(() {
                                                  filtrosSeleccionados.removeWhere((f) => f.idInventario == filtro.idInventario);
                                                });
                                              },
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                          DropdownButtonFormField<int>(
                            decoration: const InputDecoration(
                              labelText: 'Agregar filtro',
                              border: OutlineInputBorder(),
                            ),
                            items: filtrosDisponibles.map((filtro) {
                              return DropdownMenuItem<int>(
                                value: filtro.id!,
                                child: Text('${filtro.nombre} (Disponible: ${filtro.cantidad})'),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                final filtro = filtrosDisponibles.firstWhere((f) => f.id == value);
                                final existente = filtrosSeleccionados.indexWhere((f) => f.idInventario == value);
                                if (existente == -1 && filtro.cantidad > 0) {
                                  setState(() {
                                    filtrosSeleccionados.add(
                                      FiltroUtilizado(
                                        idInventario: filtro.id!,
                                        nombre: filtro.nombre,
                                        cantidad: 1,
                                      ),
                                    );
                                  });
                                }
                              }
                            },
                          ),
                          const SizedBox(height: 16),
                          ...filtrosSeleccionados.map((filtro) {
                            final inventario = filtrosDisponibles.firstWhere(
                              (i) => i.id == filtro.idInventario,
                              orElse: () => Inventario(
                                id: filtro.idInventario,
                                nombre: filtro.nombre,
                                tipo: 'Desconocido',
                                categoriaEquipo: equipo.categoria,
                                cantidad: 0,
                              ),
                            );
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: Text(filtro.nombre),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.remove),
                                    onPressed: filtro.cantidad > 1
                                        ? () {
                                            setState(() {
                                              filtro.cantidad--;
                                            });
                                          }
                                        : null,
                                  ),
                                  Text(
                                    filtro.cantidad.toString(),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add),
                                    onPressed: filtro.cantidad < inventario.cantidad
                                        ? () {
                                            setState(() {
                                              filtro.cantidad++;
                                            });
                                          }
                                        : null,
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: observacionesController,
                    decoration: const InputDecoration(
                      labelText: 'Observaciones',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final dataService = Provider.of<DataService>(context, listen: false);

                  int empleadoId = -1;
                  if (selectedEmpleadoId != null) {
                    empleadoId = selectedEmpleadoId!;
                  } else if (empleadoManualController.text.isNotEmpty) {
                    empleadoId = -1;
                  }

                  final mantenimientoRealizado = MantenimientoRealizado(
                    ficha: mantenimiento.ficha,
                    fechaMantenimiento: fechaMantenimiento,
                    horasKmAlMomento: double.parse(horasKmController.text),
                    idEmpleado: empleadoId,
                    filtrosUtilizados: filtrosSeleccionados,
                    observaciones: observacionesController.text +
                        (empleadoManualController.text.isNotEmpty
                            ? '\nRealizado por: ${empleadoManualController.text}'
                            : ''),
                  );

                  await dataService.agregarMantenimientoRealizado(mantenimientoRealizado);

                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Mantenimiento registrado correctamente'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              },
              child: const Text('Registrar'),
            ),
          ],
        );
      },
    ),
  );
}
