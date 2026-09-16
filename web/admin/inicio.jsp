<%--
  admin/inicio.jsp - Tablero general de control para el rol ADMINISTRADOR
  Proyecto: InmobiliariaWeb
--%>
<%@ page contentType="text/html" pageEncoding="UTF-8" %>
<%
    String[] rolesPermitidos = {"ADMIN"};
%>
<%@ include file="/WEB-INF/jspf/seguridad.jspf" %>
<%@ include file="/WEB-INF/jspf/conexion.jspf" %>
<%@ include file="/WEB-INF/jspf/utilidades.jspf" %>
<%
    String tituloPagina = "Panel de Administración";

    Connection con = null;
    PreparedStatement psStats = null;
    ResultSet rsStats = null;
    PreparedStatement psUsuarios = null;
    ResultSet rsUsuarios = null;
    PreparedStatement psCiudades = null;
    ResultSet rsCiudades = null;

    int totalUsuarios = 0;
    int totalPropiedades = 0;
    int totalCitas = 0;
    int totalSolicitudes = 0;
    int totalCiudades = 0;
    int totalTipos = 0;

    try {
        con = abrirConexion();

        // 1) Métricas globales del sistema
        psStats = con.prepareStatement(
            "SELECT "
          + "  (SELECT COUNT(*) FROM usuario) AS c_usuarios, "
          + "  (SELECT COUNT(*) FROM propiedad) AS c_propiedades, "
          + "  (SELECT COUNT(*) FROM cita) AS c_citas, "
          + "  (SELECT COUNT(*) FROM solicitud) AS c_solicitudes, "
          + "  (SELECT COUNT(*) FROM ciudad WHERE activo = 1) AS c_ciudades, "
          + "  (SELECT COUNT(*) FROM tipo_propiedad WHERE activo = 1) AS c_tipos"
        );
        rsStats = psStats.executeQuery();
        if (rsStats.next()) {
            totalUsuarios    = rsStats.getInt("c_usuarios");
            totalPropiedades = rsStats.getInt("c_propiedades");
            totalCitas       = rsStats.getInt("c_citas");
            totalSolicitudes = rsStats.getInt("c_solicitudes");
            totalCiudades    = rsStats.getInt("c_ciudades");
            totalTipos       = rsStats.getInt("c_tipos");
        }

        // 2) Últimos usuarios registrados con sus roles
        psUsuarios = con.prepareStatement(
            "SELECT u.id_usuario, u.correo, u.activo, u.fecha_registro, "
          + "       p.nombres, p.apellidos, p.documento, p.telefono, "
          + "       (SELECT r.nombre FROM usuario_rol ur JOIN rol r ON r.id_rol = ur.id_rol WHERE ur.id_usuario = u.id_usuario LIMIT 1) AS rol_nombre "
          + "FROM usuario u "
          + "LEFT JOIN perfil p ON p.id_usuario = u.id_usuario "
          + "ORDER BY u.id_usuario DESC LIMIT 6"
        );
        rsUsuarios = psUsuarios.executeQuery();

        // 3) Distribución de propiedades por ciudad
        psCiudades = con.prepareStatement(
            "SELECT c.nombre AS ciudad, COUNT(p.id_propiedad) AS cantidad "
          + "FROM ciudad c "
          + "LEFT JOIN propiedad p ON p.id_ciudad = c.id_ciudad AND p.activo = 1 "
          + "GROUP BY c.id_ciudad, c.nombre "
          + "ORDER BY cantidad DESC LIMIT 5"
        );
        rsCiudades = psCiudades.executeQuery();
%>
<%@ include file="/WEB-INF/jspf/cabecera.jspf" %>

<!-- Encabezado del Panel Admin -->
<div class="row mb-4">
  <div class="col-12">
    <div class="card border-0 shadow-sm bg-white p-4 rounded-4">
      <div class="d-flex flex-wrap justify-content-between align-items-center gap-3">
        <div>
          <span class="badge text-bg-danger px-3 py-1 mb-2">Administrador General</span>
          <h2 class="fw-bold text-navy mb-1">Panel de Control del Sistema</h2>
          <p class="text-muted mb-0">
            <i class="bi bi-shield-check text-danger me-1"></i> Supervisión de catálogos, cuentas de usuario, métricas globales y auditoría.
          </p>
        </div>
        <div class="d-flex gap-2">
          <a href="<%= ctx %>/agente/propiedades.jsp" class="btn btn-outline-primary fw-semibold">
            <i class="bi bi-houses me-1"></i> Ver Inmuebles
          </a>
          <a href="<%= ctx %>/landing.jsp" class="btn btn-warning fw-semibold shadow-sm">
            <i class="bi bi-eye me-1"></i> Vista Pública
          </a>
        </div>
      </div>
    </div>
  </div>
</div>

<!-- Métricas Globales -->
<div class="row g-3 mb-4">
  <div class="col-sm-6 col-xl-2">
    <div class="card border-0 shadow-sm rounded-4 p-3 bg-white h-100 text-center">
      <div class="feature-icon bg-danger-subtle text-danger mx-auto mb-2">
        <i class="bi bi-people-fill"></i>
      </div>
      <h6 class="text-muted small mb-1">Usuarios</h6>
      <h3 class="fw-bold text-navy mb-0"><%= totalUsuarios %></h3>
    </div>
  </div>

  <div class="col-sm-6 col-xl-2">
    <div class="card border-0 shadow-sm rounded-4 p-3 bg-white h-100 text-center">
      <div class="feature-icon bg-primary-subtle text-primary mx-auto mb-2">
        <i class="bi bi-buildings-fill"></i>
      </div>
      <h6 class="text-muted small mb-1">Inmuebles</h6>
      <h3 class="fw-bold text-navy mb-0"><%= totalPropiedades %></h3>
    </div>
  </div>

  <div class="col-sm-6 col-xl-2">
    <div class="card border-0 shadow-sm rounded-4 p-3 bg-white h-100 text-center">
      <div class="feature-icon bg-warning-subtle text-warning mx-auto mb-2">
        <i class="bi bi-calendar-event-fill"></i>
      </div>
      <h6 class="text-muted small mb-1">Citas</h6>
      <h3 class="fw-bold text-navy mb-0"><%= totalCitas %></h3>
    </div>
  </div>

  <div class="col-sm-6 col-xl-2">
    <div class="card border-0 shadow-sm rounded-4 p-3 bg-white h-100 text-center">
      <div class="feature-icon bg-success-subtle text-success mx-auto mb-2">
        <i class="bi bi-folder-check"></i>
      </div>
      <h6 class="text-muted small mb-1">Solicitudes</h6>
      <h3 class="fw-bold text-navy mb-0"><%= totalSolicitudes %></h3>
    </div>
  </div>

  <div class="col-sm-6 col-xl-2">
    <div class="card border-0 shadow-sm rounded-4 p-3 bg-white h-100 text-center">
      <div class="feature-icon bg-info-subtle text-info mx-auto mb-2">
        <i class="bi bi-geo-alt-fill"></i>
      </div>
      <h6 class="text-muted small mb-1">Ciudades</h6>
      <h3 class="fw-bold text-navy mb-0"><%= totalCiudades %></h3>
    </div>
  </div>

  <div class="col-sm-6 col-xl-2">
    <div class="card border-0 shadow-sm rounded-4 p-3 bg-white h-100 text-center">
      <div class="feature-icon bg-secondary-subtle text-secondary mx-auto mb-2">
        <i class="bi bi-tags-fill"></i>
      </div>
      <h6 class="text-muted small mb-1">Tipos</h6>
      <h3 class="fw-bold text-navy mb-0"><%= totalTipos %></h3>
    </div>
  </div>
</div>

<!-- Tablas de Gestión Administrativa -->
<div class="row g-4">
  
  <!-- Usuarios Recientes -->
  <div class="col-lg-8">
    <div class="card border-0 shadow-sm rounded-4 bg-white p-4 h-100">
      <div class="d-flex justify-content-between align-items-center mb-3">
        <h5 class="fw-bold text-navy mb-0">
          <i class="bi bi-person-lines-fill text-danger me-2"></i> Usuarios y Cuentas Registradas
        </h5>
        <span class="badge bg-light text-muted border">Total: <%= totalUsuarios %> cuentas</span>
      </div>

      <div class="table-responsive">
        <table class="table table-hover align-middle mb-0">
          <thead class="table-light">
            <tr>
              <th>Usuario / Nombre</th>
              <th>Documento</th>
              <th>Rol Asignado</th>
              <th>Estado</th>
            </tr>
          </thead>
          <tbody>
            <% while (rsUsuarios.next()) { 
                String uRol = rsUsuarios.getString("rol_nombre");
                if (uRol == null) uRol = "CLIENTE";
                boolean uActivo = rsUsuarios.getBoolean("activo");
                String uNombre = rsUsuarios.getString("nombres") + " " + rsUsuarios.getString("apellidos");
            %>
              <tr>
                <td>
                  <div class="fw-bold text-navy"><%= esc(uNombre) %></div>
                  <div class="small text-muted"><i class="bi bi-envelope me-1"></i> <%= esc(rsUsuarios.getString("correo")) %></div>
                </td>
                <td class="small">
                  <code><%= esc(rsUsuarios.getString("documento")) %></code>
                  <div class="text-muted"><%= esc(rsUsuarios.getString("telefono")) %></div>
                </td>
                <td>
                  <span class="badge <%= "ADMIN".equalsIgnoreCase(uRol) ? "text-bg-danger" : ("AGENTE".equalsIgnoreCase(uRol) ? "text-bg-primary" : "text-bg-success") %>">
                    <%= uRol %>
                  </span>
                </td>
                <td>
                  <% if (uActivo) { %>
                    <span class="badge bg-success-subtle text-success"><i class="bi bi-check-circle"></i> Activo</span>
                  <% } else { %>
                    <span class="badge bg-danger-subtle text-danger"><i class="bi bi-x-circle"></i> Inactivo</span>
                  <% } %>
                </td>
              </tr>
            <% } %>
          </tbody>
        </table>
      </div>
    </div>
  </div>

  <!-- Inmuebles por Ciudad -->
  <div class="col-lg-4">
    <div class="card border-0 shadow-sm rounded-4 bg-white p-4 h-100">
      <div class="d-flex justify-content-between align-items-center mb-3">
        <h5 class="fw-bold text-navy mb-0">
          <i class="bi bi-pie-chart-fill text-primary me-2"></i> Inmuebles por Ciudad
        </h5>
      </div>

      <div class="list-group list-group-flush">
        <% while (rsCiudades.next()) { %>
          <div class="list-group-item d-flex justify-content-between align-items-center px-0 py-3">
            <div>
              <i class="bi bi-geo-alt text-danger me-2"></i>
              <span class="fw-semibold text-navy"><%= esc(rsCiudades.getString("ciudad")) %></span>
            </div>
            <span class="badge bg-primary rounded-pill px-3">
              <%= rsCiudades.getInt("cantidad") %> inmuebles
            </span>
          </div>
        <% } %>
      </div>

      <div class="mt-auto pt-3 border-top text-center">
        <small class="text-muted">Gestión de Catálogos e Integridad Referencial 3FN</small>
      </div>
    </div>
  </div>

</div>

<%@ include file="/WEB-INF/jspf/pie.jspf" %>
<%
    } catch (SQLException ex) {
        out.println("<div class='alert alert-danger'>Error al cargar panel de administración: " + esc(ex.getMessage()) + "</div>");
    } finally {
        cerrar(rsCiudades, psCiudades, rsUsuarios, psUsuarios, rsStats, psStats, con);
    }
%>
