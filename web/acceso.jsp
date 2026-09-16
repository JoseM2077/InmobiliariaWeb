<%--
  acceso.jsp - Controlador de autenticación y carga de sesión
  Proyecto: InmobiliariaWeb
  Procesa credenciales mediante PreparedStatement y setea roles en sesión.
--%>
<%@ page contentType="text/html" pageEncoding="UTF-8" %>
<%@ page import="java.util.List, java.util.ArrayList" %>
<%@ include file="/WEB-INF/jspf/conexion.jspf" %>
<%@ include file="/WEB-INF/jspf/utilidades.jspf" %>
<%
    request.setCharacterEncoding("UTF-8");
    String ctx = request.getContextPath();

    String correo = request.getParameter("correo");
    if (correo == null || correo.trim().isEmpty()) {
        correo = request.getParameter("usuario"); // Soporta ambos nombres de campo
    }
    String clave = request.getParameter("clave");

    // 1) Validación de campos no vacíos
    if (correo == null || clave == null || correo.trim().isEmpty() || clave.trim().isEmpty()) {
        response.sendRedirect(ctx + "/login.jsp?error=vacio");
        return;
    }

    correo = correo.trim().toLowerCase();

    Connection con = null;
    PreparedStatement psUsuario = null;
    ResultSet rsUsuario = null;
    PreparedStatement psRoles = null;
    ResultSet rsRoles = null;
    PreparedStatement psAcceso = null;

    try {
        con = abrirConexion();

        // 2) Consulta segura con PreparedStatement para prevenir inyección SQL
        String sqlUsuario = 
            "SELECT u.id_usuario, u.correo, u.password_hash, u.activo, "
          + "       p.nombres, p.apellidos "
          + "FROM usuario u "
          + "LEFT JOIN perfil p ON p.id_usuario = u.id_usuario "
          + "WHERE u.correo = ?";

        psUsuario = con.prepareStatement(sqlUsuario);
        psUsuario.setString(1, correo);
        rsUsuario = psUsuario.executeQuery();

        if (rsUsuario.next()) {
            int idUsuario       = rsUsuario.getInt("id_usuario");
            String hashGuardado = rsUsuario.getString("password_hash");
            boolean activo      = rsUsuario.getBoolean("activo");
            String nombres      = rsUsuario.getString("nombres");
            String apellidos    = rsUsuario.getString("apellidos");
            String nombreCompleto = (nombres != null ? nombres : "") + (apellidos != null ? " " + apellidos : "");
            if (nombreCompleto.trim().isEmpty()) nombreCompleto = correo;

            // Validación de cuenta activa
            if (!activo) {
                response.sendRedirect(ctx + "/login.jsp?error=inactivo");
                return;
            }

            // Comparación de hash SHA-256 con salt 'correo:clave'
            String hashCalculado = claveCifrada(correo, clave);
            if (hashGuardado.equalsIgnoreCase(hashCalculado)) {
                
                // 3) Obtención de todos los roles asignados al usuario en la relación N:M
                String sqlRoles = 
                    "SELECT r.nombre "
                  + "FROM usuario_rol ur "
                  + "JOIN rol r ON r.id_rol = ur.id_rol "
                  + "WHERE ur.id_usuario = ? AND r.activo = 1 "
                  + "ORDER BY CASE r.nombre "
                  + "  WHEN 'ADMIN'   THEN 1 "
                  + "  WHEN 'AGENTE'  THEN 2 "
                  + "  WHEN 'CLIENTE' THEN 3 "
                  + "  ELSE 4 END";

                psRoles = con.prepareStatement(sqlRoles);
                psRoles.setInt(1, idUsuario);
                rsRoles = psRoles.executeQuery();

                List<String> listaRoles = new ArrayList<>();
                while (rsRoles.next()) {
                    listaRoles.add(rsRoles.getString("nombre"));
                }

                // Determinar el rol principal por jerarquía
                String rolPrincipal = "CLIENTE";
                if (!listaRoles.isEmpty()) {
                    rolPrincipal = listaRoles.get(0);
                } else {
                    listaRoles.add("CLIENTE");
                }

                // 4) Configurar atributos en la sesión HTTP
                session.setAttribute("idUsuario", idUsuario);
                session.setAttribute("correo", correo);
                session.setAttribute("nombre", nombreCompleto.trim());
                session.setAttribute("rol", rolPrincipal);
                session.setAttribute("roles", listaRoles);
                session.setMaxInactiveInterval(30 * 60); // 30 minutos

                // 5) Registro del último acceso
                psAcceso = con.prepareStatement("UPDATE usuario SET ultimo_acceso = NOW() WHERE id_usuario = ?");
                psAcceso.setInt(1, idUsuario);
                psAcceso.executeUpdate();

                // Redirección al panel principal
                response.sendRedirect(ctx + "/inicio.jsp");
                return;
            }
        }

        // Credenciales inválidas
        response.sendRedirect(ctx + "/login.jsp?error=clave");

    } catch (SQLException ex) {
        out.println("<div style='font-family:sans-serif;padding:30px;max-width:600px;margin:50px auto;border:1px solid #dc3545;border-radius:8px;background:#fff5f5;'>"
                  + "<h3 style='color:#dc3545;margin-top:0'>Error en el proceso de autenticación</h3>"
                  + "<p>Ocurrió un fallo de conexión con el motor MySQL:</p>"
                  + "<pre style='background:#f8d7da;padding:10px;border-radius:4px;'>" + esc(ex.getMessage()) + "</pre>"
                  + "<a href='" + ctx + "/login.jsp' style='display:inline-block;padding:8px 16px;background:#0d6efd;color:white;text-decoration:none;border-radius:4px;'>Volver a intentar</a>"
                  + "</div>");
    } finally {
        cerrar(psAcceso, rsRoles, psRoles, rsUsuario, psUsuario, con);
    }
%>
