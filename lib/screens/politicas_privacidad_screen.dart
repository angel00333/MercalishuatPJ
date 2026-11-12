import 'package:flutter/material.dart';

import '../config/app_theme.dart';

class PoliticasPrivacidadScreen extends StatelessWidget {
  const PoliticasPrivacidadScreen({
    super.key,
  });

  // ============================================================
  // DATOS GENERALES
  // ============================================================

  static const String versionPolitica =
      'Versión Beta 7.1';

  static const String ultimaActualizacion =
      'Noviembre 2026';

  // ============================================================
  // SECCIONES DE PRIVACIDAD
  // ============================================================

  static const List<_SeccionPrivacidad> secciones = [
    // ==========================================================
    // 1. DATOS DE CUENTA
    // ==========================================================

    _SeccionPrivacidad(
      icono: Icons.person_outline_rounded,
      titulo: '1. Datos de la cuenta',
      descripcion:
          'Mercalishuat recopila información necesaria para crear, autenticar y administrar las cuentas de usuario.',
      puntos: [
        'Nombre del usuario.',
        'Correo electrónico.',
        'Contraseña protegida mediante mecanismos de seguridad.',
        'Rol dentro de la plataforma.',
        'Fotografía de perfil, cuando el usuario decide agregarla.',
        'Identificadores internos necesarios para el funcionamiento de la cuenta.',
      ],
    ),

    // ==========================================================
    // 2. EMPRENDIMIENTOS
    // ==========================================================

    _SeccionPrivacidad(
      icono: Icons.storefront_outlined,
      titulo: '2. Datos de emprendimientos',
      descripcion:
          'Cuando un usuario registra o administra un emprendimiento, Mercalishuat almacena información relacionada con la actividad comercial publicada dentro de la plataforma.',
      puntos: [
        'Nombre comercial.',
        'Descripción del emprendimiento.',
        'Imagen o logotipo.',
        'Información de contacto.',
        'Productos y servicios publicados.',
        'Fotografías comerciales.',
        'Publicaciones del emprendimiento.',
        'Ubicación comercial registrada.',
      ],
    ),

    // ==========================================================
    // 3. GEOLOCALIZACIÓN
    // ==========================================================

    _SeccionPrivacidad(
      icono: Icons.location_on_outlined,
      titulo: '3. Geolocalización',
      descripcion:
          'La ubicación del dispositivo se utiliza únicamente cuando el usuario accede a funciones que requieren conocer su posición aproximada, como la búsqueda de negocios cercanos.',
      puntos: [
        'La ubicación personal no está destinada a realizar seguimiento permanente.',
        'La ubicación puede utilizarse en funciones como "Cerca de mí".',
        'La ubicación comercial de un emprendimiento puede mostrarse públicamente en el mapa.',
        'El usuario puede controlar los permisos de ubicación desde su dispositivo.',
      ],
    ),

    // ==========================================================
    // 4. IMÁGENES
    // ==========================================================

    _SeccionPrivacidad(
      icono: Icons.image_outlined,
      titulo: '4. Fotografías e imágenes',
      descripcion:
          'Mercalishuat permite cargar imágenes necesarias para mostrar perfiles, emprendimientos, productos, publicaciones y locales comerciales.',
      puntos: [
        'Fotografía de perfil.',
        'Imagen o logotipo del emprendimiento.',
        'Fotografías de productos.',
        'Imágenes de publicaciones.',
        'Fotografías de locales comerciales.',
      ],
    ),

    // ==========================================================
    // 5. MENSAJERÍA
    // ==========================================================

    _SeccionPrivacidad(
      icono: Icons.chat_bubble_outline_rounded,
      titulo: '5. Mensajería privada',
      descripcion:
          'Mercalishuat permite conversaciones entre usuarios y emprendimientos. La información necesaria para mantener estas conversaciones se almacena dentro del sistema.',
      puntos: [
        'Participantes de la conversación.',
        'Contenido de los mensajes.',
        'Fecha y hora de envío.',
        'Estado leído o no leído.',
        'Identificador interno de la conversación.',
        'Los mensajes privados no se muestran públicamente.',
      ],
    ),

    // ==========================================================
    // 6. NOTIFICACIONES
    // ==========================================================

    _SeccionPrivacidad(
      icono: Icons.notifications_none_rounded,
      titulo: '6. Notificaciones',
      descripcion:
          'Mercalishuat puede utilizar identificadores técnicos del dispositivo para enviar notificaciones relacionadas con el funcionamiento de la plataforma.',
      puntos: [
        'Avisos de nuevos mensajes.',
        'Actividad relacionada con la cuenta.',
        'Notificaciones relacionadas con emprendimientos.',
        'Avisos importantes del sistema.',
        'Identificadores técnicos necesarios para notificaciones push.',
      ],
    ),

    // ==========================================================
    // 7. PUBLICACIONES
    // ==========================================================

    _SeccionPrivacidad(
      icono: Icons.dynamic_feed_outlined,
      titulo: '7. Publicaciones e interacción',
      descripcion:
          'La información que el usuario o emprendimiento publique voluntariamente puede ser visible para otros usuarios de Mercalishuat.',
      puntos: [
        'Publicaciones.',
        'Descripción de productos.',
        'Información comercial.',
        'Imágenes publicadas.',
        'Contenido asociado a emprendimientos.',
      ],
    ),

    // ==========================================================
    // 8. FINALIDADES
    // ==========================================================

    _SeccionPrivacidad(
      icono: Icons.flag_outlined,
      titulo: '8. Para qué utilizamos los datos',
      descripcion:
          'La información recopilada se utiliza únicamente para operar las funciones de Mercalishuat y mantener la seguridad y funcionamiento de la plataforma.',
      puntos: [
        'Crear y autenticar cuentas.',
        'Mantener sesiones de usuario.',
        'Gestionar perfiles.',
        'Administrar emprendimientos.',
        'Publicar productos y contenido.',
        'Mostrar establecimientos en el mapa.',
        'Encontrar negocios cercanos.',
        'Permitir conversaciones.',
        'Enviar notificaciones.',
        'Administrar y moderar contenido.',
        'Prevenir usos indebidos de la plataforma.',
      ],
    ),

    // ==========================================================
    // 9. PROVEEDORES
    // ==========================================================

    _SeccionPrivacidad(
      icono: Icons.cloud_outlined,
      titulo: '9. Proveedores tecnológicos',
      descripcion:
          'Mercalishuat utiliza servicios tecnológicos externos necesarios para operar diferentes componentes de la plataforma.',
      puntos: [
        'Neon para infraestructura de base de datos PostgreSQL.',
        'Render para servicios de backend y API.',
        'Cloudinary para almacenamiento y distribución de imágenes.',
        'Firebase para servicios relacionados con notificaciones.',
        'Servicios de mapas o cartografía cuando corresponda.',
      ],
    ),

    // ==========================================================
    // 10. PROCESAMIENTO EXTERNO
    // ==========================================================

    _SeccionPrivacidad(
      icono: Icons.public_rounded,
      titulo: '10. Procesamiento mediante servicios externos',
      descripcion:
          'Algunos proveedores tecnológicos utilizados por Mercalishuat pueden utilizar infraestructura ubicada fuera de El Salvador.',
      puntos: [
        'Los datos compartidos con proveedores se limitan a los necesarios para prestar el servicio correspondiente.',
        'Mercalishuat procura utilizar proveedores tecnológicos con medidas razonables de seguridad.',
        'No se publican credenciales, configuraciones internas ni secretos de infraestructura.',
      ],
    ),

    // ==========================================================
    // 11. SEGURIDAD
    // ==========================================================

    _SeccionPrivacidad(
      icono: Icons.security_rounded,
      titulo: '11. Seguridad de la información',
      descripcion:
          'Mercalishuat aplica medidas técnicas destinadas a reducir riesgos de acceso, modificación o utilización no autorizada de la información.',
      puntos: [
        'Protección de contraseñas.',
        'Autenticación de usuarios.',
        'Control de acceso según roles.',
        'Validaciones realizadas desde el backend.',
        'Uso de conexiones seguras en servicios desplegados.',
        'Acceso restringido a los servicios e infraestructura.',
      ],
    ),

    // ==========================================================
    // 12. CONSERVACIÓN
    // ==========================================================

    _SeccionPrivacidad(
      icono: Icons.storage_outlined,
      titulo: '12. Conservación de información',
      descripcion:
          'Mercalishuat conserva la información mientras resulte necesaria para mantener las funciones de la plataforma y las cuentas activas.',
      puntos: [
        'Datos del perfil.',
        'Información de emprendimientos.',
        'Productos.',
        'Publicaciones.',
        'Mensajes.',
        'Imágenes.',
        'Notificaciones.',
        'Registros técnicos necesarios para operar la plataforma.',
      ],
    ),

    // ==========================================================
    // 13. DERECHOS
    // ==========================================================

    _SeccionPrivacidad(
      icono: Icons.manage_accounts_outlined,
      titulo: '13. Derechos sobre los datos personales',
      descripcion:
          'Los usuarios pueden solicitar información o correcciones relacionadas con los datos personales que administran dentro de Mercalishuat.',
      puntos: [
        'Consultar la información de su perfil.',
        'Modificar información personal disponible desde la aplicación.',
        'Corregir datos incorrectos.',
        'Actualizar información asociada a su cuenta.',
        'Solicitar información sobre el tratamiento de sus datos mediante los canales oficiales que Mercalishuat habilite.',
      ],
    ),

    // ==========================================================
    // 14. CONSENTIMIENTO
    // ==========================================================

    _SeccionPrivacidad(
      icono: Icons.fact_check_outlined,
      titulo: '14. Consentimiento y permisos',
      descripcion:
          'Determinadas funciones pueden requerir autorización del usuario o permisos específicos del dispositivo.',
      puntos: [
        'Permiso para utilizar la ubicación.',
        'Permiso para enviar notificaciones cuando corresponda.',
        'Autorización para utilizar fotografías seleccionadas por el usuario.',
        'El usuario puede modificar determinados permisos desde la configuración de su dispositivo.',
      ],
    ),

    // ==========================================================
    // 15. MINIMIZACIÓN
    // ==========================================================

    _SeccionPrivacidad(
      icono: Icons.do_not_disturb_alt_rounded,
      titulo: '15. Datos que no solicitamos innecesariamente',
      descripcion:
          'Mercalishuat busca limitar la recopilación de información a los datos necesarios para proporcionar sus funciones.',
      puntos: [
        'DUI de usuarios normales.',
        'NIT de usuarios normales.',
        'Información bancaria sin una función que lo requiera.',
        'Lista de contactos del teléfono.',
        'Mensajes SMS.',
        'Historial de llamadas.',
        'Ubicación permanente del dispositivo.',
        'Datos biométricos.',
        'Información médica.',
        'Religión.',
        'Opinión política.',
      ],
    ),

    // ==========================================================
    // 16. CAMBIOS Y CONTACTO
    // ==========================================================

    _SeccionPrivacidad(
      icono: Icons.update_rounded,
      titulo: '16. Cambios en esta política',
      descripcion:
          'Esta Política de Privacidad puede actualizarse cuando Mercalishuat incorpore nuevas funciones, cambie sus proveedores tecnológicos o modifique la forma en que procesa información.',
      puntos: [
        'Las modificaciones relevantes podrán comunicarse dentro de la aplicación.',
        'La versión y fecha de actualización se mostrarán en esta pantalla.',
        'Los canales oficiales de contacto sobre privacidad serán publicados cuando estén disponibles.',
      ],
    ),
  ];

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final bool oscuro =
        Theme.of(context).brightness ==
            Brightness.dark;

