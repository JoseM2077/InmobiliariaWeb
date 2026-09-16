<%--
  agente/inicio.jsp - Tablero de control exclusivo para el rol AGENTE
  Proyecto: InmobiliariaWeb
--%>
<%@ page contentType="text/html" pageEncoding="UTF-8" %>
<%
    String[] rolesPermitidos = {"AGENTE", "ADMIN"};
%>
<%@ include file="/WEB-INF/jspf/seguridad.jspf" %>
<%@ include file="/WEB-INF/jspf/conexion.jspf" %>
<%@ include file="/WEB-INF/jspf/utilidades.jspf" %>
<%
    String tituloPagina = "Tablero del Agente";

    Connection con = null;
    PreparedStatement psStats = null;
    ResultSet rsStats = null;
    PreparedStatement psProps = null;
    ResultSet rsProps = null;
    PreparedStatement psCitas = null;
    ResultSet rsCitas = null;

    int totalMisInmuebles = 0;
    int totalCitasPendientes = 0;
    int totalCitasConfirmadas = 0;
    int totalSolicitudes = 0;

    try {
        con = abrirConexion();

        // 1) Métricas clave del asesor inmobiliario
        psStats = con.prepareStatement(
            "SELECT "
          + "  (SELECT COUNT(*) FROM propiedad WHERE id_agente = ? AND activo = 1) AS c_props, "
          + "  (SELECT COUNT(*) FROM cita WHERE id_agente = ? AND estado = 'SOLICITADA') AS c_citas_sol, "
          + "  (SELECT COUNT(*) FROM cita WHERE id_agente = ? AND estado = 'CONFIRMADA') AS c_citas_conf, "
          + "  (SELECT COUNT(*) FROM solicitud s JOIN propiedad p ON p.id_propiedad = s.id_propiedad WHERE p.id_agente = ? AND s.estado IN ('PENDIENTE', 'EN_REVISION')) AS c_solicitudes"
        );
        psStats.setInt(1, idUsuarioSesion);
        psStats.setInt(2, idUsuarioSesion);
        psStats.setInt(3, idUsuarioSesion);
        psStats.setInt(4, idUsuarioSesion);
        rsStats = psStats.executeQuery();
        if (rsStats.next()) {
            totalMisInmuebles = rsStats.getInt("c_props");
            totalCitasPendientes = rsStats.getInt("c_citas_sol");
            totalCitasConfirmadas = rsStats.getInt("c_citas_conf");
            totalSolicitudes = rsStats.getInt("c_solicitudes");
        }

        // 2) Mis propiedades más recientes
        psProps = con.prepareStatement(
            "SELECT p.id_propiedad, p.codigo, p.matricula_inmobiliaria, p.titulo, p.precio, p.tipo_negocio, "
          + "       p.estado, p.activo, c.nombre AS ciudad, tp.nombre AS tipo "
          + "FROM propiedad p "
          + "JOIN ciudad c ON c.id_ciudad = p.id_ciudad "
          + "JOIN tipo_propiedad tp ON tp.id_tipo = p.id_tipo "
          + "WHERE p.id_agente = ? "
          + "ORDER BY p.id_propiedad DESC LIMIT 5"
        );
        psProps.setInt(1, idUsuarioSesion);
        rsProps = psProps.executeQuery();

        // 3) Citas pendientes que requieren atención
        psCitas = con.prepareStatement(
            "SELECT c.id_cita, c.fecha_hora, c.estado, c.mensaje, p.titulo AS propiedad_titulo, "
          + "       perf.nombres AS cli_nombres, perf.apellidos AS cli_apellidos, perf.telefono AS cli_telefono "
          + "FROM cita c "
          + "JOIN propiedad p ON p.id_propiedad = c.id_propiedad "
          + "JOIN usuario u ON u.id_usuario = c.id_cliente "
          + "LEFT JOIN perfil perf ON perf.id_usuario = u.id_usuario "
          + "WHERE c.id_agente = ? AND c.estado = 'SOLICITADA' "
          + "ORDER BY c.fecha_hora ASC LIMIT 4"
        );
        psCitas.setInt(1, idUsuarioSesion);
        rsCitas = psCitas.executeQuery();
%>
<%@ include file="/WEB-INF/jspf/cabecera.jspf" %>

<!-- Encabezado del Tablero -->
<div class="row mb-4">
  <div class="col-12">
    <div class="card border-0 shadow-sm bg-white p-4 rounded-4">
      <div class="d-flex flex-wrap justify-content-between align-items-center gap-3">
        <div>
          <span class="badge text-bg-primary px-3 py-1 mb-2">Rol Agente Inmobiliario</span>
          <h2 class="fw-bold text-navy mb-1">¡Bienvenido(a), Asesor(a) <%= esc(nombreSesion) %>!</h2>
          <p class="text-muted mb-0">
            <i class="bi bi-briefcase me-1 text-primary"></i> Gestiona tu inventario inmobiliario, agenda de citas y solicitudes de clientes.
          </p>
        </div>
        <div class="d-flex gap-2">
          <a href="<%= ctx %>/agente/propiedades.jsp" class="btn btn-primary fw-semibold shadow-sm">
            <i class="bi bi-houses me-1"></i> Administrar Mis Inmuebles
          </a>
        </div>
      </div>
    </div>
  </div>
</div>

<!-- Métricas Clave -->
<div class="row g-3 mb-4">
  <div class="col-sm-6 col-xl-3">
    <div class="card border-0 shadow-sm rounded-4 p-3 bg-white h-100">
      <div class="d-flex align-items-center gap-3">
        <div class="feature-icon bg-primary-subtle text-primary mb-0">
          <i class="bi bi-building-check"></i>
        </div>
        <div>
          <h6 class="text-muted small mb-1">Inmuebles Activos</h6>
          <h3 class="fw-bold text-navy mb-0"><%= totalMisInmuebles %></h3>
        </div>
      </div>
    </div>
  </div>

  <div class="col-sm-6 col-xl-3">
    <div class="card border-0 shadow-sm rounded-4 p-3 bg-white h-100">
      <div class="d-flex align-items-center gap-3">
        <div class="feature-icon bg-warning-subtle text-warning mb-0">
          <i class="bi bi-calendar-plus-fill"></i>
        </div>
        <div>
          <h6 class="text-muted small mb-1">Citas Por Confirmar</h6>
          <h3 class="fw-bold text-navy mb-0"><%= totalCitasPendientes %></h3>
        </div>
      </div>
    </div>
  </div>

  <div class="col-sm-6 col-xl-3">
    <div class="card border-0 shadow-sm rounded-4 p-3 bg-white h-100">
      <div class="d-flex align-items-center gap-3">
        <div class="feature-icon bg-info-subtle text-info mb-0">
          <i class="bi bi-calendar-check-fill"></i>
        </div>
        <div>
          <h6 class="text-muted small mb-1">Citas Confirmadas</h6>
          <h3 class="fw-bold text-navy mb-0"><%= totalCitasConfirmadas %></h3>
        </div>
      </div>
    </div>
  </div>

  <div class="col-sm-6 col-xl-3">
    <div class="card border-0 shadow-sm rounded-4 p-3 bg-white h-100">
      <div class="d-flex align-items-center gap-3">
        <div class="feature-icon bg-success-subtle text-success mb-0">
          <i class="bi bi-file-earmark-arrow-up-fill"></i>
        </div>
        <div>
          <h6 class="text-muted small mb-1">Solicitudes en Estudio</h6>
          <h3 class="fw-bold text-navy mb-0"><%= totalSolicitudes %></h3>
        </div>
      </div>
    </div>
  </div>
</div>

<!-- Tablas de Gestión Rápida -->
<div class="row g-4">
  
  <!-- Inmuebles asignados -->
  <div class="col-lg-8">
    <div class="card border-0 shadow-sm rounded-4 bg-white p-4 h-100">
      <div class="d-flex justify-content-between align-items-center mb-3">
        <h5 class="fw-bold text-navy mb-0">
          <i class="bi bi-buildings text-primary me-2"></i> Mis Inmuebles Publicados
        </h5>
        <a href="<%= ctx %>/agente/propiedades.jsp" class="btn btn-sm btn-outline-primary fw-semibold">
          Ver Todos <i class="bi bi-arrow-right"></i>
        </a>
      </div>

      <div class="table-responsive">
        <table class="table table-hover align-middle mb-0">
          <thead class="table-light">
            <tr>
              <th>Código / Título</th>
              <th>Ciudad / Tipo</th>
              <th>Precio</th>
              <th>Estado</th>
              <th>Acción</th>
            </tr>
          </thead>
          <tbody>
            <% 
              boolean hayInmuebles = false;
              while (rsProps.next()) { 
                hayInmuebles = true;
                int pId = rsProps.getInt("id_propiedad");
                String pEst = rsProps.getString("estado");
                boolean pActivo = rsProps.getBoolean("activo");
            %>
              <tr>
                <td>
                  <div class="fw-bold text-navy"><%= esc(rsProps.getString("titulo")) %></div>
                  <small class="text-muted">Cód: <code><%= esc(rsProps.getString("codigo")) %></code> &middot; Mat: <%= esc(rsProps.getString("matricula_inmobiliaria")) %></small>
                </td>
                <td class="small">
                  <div><%= esc(rsProps.getString("ciudad")) %></div>
                  <span class="badge bg-light text-dark border"><%= esc(rsProps.getString("tipo")) %></span>
                </td>
                <td class="fw-semibold text-dark">
                  <%= pesos(rsProps.getDouble("precio")) %>
                  <div class="small text-muted"><%= esc(rsProps.getString("tipo_negocio")) %></div>
                </td>
                <td>
                  <span class="badge bg-<%= colorEstadoPropiedad(pEst) %>"><%= pEst %></span>
                  <% if (!pActivo) { %>
                    <span class="badge bg-secondary">Inactivo</span>
                  <% } %>
                </td>
                <td>
                  <a href="<%= ctx %>/detalle_propiedad.jsp?id=<%= pId %>" class="btn btn-sm btn-outline-secondary" title="Ver ficha pública">
                    <i class="bi bi-eye"></i>
                  </a>
                </td>
              </tr>
            <% } %>

            <% if (!hayInmuebles) { %>
              <tr>
                <td colspan="5" class="text-center py-4 text-muted">
                  No tienes propiedades registradas aún. ¡Publica tu primer inmueble!
                </td>
              </tr>
            <% } %>
          </tbody>
        </table>
      </div>
    </div>
  </div>

  <!-- Citas pendientes por atender -->
  <div class="col-lg-4">
    <div class="card border-0 shadow-sm rounded-4 bg-white p-4 h-100">
      <div class="d-flex justify-content-between align-items-center mb-3">
        <h5 class="fw-bold text-navy mb-0">
          <i class="bi bi-bell-fill text-warning me-2"></i> Solicitudes de Cita
        </h5>
      </div>

      <div class="d-flex flex-column gap-3">
        <% 
          boolean hayCitasSol = false;
          while (rsCitas.next()) { 
            hayCitasSol = true;
            String cliente = rsCitas.getString("cli_nombres") + " " + rsCitas.getString("cli_apellidos");
        %>
          <div class="p-3 border rounded-3 bg-light">
            <div class="d-flex justify-content-between align-items-center mb-1">
              <span class="badge bg-warning text-dark"><i class="bi bi-clock"></i> Pendiente</span>
              <small class="text-muted"><%= rsCitas.getString("fecha_hora").substring(0, 16) %></small>
            </div>
            <div class="fw-bold text-navy small mb-1"><%= esc(rsCitas.getString("propiedad_titulo")) %></div>
            <div class="small text-secondary mb-2">
              <i class="bi bi-person me-1"></i> <%= esc(cliente) %> 
              &middot; <i class="bi bi-telephone me-1"></i> <%= esc(rsCitas.getString("cli_telefono")) %>
            </div>
            <% if (rsCitas.getString("mensaje") != null && !rsCitas.getString("mensaje").isEmpty()) { %>
              <div class="small fst-italic text-muted mb-2">"<%= esc(rsCitas.getString("mensaje")) %>"</div>
            <% } %>
          </div>
        <% } %>

        <% if (!hayCitasSol) { %>
          <div class="text-center py-4 text-muted">
            <i class="bi bi-check2-circle display-6 d-block mb-2 text-success"></i>
            ¡Al día! No tienes solicitudes de visita pendientes por confirmar.
          </div>
        <% } %>
      </div>
    </div>
  </div>

</div>

<%@ include file="/WEB-INF/jspf/pie.jspf" %>
<%
    } catch (SQLException ex) {
        out.println("<div class='alert alert-danger'>Error al cargar panel de agente: " + esc(ex.getMessage()) + "</div>");
    } finally {
        cerrar(rsCitas, psCitas, rsProps, psProps, rsStats, psStats, con);
    }
%>
