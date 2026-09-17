<%--
  cliente/acciones_cita.jsp - Controlador transaccional para agendamiento de citas y favoritos
  Proyecto: InmobiliariaWeb
  Valida cruces de horario mediante UNIQUE(id_propiedad, fecha_hora), capturando
  la excepción SQLIntegrityConstraintViolationException para notificar:
  "Ese horario ya se encuentra reservado para esta propiedad".
--%>
<%@ page contentType="text/html" pageEncoding="UTF-8" %>
<%@ page import="java.sql.SQLIntegrityConstraintViolationException, java.net.URLEncoder" %>
<%@ include file="/WEB-INF/jspf/conexion.jspf" %>
<%@ include file="/WEB-INF/jspf/utilidades.jspf" %>
<%
    String[] rolesPermitidos = {"CLIENTE", "ADMIN"};
%>
<%@ include file="/WEB-INF/jspf/seguridad.jspf" %>
<%
    request.setCharacterEncoding("UTF-8");
    String ctx = request.getContextPath();
    String accion = request.getParameter("accion");
    if (accion == null) accion = "agendar";

    String destino = ctx + "/cliente/agendar_cita.jsp";

    Connection con = null;
    PreparedStatement ps = null;
    ResultSet rs = null;

    try {
        con = abrirConexion();

        if ("agendar".equalsIgnoreCase(accion)) {
            // ================= 1) AGENDAR CITA =================
            int idPropiedad = aEntero(request.getParameter("id_propiedad"), 0);
            String fechaHoraRaw = request.getParameter("fecha_hora");
            String mensaje = request.getParameter("mensaje");

            if (idPropiedad <= 0 || fechaHoraRaw == null || fechaHoraRaw.trim().isEmpty()) {
                destino += "?err=" + URLEncoder.encode("Por favor seleccione un inmueble y la fecha/hora de la visita.", "UTF-8");
                response.sendRedirect(destino);
                return;
            }

            // Normalización de fecha/hora de HTML5 (YYYY-MM-DDTHH:MM) a formato MySQL (YYYY-MM-DD HH:MM:00)
            String fechaHoraSql = fechaHoraRaw.trim().replace("T", " ");
            if (fechaHoraSql.length() == 16) {
                fechaHoraSql += ":00";
            }

            // Obtener el agente asignado a la propiedad
            int idAgente = 0;
            ps = con.prepareStatement("SELECT id_agente FROM propiedad WHERE id_propiedad = ?");
            ps.setInt(1, idPropiedad);
            rs = ps.executeQuery();
            if (rs.next()) {
                idAgente = rs.getInt("id_agente");
            } else {
                destino += "?err=" + URLEncoder.encode("El inmueble seleccionado no existe o está inactivo.", "UTF-8");
                response.sendRedirect(destino);
                return;
            }
            cerrar(rs, ps);

            // Inserción de la cita en estado SOLICITADA
            String sqlInsert = 
                "INSERT INTO cita (id_propiedad, id_cliente, id_agente, fecha_hora, mensaje, estado, fecha_creacion) "
              + "VALUES (?, ?, ?, ?, ?, 'SOLICITADA', NOW())";

            ps = con.prepareStatement(sqlInsert);
            ps.setInt(1, idPropiedad);
            ps.setInt(2, idUsuarioSesion); // Cliente autenticado
            ps.setInt(3, idAgente);
            ps.setString(4, fechaHoraSql);
            ps.setString(5, mensaje != null ? mensaje.trim() : "");
            ps.executeUpdate();

            destino += "?msg=" + URLEncoder.encode("Su cita ha sido solicitada con éxito. El asesor confirmará su visita en breve.", "UTF-8");

        } else if ("cancelar".equalsIgnoreCase(accion)) {
            // ================= 2) CANCELAR CITA POR EL CLIENTE =================
            int idCita = aEntero(request.getParameter("id_cita"), 0);

            ps = con.prepareStatement("UPDATE cita SET estado = 'CANCELADA' WHERE id_cita = ? AND id_cliente = ?");
            ps.setInt(1, idCita);
            ps.setInt(2, idUsuarioSesion);
            int filas = ps.executeUpdate();

            if (filas > 0) {
                destino += "?msg=" + URLEncoder.encode("La cita ha sido cancelada correctamente.", "UTF-8");
            } else {
                destino += "?err=" + URLEncoder.encode("No fue posible cancelar la cita especificada.", "UTF-8");
            }

        } else if ("favorito".equalsIgnoreCase(accion)) {
            // ================= 3) ALTERNAR FAVORITO (TOGGLE) =================
            int idPropiedad = aEntero(request.getParameter("id_propiedad"), 0);
            String retorno = request.getParameter("retorno");
            if (retorno != null && !retorno.trim().isEmpty()) {
                destino = ctx + "/" + retorno;
            } else {
                destino = ctx + "/detalle_propiedad.jsp?id=" + idPropiedad;
            }

            // Verificar si ya existe en favoritos
            ps = con.prepareStatement("SELECT id_favorito FROM favorito WHERE id_usuario = ? AND id_propiedad = ?");
            ps.setInt(1, idUsuarioSesion);
            ps.setInt(2, idPropiedad);
            rs = ps.executeQuery();

            if (rs.next()) {
                // Ya existe -> Eliminar de favoritos
                cerrar(rs, ps);
                ps = con.prepareStatement("DELETE FROM favorito WHERE id_usuario = ? AND id_propiedad = ?");
                ps.setInt(1, idUsuarioSesion);
                ps.setInt(2, idPropiedad);
                ps.executeUpdate();
                destino += (destino.contains("?") ? "&" : "?") + "msg=" + URLEncoder.encode("Inmueble removido de sus favoritos.", "UTF-8");
            } else {
                // No existe -> Agregar a favoritos
                cerrar(rs, ps);
                ps = con.prepareStatement("INSERT INTO favorito (id_usuario, id_propiedad, fecha_agregado) VALUES (?, ?, NOW())");
                ps.setInt(1, idUsuarioSesion);
                ps.setInt(2, idPropiedad);
                ps.executeUpdate();
                destino += (destino.contains("?") ? "&" : "?") + "msg=" + URLEncoder.encode("¡Inmueble añadido a sus favoritos!", "UTF-8");
            }
        }

    } catch (SQLIntegrityConstraintViolationException exIntegridad) {
        // Requisito obligatorio: Captura de la restricción UNIQUE(id_propiedad, fecha_hora)
        String msg = exIntegridad.getMessage();
        String amigable = "Ese horario ya se encuentra reservado para esta propiedad. Por favor seleccione otro horario.";
        destino += (destino.contains("?") ? "&" : "?") + "err=" + URLEncoder.encode(amigable, "UTF-8");

    } catch (SQLException exSql) {
        destino += (destino.contains("?") ? "&" : "?") + "err=" + URLEncoder.encode("Error de base de datos: " + exSql.getMessage(), "UTF-8");

    } finally {
        cerrar(rs, ps, con);
    }

    response.sendRedirect(destino);
%>
