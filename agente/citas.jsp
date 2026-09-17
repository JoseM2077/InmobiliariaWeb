<%--
  agente/citas.jsp - Gestión de visitas presenciales para el AGENTE (aprobar o rechazar citas)
  Proyecto: InmobiliariaWeb
--%>
<%@ page contentType="text/html" pageEncoding="UTF-8" %>
<%@ page import="java.net.URLEncoder" %>
<%@ include file="/WEB-INF/jspf/conexion.jspf" %>
<%@ include file="/WEB-INF/jspf/utilidades.jspf" %>
<%
    String[] rolesPermitidos = {"AGENTE", "ADMIN"};
%>
<%@ include file="/WEB-INF/jspf/seguridad.jspf" %>
<%
    request.setCharacterEncoding("UTF-8");
    String accion = request.getParameter("accion");
    String msg = request.getParameter("msg");
    String err = request.getParameter("err");

    Connection con = null;
    PreparedStatement psAccion = null;
    PreparedStatement psCitas = null;
    ResultSet rsCitas = null;

    try {
        con = abrirConexion();

        // 1) Procesar cambios de estado de cita (Aprobar, Rechazar, Marcar Realizada)
        if ("cambiar_estado".equalsIgnoreCase(accion)) {
            int idCita = aEntero(request.getParameter("id_cita"), 0);
            String nuevoEstado = request.getParameter("nuevo_estado");

            if (idCita > 0 && nuevoEstado != null && !nuevoEstado.trim().isEmpty()) {
                nuevoEstado = nuevoEstado.trim().toUpperCase();

                String sqlUpdate = "UPDATE cita SET estado = ? WHERE id_cita = ?";
                if (!"ADMIN".equalsIgnoreCase(rolSesion)) {
                    sqlUpdate += " AND id_agente = ?";
                }

                psAccion = con.prepareStatement(sqlUpdate);
                psAccion.setString(1, nuevoEstado);
                psAccion.setInt(2, idCita);
                if (!"ADMIN".equalsIgnoreCase(rolSesion)) {
                    psAccion.setInt(3, idUsuarioSesion);
                }

                int filas = psAccion.executeUpdate();
                cerrar(psAccion);

                if (filas > 0) {
                    msg = "La cita #" + idCita + " fue actualizada al estado: " + nuevoEstado;
                } else {
                    err = "No fue posible modificar el estado de la cita seleccionada.";
                }
            }
        }

        // 2) Filtro de estado
        String filtroEstado = request.getParameter("estado");
        if (filtroEstado == null) filtroEstado = "TODOS";

        StringBuilder sql = new StringBuilder();
        sql.append("SELECT c.id_cita, c.fecha_hora, c.estado, c.mensaje, c.fecha_creacion, ")
           .append("       p.id_propiedad, p.codigo, p.titulo, p.direccion, c_ciu.nombre AS ciudad, ")
           .append("       u_cli.correo AS cli_correo, perf.nombres AS cli_nombres, perf.apellidos AS cli_apellidos, ")
           .append("       perf.documento AS cli_doc, perf.telefono AS cli_tel ")
           .append("FROM cita c ")
           .append("JOIN propiedad p ON p.id_propiedad = c.id_propiedad ")
           .append("JOIN ciudad c_ciu ON c_ciu.id_ciudad = p.id_ciudad ")
           .append("JOIN usuario u_cli ON u_cli.id_usuario = c.id_cliente ")
           .append("LEFT JOIN perfil perf ON perf.id_usuario = u_cli.id_usuario ")
           .append("WHERE 1=1 ");

        if (!"ADMIN".equalsIgnoreCase(rolSesion)) {
            sql.append(" AND c.id_agente = ? ");
        }
        if (!"TODOS".equalsIgnoreCase(filtroEstado)) {
            sql.append(" AND c.estado = ? ");
        }
        sql.append(" ORDER BY c.fecha_hora DESC");

        psCitas = con.prepareStatement(sql.toString());
        int pIdx = 1;
        if (!"ADMIN".equalsIgnoreCase(rolSesion)) {
            psCitas.setInt(pIdx++, idUsuarioSesion);
        }
        if (!"TODOS".equalsIgnoreCase(filtroEstado)) {
            psCitas.setString(pIdx++, filtroEstado);
        }

        rsCitas = psCitas.executeQuery();
%>
<% String tituloPagina = "Agenda de Citas"; %>
<%@ include file="/WEB-INF/jspf/cabecera.jspf" %>

<div class="container my-4">

  <!-- Mensajes de feedback -->
  <% if (msg != null) { %>
    <div class="alert alert-success alert-dismissible fade show shadow-sm" role="alert">
      <i class="bi bi-check-circle-fill me-2"></i> <%= esc(msg) %>
      <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
    </div>
  <% } %>
  <% if (err != null) { %>
    <div class="alert alert-danger alert-dismissible fade show shadow-sm" role="alert">
      <i class="bi bi-exclamation-octagon-fill me-2"></i> <%= esc(err) %>
      <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
    </div>
  <% } %>

  <div class="card border-0 shadow-sm rounded-4 p-4 bg-white mb-4">
    <div class="d-flex flex-wrap justify-content-between align-items-center gap-3">
      <div>
        <h3 class="fw-bold text-navy mb-1">
          <i class="bi bi-calendar2-check-fill text-primary me-2"></i> Gesti&oacute;n de Citas y Visitas
        </h3>
        <p class="text-muted small mb-0">
          Revise solicitudes de visita, apruebe horarios, rechace o marque visitas realizadas con clientes.
        </p>
      </div>

      <!-- Filtro rápido de estado -->
      <div class="btn-group" role="group">
        <a href="<%= ctx %>/agente/citas.jsp?estado=TODOS" class="btn btn-sm <%= "TODOS".equals(filtroEstado) ? "btn-primary fw-bold" : "btn-outline-secondary" %>">Todas</a>
        <a href="<%= ctx %>/agente/citas.jsp?estado=SOLICITADA" class="btn btn-sm <%= "SOLICITADA".equals(filtroEstado) ? "btn-warning fw-bold text-dark" : "btn-outline-warning text-dark" %>">Por Aprobar</a>
        <a href="<%= ctx %>/agente/citas.jsp?estado=CONFIRMADA" class="btn btn-sm <%= "CONFIRMADA".equals(filtroEstado) ? "btn-info fw-bold text-dark" : "btn-outline-info text-dark" %>">Confirmadas</a>
        <a href="<%= ctx %>/agente/citas.jsp?estado=REALIZADA" class="btn btn-sm <%= "REALIZADA".equals(filtroEstado) ? "btn-success fw-bold" : "btn-outline-success" %>">Realizadas</a>
        <a href="<%= ctx %>/agente/citas.jsp?estado=CANCELADA" class="btn btn-sm <%= "CANCELADA".equals(filtroEstado) ? "btn-danger fw-bold" : "btn-outline-danger" %>">Canceladas</a>
      </div>
    </div>
  </div>

  <!-- Tabla de Citas -->
  <div class="card border-0 shadow-sm rounded-4 bg-white overflow-hidden">
    <div class="table-responsive">
      <table class="table table-hover align-middle mb-0">
        <thead class="table-navy bg-navy text-white">
          <tr>
            <th>C&oacute;d / Inmueble</th>
            <th>Cliente Interesado</th>
            <th>Fecha y Hora</th>
            <th>Mensaje / Consulta</th>
            <th class="text-center">Estado</th>
            <th class="text-center" style="width: 220px;">Acciones de Agente</th>
          </tr>
        </thead>
        <tbody>
          <% 
            boolean hayCitas = false;
            while (rsCitas.next()) { 
              hayCitas = true;
              int idCita = rsCitas.getInt("id_cita");
              String est = rsCitas.getString("estado");
              String cliNom = rsCitas.getString("cli_nombres") + " " + rsCitas.getString("cli_apellidos");
              String cliTel = rsCitas.getString("cli_tel");
              String cliCor = rsCitas.getString("cli_correo");
              String msgCli = rsCitas.getString("mensaje");
          %>
            <tr>
              <td>
                <div class="fw-bold text-navy">
                  <a href="<%= ctx %>/detalle_propiedad.jsp?id=<%= rsCitas.getInt("id_propiedad") %>" class="text-decoration-none text-navy">
                    <%= esc(rsCitas.getString("titulo")) %>
                  </a>
                </div>
                <small class="text-muted">C&oacute;d: <code><%= esc(rsCitas.getString("codigo")) %></code> &middot; <%= esc(rsCitas.getString("ciudad")) %></small>
              </td>
              <td class="small">
                <div class="fw-bold"><%= esc(cliNom) %></div>
                <div class="text-muted">
                  <i class="bi bi-telephone text-primary me-1"></i> <a href="tel:<%= cliTel %>" class="text-decoration-none text-secondary"><%= esc(cliTel) %></a>
                </div>
                <div class="text-muted">
                  <i class="bi bi-envelope text-primary me-1"></i> <%= esc(cliCor) %>
                </div>
              </td>
              <td class="small fw-semibold text-secondary">
                <i class="bi bi-calendar-event text-primary me-1"></i> <%= rsCitas.getString("fecha_hora").substring(0, 16) %>
              </td>
              <td class="small text-muted" style="max-width: 250px;">
                <%= (msgCli != null && !msgCli.isEmpty()) ? esc(msgCli) : "<span class='text-muted fst-italic'>Sin mensaje</span>" %>
              </td>
              <td class="text-center">
                <span class="badge bg-<%= colorEstadoCita(est) %> px-3 py-2"><%= est %></span>
              </td>
              <td class="text-center">
                
                <% if ("SOLICITADA".equalsIgnoreCase(est)) { %>
                  <div class="d-flex justify-content-center gap-1">
                    <!-- Botón Aprobar / Confirmar -->
                    <a href="<%= ctx %>/agente/citas.jsp?accion=cambiar_estado&id_cita=<%= idCita %>&nuevo_estado=CONFIRMADA&estado=<%= filtroEstado %>" 
                       class="btn btn-sm btn-success fw-semibold" 
                       title="Aprobar y Confirmar Cita">
                      <i class="bi bi-check-lg"></i> Aprobar
                    </a>
                    <!-- Botón Rechazar / Cancelar -->
                    <a href="<%= ctx %>/agente/citas.jsp?accion=cambiar_estado&id_cita=<%= idCita %>&nuevo_estado=CANCELADA&estado=<%= filtroEstado %>" 
                       class="btn btn-sm btn-outline-danger" 
                       onclick="return confirm('&iquest;Est&aacute; seguro de rechazar esta solicitud de visita?');"
                       title="Rechazar Cita">
                      <i class="bi bi-x-lg"></i> Rechazar
                    </a>
                  </div>

                <% } else if ("CONFIRMADA".equalsIgnoreCase(est)) { %>
                  <div class="d-flex justify-content-center gap-1">
                    <!-- Botón Marcar Realizada -->
                    <a href="<%= ctx %>/agente/citas.jsp?accion=cambiar_estado&id_cita=<%= idCita %>&nuevo_estado=REALIZADA&estado=<%= filtroEstado %>" 
                       class="btn btn-sm btn-primary fw-semibold" 
                       title="Marcar Visita Realizada">
                      <i class="bi bi-check2-all"></i> Realizada
                    </a>
                    <!-- Cancelar Cita Confirmada -->
                    <a href="<%= ctx %>/agente/citas.jsp?accion=cambiar_estado&id_cita=<%= idCita %>&nuevo_estado=CANCELADA&estado=<%= filtroEstado %>" 
                       class="btn btn-sm btn-outline-secondary" 
                       onclick="return confirm('&iquest;Desea cancelar esta cita confirmada?');"
                       title="Cancelar">
                      <i class="bi bi-x-circle"></i> Cancelar
                    </a>
                  </div>

                <% } else { %>
                  <span class="badge bg-light text-muted border">Visita <%= est.toLowerCase() %></span>
                <% } %>

              </td>
            </tr>
          <% } %>

          <% if (!hayCitas) { %>
            <tr>
              <td colspan="6" class="text-center py-5 text-muted">
                <i class="bi bi-calendar-check display-6 d-block mb-2 text-secondary"></i>
                No se encontraron citas con el estado seleccionado.
              </td>
            </tr>
          <% } %>
        </tbody>
      </table>
    </div>
  </div>

</div>

<%@ include file="/WEB-INF/jspf/pie.jspf" %>
<%
    } catch (SQLException ex) {
        out.println("<div class='alert alert-danger'>Error al procesar citas de agente: " + esc(ex.getMessage()) + "</div>");
    } finally {
        cerrar(rsCitas, psCitas, psAccion, con);
    }
%>
