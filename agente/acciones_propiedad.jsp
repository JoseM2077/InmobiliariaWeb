<%--
  agente/acciones_propiedad.jsp - Controlador transaccional para operaciones de inmuebles
  Proyecto: InmobiliariaWeb
  Maneja setAutoCommit(false), inserción de características N:M,
  baja lógica y captura de SQLIntegrityConstraintViolationException en matrícula inmobiliaria y código.
--%>
<%@ page contentType="text/html" pageEncoding="UTF-8" %>
<%@ page import="java.sql.SQLIntegrityConstraintViolationException, java.net.URLEncoder" %>
<%@ include file="/WEB-INF/jspf/conexion.jspf" %>
<%@ include file="/WEB-INF/jspf/utilidades.jspf" %>
<%
    String[] rolesPermitidos = {"AGENTE", "ADMIN"};
%>
<%@ include file="/WEB-INF/jspf/seguridad.jspf" %>
<%
    request.setCharacterEncoding("UTF-8");
    String ctx = request.getContextPath();
    String accion = request.getParameter("accion");
    if (accion == null) accion = "crear";

    String destino = ctx + "/agente/propiedades.jsp";

    Connection con = null;
    PreparedStatement psProp = null;
    ResultSet rsKeys = null;
    PreparedStatement psImg = null;
    PreparedStatement psPC = null;
    PreparedStatement psDelPC = null;

    try {
        con = abrirConexion();
        con.setAutoCommit(false); // Transacción atómica obligatoria

        if ("baja_logica".equalsIgnoreCase(accion)) {
            // ================= 1) BAJA O REACTIVACIÓN LÓGICA =================
            int idPropiedad = aEntero(request.getParameter("id_propiedad"), 0);
            int nuevoActivo = aEntero(request.getParameter("activo"), 0);
            String nuevoEstado = (nuevoActivo == 1) ? "DISPONIBLE" : "INACTIVA";

            // Si es agente, solo puede modificar sus propias propiedades
            String sqlBaja = "UPDATE propiedad SET activo = ?, estado = ? WHERE id_propiedad = ?";
            if (!"ADMIN".equalsIgnoreCase(rolSesion)) {
                sqlBaja += " AND id_agente = ?";
            }

            psProp = con.prepareStatement(sqlBaja);
            psProp.setInt(1, nuevoActivo);
            psProp.setString(2, nuevoEstado);
            psProp.setInt(3, idPropiedad);
            if (!"ADMIN".equalsIgnoreCase(rolSesion)) {
                psProp.setInt(4, idUsuarioSesion);
            }

            int filas = psProp.executeUpdate();
            con.commit();

            if (filas > 0) {
                String textoMsg = (nuevoActivo == 1) ? "Inmueble reactivado exitosamente en el catálogo." : "Inmueble dado de baja lógica correctamente.";
                destino += "?msg=" + URLEncoder.encode(textoMsg, "UTF-8");
            } else {
                destino += "?err=" + URLEncoder.encode("No se encontró el inmueble o no tiene permisos para modificarlo.", "UTF-8");
            }

        } else if ("crear".equalsIgnoreCase(accion)) {
            // ================= 2) CREACIÓN DE NUEVA PROPIEDAD =================
            String codigo    = request.getParameter("codigo");
            String matricula = request.getParameter("matricula_inmobiliaria");
            String titulo    = request.getParameter("titulo");
            String desc      = request.getParameter("descripcion");
            double precio    = aDoble(request.getParameter("precio"), 0);
            String negocio   = request.getParameter("tipo_negocio");
            String direccion = request.getParameter("direccion");
            int idCiudad     = aEntero(request.getParameter("id_ciudad"), 0);
            int idTipo       = aEntero(request.getParameter("id_tipo"), 0);
            double area      = aDoble(request.getParameter("area_m2"), 0);
            int hab          = aEntero(request.getParameter("habitaciones"), 0);
            int banos        = aEntero(request.getParameter("banos"), 0);
            int pq           = aEntero(request.getParameter("parqueaderos"), 0);
            int estrato      = aEntero(request.getParameter("estrato"), 3);
            int destacada    = "1".equals(request.getParameter("destacada")) ? 1 : 0;
            String urlImagen = request.getParameter("url_imagen");
            String[] caracteristicas = request.getParameterValues("caracteristicas");

            if (codigo == null || codigo.trim().isEmpty()
                || matricula == null || matricula.trim().isEmpty()
                || titulo == null || titulo.trim().isEmpty()
                || precio <= 0 || idCiudad <= 0 || idTipo <= 0) {
                
                destino += "?err=" + URLEncoder.encode("Por favor complete los campos obligatorios y un precio válido.", "UTF-8");
                response.sendRedirect(destino);
                return;
            }

            // Paso A: Insertar en tabla propiedad
            String sqlInsertProp = 
                "INSERT INTO propiedad (codigo, matricula_inmobiliaria, titulo, descripcion, precio, "
              + "  tipo_negocio, direccion, id_ciudad, id_tipo, id_agente, area_m2, habitaciones, banos, "
              + "  parqueaderos, estrato, estado, destacada, fecha_publicacion, activo) "
              + "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'DISPONIBLE', ?, NOW(), 1)";

            psProp = con.prepareStatement(sqlInsertProp, Statement.RETURN_GENERATED_KEYS);
            psProp.setString(1, codigo.trim().toUpperCase());
            psProp.setString(2, matricula.trim().toUpperCase());
            psProp.setString(3, titulo.trim());
            psProp.setString(4, desc != null ? desc.trim() : "");
            psProp.setDouble(5, precio);
            psProp.setString(6, negocio != null ? negocio.trim().toUpperCase() : "VENTA");
            psProp.setString(7, direccion != null ? direccion.trim() : "");
            psProp.setInt(8, idCiudad);
            psProp.setInt(9, idTipo);
            psProp.setInt(10, idUsuarioSesion); // Agente autenticado
            psProp.setDouble(11, area);
            psProp.setInt(12, hab);
            psProp.setInt(13, banos);
            psProp.setInt(14, pq);
            psProp.setInt(15, estrato);
            psProp.setInt(16, destacada);
            psProp.executeUpdate();

            rsKeys = psProp.getGeneratedKeys();
            int idPropiedadNueva = 0;
            if (rsKeys.next()) {
                idPropiedadNueva = rsKeys.getInt(1);
            } else {
                throw new SQLException("No se pudo obtener el ID del inmueble insertado.");
            }

            // Paso B: Insertar imagen principal en imagen_propiedad (1:N)
            if (urlImagen != null && !urlImagen.trim().isEmpty()) {
                psImg = con.prepareStatement(
                    "INSERT INTO imagen_propiedad (id_propiedad, url_imagen, titulo, es_principal, orden) "
                  + "VALUES (?, ?, ?, 1, 1)"
                );
                psImg.setInt(1, idPropiedadNueva);
                psImg.setString(2, urlImagen.trim());
                psImg.setString(3, titulo.trim());
                psImg.executeUpdate();
            }

            // Paso C: Insertar características seleccionadas en propiedad_caracteristica (N:M)
            if (caracteristicas != null && caracteristicas.length > 0) {
                psPC = con.prepareStatement(
                    "INSERT INTO propiedad_caracteristica (id_propiedad, id_caracteristica, valor) VALUES (?, ?, 'Sí')"
                );
                for (String cIdStr : caracteristicas) {
                    int cId = aEntero(cIdStr, 0);
                    if (cId > 0) {
                        psPC.setInt(1, idPropiedadNueva);
                        psPC.setInt(2, cId);
                        psPC.addBatch();
                    }
                }
                psPC.executeBatch();
            }

            // Consolidar toda la transacción
            con.commit();
            destino += "?msg=" + URLEncoder.encode("Inmueble " + codigo.trim() + " publicado exitosamente.", "UTF-8");

        } else if ("editar".equalsIgnoreCase(accion)) {
            // ================= 3) EDICIÓN DE PROPIEDAD =================
            int idPropiedad  = aEntero(request.getParameter("id_propiedad"), 0);
            String matricula = request.getParameter("matricula_inmobiliaria");
            String titulo    = request.getParameter("titulo");
            String desc      = request.getParameter("descripcion");
            double precio    = aDoble(request.getParameter("precio"), 0);
            String negocio   = request.getParameter("tipo_negocio");
            String direccion = request.getParameter("direccion");
            int idCiudad     = aEntero(request.getParameter("id_ciudad"), 0);
            int idTipo       = aEntero(request.getParameter("id_tipo"), 0);
            double area      = aDoble(request.getParameter("area_m2"), 0);
            int hab          = aEntero(request.getParameter("habitaciones"), 0);
            int banos        = aEntero(request.getParameter("banos"), 0);
            int pq           = aEntero(request.getParameter("parqueaderos"), 0);
            int estrato      = aEntero(request.getParameter("estrato"), 3);
            String estado    = request.getParameter("estado");
            int destacada    = "1".equals(request.getParameter("destacada")) ? 1 : 0;
            String[] caracteristicas = request.getParameterValues("caracteristicas");

            String sqlUpdate = 
                "UPDATE propiedad SET matricula_inmobiliaria = ?, titulo = ?, descripcion = ?, precio = ?, "
              + "  tipo_negocio = ?, direccion = ?, id_ciudad = ?, id_tipo = ?, area_m2 = ?, habitaciones = ?, "
              + "  banos = ?, parqueaderos = ?, estrato = ?, estado = ?, destacada = ? "
              + "WHERE id_propiedad = ?";
            if (!"ADMIN".equalsIgnoreCase(rolSesion)) {
                sqlUpdate += " AND id_agente = ?";
            }

            psProp = con.prepareStatement(sqlUpdate);
            psProp.setString(1, matricula.trim().toUpperCase());
            psProp.setString(2, titulo.trim());
            psProp.setString(3, desc != null ? desc.trim() : "");
            psProp.setDouble(4, precio);
            psProp.setString(5, negocio != null ? negocio.trim().toUpperCase() : "VENTA");
            psProp.setString(7, direccion != null ? direccion.trim() : "");
            psProp.setInt(7, idCiudad);
            psProp.setInt(8, idTipo);
            psProp.setDouble(9, area);
            psProp.setInt(10, hab);
            psProp.setInt(11, banos);
            psProp.setInt(12, pq);
            psProp.setInt(13, estrato);
            psProp.setString(14, estado != null ? estado.trim().toUpperCase() : "DISPONIBLE");
            psProp.setInt(15, destacada);
            psProp.setInt(16, idPropiedad);
            if (!"ADMIN".equalsIgnoreCase(rolSesion)) {
                psProp.setInt(17, idUsuarioSesion);
            }
            psProp.executeUpdate();

            // Reasignar características (eliminar previas y reinsertar)
            psDelPC = con.prepareStatement("DELETE FROM propiedad_caracteristica WHERE id_propiedad = ?");
            psDelPC.setInt(1, idPropiedad);
            psDelPC.executeUpdate();

            if (caracteristicas != null && caracteristicas.length > 0) {
                psPC = con.prepareStatement(
                    "INSERT INTO propiedad_caracteristica (id_propiedad, id_caracteristica, valor) VALUES (?, ?, 'Sí')"
                );
                for (String cIdStr : caracteristicas) {
                    int cId = aEntero(cIdStr, 0);
                    if (cId > 0) {
                        psPC.setInt(1, idPropiedad);
                        psPC.setInt(2, cId);
                        psPC.addBatch();
                    }
                }
                psPC.executeBatch();
            }

            con.commit();
            destino += "?msg=" + URLEncoder.encode("Inmueble actualizado correctamente.", "UTF-8");
        }

    } catch (SQLIntegrityConstraintViolationException exIntegridad) {
        // Requisito obligatorio: Captura de violación de restricción UNIQUE en matrícula_inmobiliaria y código
        deshacer(con);
        String msg = exIntegridad.getMessage();
        String amigable = "Error de datos duplicados:";
        if (msg != null && (msg.contains("matricula") || msg.contains("uq_propiedad_matricula"))) {
            amigable = "Ya existe un inmueble registrado con esa matrícula inmobiliaria. Por favor verifique el certificado catastral.";
        } else if (msg != null && (msg.contains("codigo") || msg.contains("uq_propiedad_codigo"))) {
            amigable = "El código asignado al inmueble ya se encuentra en uso. Ingrese un código único.";
        } else {
            amigable = "Restricción de integridad en la base de datos: " + msg;
        }
        destino += "?err=" + URLEncoder.encode(amigable, "UTF-8");

    } catch (SQLException exSql) {
        deshacer(con);
        destino += "?err=" + URLEncoder.encode("Error de base de datos: " + exSql.getMessage(), "UTF-8");

    } finally {
        cerrar(psDelPC, psPC, psImg, rsKeys, psProp, con);
    }

    response.sendRedirect(destino);
%>
