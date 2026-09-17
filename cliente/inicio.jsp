<%--
  cliente/inicio.jsp - Dashboard exclusivo para el rol CLIENTE
  Proyecto: InmobiliariaWeb
--%>
<%@ page contentType="text/html" pageEncoding="UTF-8" %>
<%
    String[] rolesPermitidos = {"CLIENTE", "ADMIN"};
%>
<%@ include file="/WEB-INF/jspf/seguridad.jspf" %>
<%@ include file="/WEB-INF/jspf/conexion.jspf" %>
<%@ include file="/WEB-INF/jspf/utilidades.jspf" %>
<%
    String tituloPagina = "Panel del Cliente";

    Connection con = null;
    PreparedStatement psStats = null;
    ResultSet rsStats = null;
    PreparedStatement psCitas = null;
    ResultSet rsCitas = null;
    PreparedStatement psFavs = null;
    ResultSet rsFavs = null;

    int totalCitas = 0;
    int totalSolicitudes = 0;
    int totalFavoritos = 0;
    int totalDisponibles = 0;

    try {
        con = abrirConexion();

        // 1) Contadores del cliente
        psStats = con.prepareStatement(
            "SELECT "
          + "  (SELECT COUNT(*) FROM cita WHERE id_cliente = ?) AS c_citas, "
          + "  (SELECT COUNT(*) FROM solicitud WHERE id_cliente = ?) AS c_solicitudes, "
          + "  (SELECT COUNT(*) FROM favorito WHERE id_usuario = ?) AS c_favoritos, "
          + "  (SELECT COUNT(*) FROM propiedad WHERE activo = 1 AND estado = 'DISPONIBLE') AS c_disponibles"
        );
        psStats.setInt(1, idUsuarioSesion);
        psStats.setInt(2, idUsuarioSesion);
        psStats.setInt(3, idUsuarioSesion);
        rsStats = psStats.executeQuery();
        if (rsStats.next()) {
            totalCitas = rsStats.getInt("c_citas");
            totalSolicitudes = rsStats.getInt("c_solicitudes");
            totalFavoritos = rsStats.getInt("c_favoritos");
            totalDisponibles = rsStats.getInt("c_disponibles");
        }

        // 2) Próximas citas agendadas del cliente
        psCitas = con.prepareStatement(
            "SELECT c.id_cita, c.fecha_hora, c.estado, c.mensaje, p.id_propiedad, p.titulo, p.direccion, "
          + "       perf.nombres AS agente_nombres, perf.apellidos AS agente_apellidos, perf.telefono AS agente_tel "
          + "FROM cita c "
          + "JOIN propiedad p ON p.id_propiedad = c.id_propiedad "
          + "JOIN usuario u ON u.id_usuario = c.id_agente "
          + "LEFT JOIN perfil perf ON perf.id_usuario = u.id_usuario "
          + "WHERE c.id_cliente = ? "
          + "ORDER BY c.fecha_hora ASC LIMIT 4"
        );
        psCitas.setInt(1, idUsuarioSesion);
        rsCitas = psCitas.executeQuery();

        // 3) Inmuebles marcados como favoritos
        psFavs = con.prepareStatement(
            "SELECT p.id_propiedad, p.codigo, p.titulo, p.precio, p.tipo_negocio, c.nombre AS ciudad, "
          + "       (SELECT ip.url_imagen FROM imagen_propiedad ip WHERE ip.id_propiedad = p.id_propiedad ORDER BY ip.es_principal DESC, ip.orden ASC LIMIT 1) AS imagen "
          + "FROM favorito f "
          + "JOIN propiedad p ON p.id_propiedad = f.id_propiedad "
          + "JOIN ciudad c ON c.id_ciudad = p.id_ciudad "
          + "WHERE f.id_usuario = ? AND p.activo = 1 "
          + "ORDER BY f.fecha_agregado DESC LIMIT 3"
        );
        psFavs.setInt(1, idUsuarioSesion);
        rsFavs = psFavs.executeQuery();
%>
<%@ include file="/WEB-INF/jspf/cabecera.jspf" %>

<!-- Encabezado del Dashboard -->
<div class="row mb-4">
  <div class="col-12">
    <div class="card border-0 shadow-sm bg-white p-4 rounded-4">
      <div class="d-flex flex-wrap justify-content-between align-items-center gap-3">
        <div>
          <span class="badge text-bg-success px-3 py-1 mb-2">Rol Cliente</span>
          <h2 class="fw-bold text-navy mb-1">&iexcl;Hola, <%= esc(nombreSesion) %>!</h2>
          <p class="text-muted mb-0">
            <i class="bi bi-person-badge text-success me-1"></i> Bienvenido a su panel de gesti&oacute;n inmobiliaria personal.
          </p>
        </div>
        <div class="d-flex gap-2">
          <a href="<%= ctx %>/landing.jsp#catalogo" class="btn btn-warning fw-semibold shadow-sm">
            <i class="bi bi-search me-1"></i> Explorar Cat&aacute;logo
          </a>
        </div>
      </div>
    </div>
  </div>
</div>

<!-- Tarjetas de Métricas -->
<div class="row g-3 mb-4">
  <div class="col-sm-6 col-xl-3">
    <div class="card border-0 shadow-sm rounded-4 p-3 bg-white h-100">
      <div class="d-flex align-items-center gap-3">
        <div class="feature-icon bg-primary-subtle text-primary mb-0">
          <i class="bi bi-calendar-check-fill"></i>
        </div>
        <div>
          <h6 class="text-muted small mb-1">Citas Agendadas</h6>
          <h3 class="fw-bold text-navy mb-0"><%= totalCitas %></h3>
        </div>
      </div>
    </div>
  </div>

  <div class="col-sm-6 col-xl-3">
    <div class="card border-0 shadow-sm rounded-4 p-3 bg-white h-100">
      <div class="d-flex align-items-center gap-3">
        <div class="feature-icon bg-warning-subtle text-warning mb-0">
          <i class="bi bi-file-earmark-text-fill"></i>
        </div>
        <div>
          <h6 class="text-muted small mb-1">Solicitudes Radicadas</h6>
          <h3 class="fw-bold text-navy mb-0"><%= totalSolicitudes %></h3>
        </div>
      </div>
    </div>
  </div>

  <div class="col-sm-6 col-xl-3">
    <div class="card border-0 shadow-sm rounded-4 p-3 bg-white h-100">
      <div class="d-flex align-items-center gap-3">
        <div class="feature-icon bg-danger-subtle text-danger mb-0">
          <i class="bi bi-heart-fill"></i>
        </div>
        <div>
          <h6 class="text-muted small mb-1">Mis Favoritos</h6>
          <h3 class="fw-bold text-navy mb-0"><%= totalFavoritos %></h3>
        </div>
      </div>
    </div>
  </div>

  <div class="col-sm-6 col-xl-3">
    <div class="card border-0 shadow-sm rounded-4 p-3 bg-white h-100">
      <div class="d-flex align-items-center gap-3">
        <div class="feature-icon bg-success-subtle text-success mb-0">
          <i class="bi bi-buildings-fill"></i>
        </div>
        <div>
          <h6 class="text-muted small mb-1">Inmuebles en Cat&aacute;logo</h6>
          <h3 class="fw-bold text-navy mb-0"><%= totalDisponibles %></h3>
        </div>
      </div>
    </div>
  </div>
</div>

<!-- Contenido: Mis Citas e Inmuebles Favoritos -->
<div class="row g-4">
  
  <!-- Columna Izquierda: Mis Citas -->
  <div class="col-lg-7">
    <div class="card border-0 shadow-sm rounded-4 bg-white p-4 h-100">
      <div class="d-flex justify-content-between align-items-center mb-3">
        <h5 class="fw-bold text-navy mb-0">
          <i class="bi bi-calendar-event text-primary me-2"></i> Mis Pr&oacute;ximas Visitas Agendadas
        </h5>
      </div>

      <div class="table-responsive">
        <table class="table table-hover align-middle mb-0">
          <thead class="table-light">
            <tr>
              <th>Inmueble</th>
              <th>Fecha y Hora</th>
              <th>Asesor</th>
              <th>Estado</th>
            </tr>
          </thead>
          <tbody>
            <% 
              boolean hayCitas = false;
              while (rsCitas.next()) { 
                hayCitas = true;
                String estCita = rsCitas.getString("estado");
                String nomAgente = rsCitas.getString("agente_nombres") + " " + rsCitas.getString("agente_apellidos");
            %>
              <tr>
                <td>
                  <a href="<%= ctx %>/detalle_propiedad.jsp?id=<%= rsCitas.getInt("id_propiedad") %>" class="fw-semibold text-decoration-none text-navy">
                    <%= esc(rsCitas.getString("titulo")) %>
                  </a>
                  <div class="small text-muted"><%= esc(rsCitas.getString("direccion")) %></div>
                </td>
                <td class="small fw-semibold text-secondary">
                  <i class="bi bi-clock me-1"></i> <%= rsCitas.getString("fecha_hora").substring(0, 16) %>
                </td>
                <td class="small">
                  <div><%= esc(nomAgente) %></div>
                  <div class="text-muted"><i class="bi bi-telephone"></i> <%= esc(rsCitas.getString("agente_tel")) %></div>
                </td>
                <td>
                  <span class="badge bg-<%= colorEstadoCita(estCita) %>">
                    <%= estCita %>
                  </span>
                </td>
              </tr>
            <% } %>

            <% if (!hayCitas) { %>
              <tr>
                <td colspan="4" class="text-center py-4 text-muted">
                  <i class="bi bi-calendar-x display-6 d-block mb-2 text-secondary"></i>
                  A&uacute;n no tiene visitas agendadas. &iexcl;Explore el cat&aacute;logo y agende su primera cita!
                </td>
              </tr>
            <% } %>
          </tbody>
        </table>
      </div>
    </div>
  </div>

  <!-- Columna Derecha: Favoritos Destacados -->
  <div class="col-lg-5">
    <div class="card border-0 shadow-sm rounded-4 bg-white p-4 h-100">
      <div class="d-flex justify-content-between align-items-center mb-3">
        <h5 class="fw-bold text-navy mb-0">
          <i class="bi bi-heart-fill text-danger me-2"></i> Mis Inmuebles Favoritos
        </h5>
      </div>

      <div class="d-flex flex-column gap-3">
        <% 
          boolean hayFavs = false;
          while (rsFavs.next()) { 
            hayFavs = true;
            String fImg = rsFavs.getString("imagen");
            if (fImg == null || fImg.isEmpty()) fImg = "https://images.unsplash.com/photo-1560518883-ce09059eeffa?w=400";
        %>
          <div class="d-flex align-items-center gap-3 p-2 border rounded-3 bg-light">
            <img src="<%= fImg %>" alt="Foto" class="rounded-3 object-fit-cover" style="width: 80px; height: 70px;">
            <div class="flex-grow-1 min-w-0">
              <span class="badge <%= "VENTA".equalsIgnoreCase(rsFavs.getString("tipo_negocio")) ? "bg-primary" : "bg-success" %> small mb-1">
                <%= rsFavs.getString("tipo_negocio") %>
              </span>
              <h6 class="mb-0 text-truncate fw-bold text-navy">
                <a href="<%= ctx %>/detalle_propiedad.jsp?id=<%= rsFavs.getInt("id_propiedad") %>" class="text-decoration-none text-navy">
                  <%= esc(rsFavs.getString("titulo")) %>
                </a>
              </h6>
              <div class="small text-muted"><%= esc(rsFavs.getString("ciudad")) %> &middot; <strong class="text-dark"><%= pesos(rsFavs.getDouble("precio")) %></strong></div>
            </div>
            <div>
              <a href="<%= ctx %>/detalle_propiedad.jsp?id=<%= rsFavs.getInt("id_propiedad") %>" class="btn btn-sm btn-outline-primary" title="Ver ficha">
                <i class="bi bi-arrow-right"></i>
              </a>
            </div>
          </div>
        <% } %>

        <% if (!hayFavs) { %>
          <div class="text-center py-4 text-muted">
            <i class="bi bi-bookmark-heart display-6 d-block mb-2 text-secondary"></i>
            No ha guardado ning&uacute;n inmueble como favorito todav&iacute;a.
          </div>
        <% } %>
      </div>
    </div>
  </div>

</div>

<%@ include file="/WEB-INF/jspf/pie.jspf" %>
<%
    } catch (SQLException ex) {
        out.println("<div class='alert alert-danger'>Error al cargar panel de cliente: " + esc(ex.getMessage()) + "</div>");
    } finally {
        cerrar(rsFavs, psFavs, rsCitas, psCitas, rsStats, psStats, con);
    }
%>