    final Color fondo =
        Theme.of(context)
            .scaffoldBackgroundColor;

    final Color superficie = oscuro
        ? AppColors.tarjetaOscura
        : Colors.white;

    final Color textoPrincipal = oscuro
        ? AppColors.textoOscuro
        : AppColors.textoClaro;

    final Color textoSecundario = oscuro
        ? AppColors.textoSecundarioOscuro
        : AppColors.textoSecundarioClaro;

    final Color borde = oscuro
        ? AppColors.bordeOscuro
        : AppColors.bordeClaro;

    return Scaffold(
      backgroundColor: fondo,

      // ========================================================
      // APP BAR
      // ========================================================

      appBar: AppBar(
        title: const Text(
          'Política de privacidad',
        ),
      ),

      // ========================================================
      // BODY
      // ========================================================

      body: SafeArea(
        child: SingleChildScrollView(
          padding:
              const EdgeInsets.fromLTRB(
            18,
            18,
            18,
            40,
          ),

          child: Center(
            child: ConstrainedBox(
              constraints:
                  const BoxConstraints(
                maxWidth: 850,
              ),

              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.stretch,

                children: [
                  // =============================================
                  // CABECERA
                  // =============================================

                  const _CabeceraPrivacidad(),

                  const SizedBox(
                    height: 18,
                  ),

                  // =============================================
                  // RESUMEN
                  // =============================================

                  _TarjetaResumen(
                    textoPrincipal:
                        textoPrincipal,

                    textoSecundario:
                        textoSecundario,

                    oscuro:
                        oscuro,
                  ),

                  const SizedBox(
                    height: 24,
                  ),

                  // =============================================
                  // TÍTULO
                  // =============================================

                  Row(
                    children: [
                      const Icon(
                        Icons.shield_outlined,
                        color:
                            AppColors.naranja,
                      ),

                      const SizedBox(
                        width: 10,
                      ),

                      Text(
                        'Cómo protegemos tu información',

                        style:
                            TextStyle(
                          color:
                              textoPrincipal,

                          fontSize:
                              20,

                          fontWeight:
                              FontWeight.w900,

                          fontFamily:
                              'Outfit',
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(
                    height: 14,
                  ),

                  // =============================================
                  // SECCIONES
                  // =============================================

                  ...secciones.map(
                    (
                      seccion,
                    ) {
                      return Padding(
                        padding:
                            const EdgeInsets.only(
                          bottom: 10,
                        ),

                        child:
                            _TarjetaPolitica(
                          seccion:
                              seccion,

                          superficie:
                              superficie,

                          textoPrincipal:
                              textoPrincipal,

                          textoSecundario:
                              textoSecundario,

                          borde:
                              borde,

                          oscuro:
                              oscuro,
                        ),
                      );
                    },
                  ),

                  const SizedBox(
                    height: 16,
                  ),

                  // =============================================
                  // AVISO FINAL
                  // =============================================

                  Container(
                    padding:
                        const EdgeInsets.all(
                      20,
                    ),

                    decoration:
                        BoxDecoration(
                      color:
                          AppColors.morado,

                      borderRadius:
                          BorderRadius.circular(
                        22,
                      ),
                    ),

                    child:
                        Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,

                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons
                                  .contact_support_outlined,

                              color:
                                  Colors.white,
                            ),

                            SizedBox(
                              width: 10,
                            ),

                            Expanded(
                              child:
                                  Text(
                                '¿Tienes una consulta sobre privacidad?',

                                style:
                                    TextStyle(
                                  color:
                                      Colors.white,

                                  fontSize:
                                      17,

                                  fontWeight:
                                      FontWeight.w800,

                                  fontFamily:
                                      'Outfit',
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(
                          height: 10,
                        ),

                        Text(
                          'Mercalishuat habilitará sus canales oficiales para atender consultas relacionadas con privacidad, corrección de información y tratamiento de datos.',

                          style:
                              TextStyle(
                            color:
                                Colors.white
                                    .withValues(
                              alpha:
                                  0.88,
                            ),

                            fontSize:
                                13.5,

                            height:
                                1.45,

                            fontFamily:
                                'Outfit',
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(
                    height: 24,
                  ),

                  // =============================================
                  // VERSIÓN
                  // =============================================

                  Center(
                    child:
                        Column(
                      children: [
                        Text(
                          versionPolitica,

                          style:
                              TextStyle(
                            color:
                                textoSecundario,

                            fontSize:
                                12,

                            fontWeight:
                                FontWeight.w700,

                            fontFamily:
                                'Outfit',
                          ),
                        ),

                        const SizedBox(
                          height: 4,
                        ),

                        Text(
                          'Última actualización: $ultimaActualizacion',

                          textAlign:
                              TextAlign.center,

                          style:
                              TextStyle(
                            color:
                                textoSecundario,

                            fontSize:
                                11.5,

                            fontFamily:
                                'Outfit',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// CABECERA
// ============================================================

class _CabeceraPrivacidad
    extends StatelessWidget {
  const _CabeceraPrivacidad();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.all(
        22,
      ),

      decoration:
          BoxDecoration(
        gradient:
            const LinearGradient(
          begin:
              Alignment.topLeft,

          end:
              Alignment.bottomRight,

          colors: [
            AppColors.naranja,
            AppColors.naranjaClaro,
          ],
        ),

        borderRadius:
            BorderRadius.circular(
          26,
        ),
      ),

      child:
          Stack(
        children: [
          Positioned(
            right: -30,
            top: -40,

            child:
                Container(
              width: 140,
              height: 140,

              decoration:
                  BoxDecoration(
                color:
                    AppColors.morado
                        .withValues(
                  alpha: 0.15,
                ),

                shape:
                    BoxShape.circle,
              ),
            ),
          ),

          const Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [
              _IconoCabecera(),

              SizedBox(
                width: 16,
              ),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [
                    Text(
                      'Tu privacidad\nes importante',

                      style:
                          TextStyle(
                        color:
                            Colors.white,

                        fontSize:
                            24,

                        height:
                            1.05,

                        fontWeight:
                            FontWeight.w900,

                        fontFamily:
                            'Outfit',
                      ),
                    ),

                    SizedBox(
                      height: 10,
                    ),

                    Text(
                      'Conoce qué información utiliza Mercalishuat y cómo es utilizada dentro de la plataforma.',

                      style:
                          TextStyle(
                        color:
                            Colors.white,

                        fontSize:
                            13.5,

                        height:
                            1.4,

                        fontWeight:
                            FontWeight.w500,

                        fontFamily:
                            'Outfit',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================
// ICONO CABECERA
// ============================================================

class _IconoCabecera
    extends StatelessWidget {
  const _IconoCabecera();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 58,
      height: 58,

      decoration:
          BoxDecoration(
        color: Colors.white,

        borderRadius:
            BorderRadius.circular(
          18,
        ),
      ),

      child:
          const Icon(
        Icons.privacy_tip_outlined,

        color:
            AppColors.naranja,

        size: 31,
      ),
    );
  }
}

// ============================================================
// RESUMEN
// ============================================================

class _TarjetaResumen
    extends StatelessWidget {
  final Color textoPrincipal;
  final Color textoSecundario;
  final bool oscuro;

  const _TarjetaResumen({
    required this.textoPrincipal,
    required this.textoSecundario,
    required this.oscuro,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.all(
        18,
      ),

      decoration:
          BoxDecoration(
        color:
            AppColors.naranja
                .withValues(
          alpha:
              oscuro
                  ? 0.14
                  : 0.08,
        ),

        borderRadius:
            BorderRadius.circular(
          20,
        ),

        border:
            Border.all(
          color:
              AppColors.naranja
                  .withValues(
            alpha: 0.25,
          ),
        ),
      ),

      child:
          Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          Container(
            width: 42,
            height: 42,

            decoration:
                BoxDecoration(
              color:
                  AppColors.naranja,

              borderRadius:
                  BorderRadius.circular(
                14,
              ),
            ),

            child:
                const Icon(
              Icons
                  .verified_user_outlined,

              color:
                  Colors.white,
            ),
          ),

          const SizedBox(
            width: 14,
          ),

          Expanded(
            child:
                Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                Text(
                  'Privacidad en Mercalishuat',

                  style:
                      TextStyle(
                    color:
                        textoPrincipal,

                    fontSize:
                        16,

                    fontWeight:
                        FontWeight.w800,

                    fontFamily:
                        'Outfit',
                  ),
                ),

                const SizedBox(
                  height: 5,
                ),

                Text(
                  'Recopilamos únicamente la información necesaria para operar las funciones actuales de la plataforma.',

                  style:
                      TextStyle(
                    color:
                        textoSecundario,

                    fontSize:
                        13.5,

                    height:
                        1.4,

                    fontFamily:
                        'Outfit',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// TARJETA DE POLÍTICA
// ============================================================

class _TarjetaPolitica
    extends StatelessWidget {
  final _SeccionPrivacidad seccion;

  final Color superficie;
  final Color textoPrincipal;
  final Color textoSecundario;
  final Color borde;
  final bool oscuro;

  const _TarjetaPolitica({
    required this.seccion,
    required this.superficie,
    required this.textoPrincipal,
    required this.textoSecundario,
    required this.borde,
    required this.oscuro,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration:
          BoxDecoration(
        color:
            superficie,

        borderRadius:
            BorderRadius.circular(
          20,
        ),

        border:
            Border.all(
          color:
              borde,
        ),
      ),

      clipBehavior:
          Clip.antiAlias,

      child:
          Theme(
        data:
            Theme.of(context)
                .copyWith(
          dividerColor:
              Colors.transparent,

          splashColor:
              AppColors.naranja
                  .withValues(
            alpha: 0.05,
          ),

          highlightColor:
              Colors.transparent,
        ),

        child:
            ExpansionTile(
          tilePadding:
              const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 5,
          ),

          childrenPadding:
              const EdgeInsets.fromLTRB(
            18,
            0,
            18,
            18,
          ),

          iconColor:
              AppColors.naranja,

          collapsedIconColor:
              textoSecundario,

          leading:
              Container(
            width: 43,
            height: 43,

            decoration:
                BoxDecoration(
              color:
                  AppColors.naranja
                      .withValues(
                alpha:
                    oscuro
                        ? 0.16
                        : 0.09,
              ),

              borderRadius:
                  BorderRadius.circular(
                13,
              ),
            ),

            child:
                Icon(
              seccion.icono,

              color:
                  AppColors.naranja,

              size: 22,
            ),
          ),

          title:
              Text(
            seccion.titulo,

            style:
                TextStyle(
              color:
                  textoPrincipal,

              fontSize:
                  14.5,

              fontWeight:
                  FontWeight.w800,

              fontFamily:
                  'Outfit',
            ),
          ),

          children: [
            Align(
              alignment:
                  Alignment.centerLeft,

              child:
                  Text(
                seccion.descripcion,

                style:
                    TextStyle(
                  color:
                      textoSecundario,

                  fontSize:
                      13.5,

                  height:
                      1.5,

                  fontFamily:
                      'Outfit',
                ),
              ),
            ),

            if (seccion
                .puntos
                .isNotEmpty)
              const SizedBox(
                height: 12,
              ),

            ...seccion.puntos.map(
              (
                punto,
              ) {
                return Padding(
                  padding:
                      const EdgeInsets.only(
                    bottom: 8,
                  ),

                  child:
                      Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,

                    children: [
                      Container(
                        width: 6,
                        height: 6,

                        margin:
                            const EdgeInsets.only(
                          top: 7,
                          right: 10,
                        ),

                        decoration:
                            const BoxDecoration(
                          color:
                              AppColors.naranja,

                          shape:
                              BoxShape.circle,
                        ),
                      ),

                      Expanded(
                        child:
                            Text(
                          punto,

                          style:
                              TextStyle(
                            color:
                                textoSecundario,

                            fontSize:
                                13,

                            height:
                                1.4,

                            fontFamily:
                                'Outfit',
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// MODELO
// ============================================================

class _SeccionPrivacidad {
  final IconData icono;

  final String titulo;

  final String descripcion;

  final List<String> puntos;

  const _SeccionPrivacidad({
    required this.icono,
    required this.titulo,
    required this.descripcion,
    required this.puntos,
  });
}