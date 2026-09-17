<%--
  cliente/agendar_cita.jsp - Interfaz de solicitud y consulta de citas para el CLIENTE
  Proyecto: InmobiliariaWeb
  Permite al cliente solicitar visitas a inmuebles, gestionar cancelaciones y ver sus citas agendadas.
--%>
<%@ page contentType="text/html" pageEncoding="UTF-8" %>
<%@ include file="/WEB-INF/jspf/conexion.jspf" %>
<%@ include file="/WEB-INF/jspf/utilidades.jspf" %>
<%
    String[] rolesPermitidos = {"CLIENTE", "ADMIN"};
%>
<%@ include file="/WEB-INF/jspf/seguridad.jspf" %>
<%
    String tituloPagina = "Agendamiento de Citas";
    int idPropPreseleccionada = aEntero(request.getParameter("id"), 0);

    Connection con = null;
    PreparedStatement psProps = null;
    ResultSet rsProps = null;
    PreparedStatement psCitas = null;
    ResultSet rsCitas = null;
    PreparedStatement psFavs = null;
    ResultSet rsFavs = null;

    try {
        con = abrirConexion();

        // 1) Listado de propiedades disponibles para el selector
        psProps = con.prepareStatement(
            "SELECT p.id_propiedad, p.codigo, p.titulo, p.precio, p.tipo_negocio, c.nombre AS ciudad "
          + "FROM propiedad p "
          + "JOIN ciudad c ON c.id_ciudad = p.id_ciudad "
          + "WHERE p.activo = 1 AND p.estado = 'DISPONIBLE' "
          + "ORDER BY p.titulo ASC"
        );
        rsProps = psProps.executeQuery();

        // 2) Listado de citas agendadas del cliente
        psCitas = con.prepareStatement(
            "SELECT c.id_cita, c.fecha_hora, c.estado, c.mensaje, c.fecha_creacion, "
          + "       p.id_propiedad, p.codigo, p.titulo, p.direccion, c_ciu.nombre AS ciudad, "
          + "       perf.nombres AS ag_nombres, perf.apellidos AS ag_apellidos, perf.telefono AS ag_tel "
          + "FROM cita c "
          + "JOIN propiedad p ON p.id_propiedad = c.id_propiedad "
          + "JOIN ciudad c_ciu ON c_ciu.id_ciudad = p.id_ciudad "
          + "JOIN usuario u ON u.id_usuario = c.id_agente "
          + "LEFT JOIN perfil perf ON perf.id_usuario = u.id_usuario "
          + "WHERE c.id_cliente = ? "
          + "ORDER BY c.fecha_hora DESC"
        );
        psCitas.setInt(1, idUsuarioSesion);
        rsCitas = psCitas.executeQuery();

        // 3) Favoritos del cliente
        psFavs = con.prepareStatement(
            "SELECT p.id_propiedad, p.codigo, p.titulo, p.precio, c.nombre AS ciudad "
          + "FROM favorito f "
          + "JOIN propiedad p ON p.id_propiedad = f.id_propiedad "
          + "JOIN ciudad c ON c.id_ciudad = p.id_ciudad "
          + "WHERE f.id_usuario = ? AND p.activo = 1"
        );
        psFavs.setInt(1, idUsuarioSesion);
        rsFavs = psFavs.executeQuery();
%>
<%@ include file="/WEB-INF/jspf/cabecera.jspf" %>

<div class="container my-4">

  <!-- Mensajes de Feedback -->
  <% if (request.getParameter("msg") != null) { %>
    <div class="alert alert-success alert-dismissible fade show shadow-sm" role="alert">
      <i class="bi bi-check-circle-fill me-2"></i> <%= esc(request.getParameter("msg")) %>
      <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
    </div>
  <% } %>
  <% if (request.getParameter("err") != null) { %>
    <div class="alert alert-danger alert-dismissible fade show shadow-sm" role="alert">
      <i class="bi bi-exclamation-octagon-fill me-2"></i> <%= esc(request.getParameter("err")) %>
      <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
    </div>
  <% } %>

  <div class="row g-4">
    
    <!-- Formulario de Agendamiento -->
    <div class="col-lg-5">
      <div class="card border-0 shadow-sm rounded-4 p-4 bg-white h-100">
        <h4 class="fw-bold text-navy mb-2">
          <i class="bi bi-calendar2-plus text-primary me-2"></i> Agendar Nueva Visita
        </h4>
        <p class="text-muted small mb-4">
          Seleccione el inmueble y el horario que mejor le convenga. Nuestro sistema verifica en tiempo real que el horario no esté ocupado.
        </p>

        <form method="post" action="<%= ctx %>/cliente/acciones_cita.jsp">
          <input type="hidden" name="accion" value="agendar">

          <div class="mb-3">
            <label for="id_propiedad" class="form-label small fw-semibold text-secondary">Inmueble a Visitar *</label>
            <select class="form-select" id="id_propiedad" name="id_propiedad" required>
              <option value="">Seleccione una propiedad...</option>
              <% while (rsProps.next()) { 
                  int pId = rsProps.getInt("id_propiedad");
                  String pCod = rsProps.getString("codigo");
                  String pTit = rsProps.getString("titulo");
                  String pCiu = rsProps.getString("ciudad");
                  double pPre = rsProps.getDouble("precio");
              %>
                <option value="<%= pId %>" <%= (idPropPreseleccionada == pId ? "selected" : "") %>>
                  <%= esc(pTit) %> [<%= esc(pCod) %>] - <%= esc(pCiu) %> (<%= pesos(pPre) %>)
                </option>
              <% } %>
            </select>
          </div>

          <div class="mb-3">
            <label for="fecha_hora" class="form-label small fw-semibold text-secondary">Fecha y Hora de la Visita *</label>
            <input type="datetime-local" class="form-control" id="fecha_hora" name="fecha_hora" required>
            <div class="form-text small">
              <i class="bi bi-info-circle"></i> Los horarios repetidos para el mismo inmueble son rechazados autom&aacute;ticamente.
            </div>
          </div>

          <div class="mb-4">
            <label for="mensaje" class="form-label small fw-semibold text-secondary">Mensaje u Observaciones para el Asesor</label>
            <textarea class="form-control" id="mensaje" name="mensaje" rows="3" placeholder="Ej: Visita con mi c&oacute;nyuge. Deseamos revisar la cocina y las &aacute;reas comunes."></textarea>
          </div>

          <button type="submit" class="btn btn-warning w-100 fw-bold py-2 shadow-sm text-dark">
            <i class="bi bi-calendar-check-fill me-1"></i> Confirmar Agendamiento
          </button>
        </form>
      </div>
    </div>

    <!-- Historial de Citas del Cliente -->
    <div class="col-lg-7">
      <div class="card border-0 shadow-sm rounded-4 p-4 bg-white h-100">
        <h4 class="fw-bold text-navy mb-3">
          <i class="bi bi-calendar-week text-primary me-2"></i> Mis Citas Agendadas
        </h4>

        <div class="table-responsive">
          <table class="table table-hover align-middle mb-0">
            <thead class="table-light">
              <tr>
                <th>Inmueble</th>
                <th>Fecha y Hora</th>
                <th>Asesor</th>
                <th>Estado</th>
                <th class="text-center">Acci&oacute;n</th>
              </tr>
            </thead>
            <tbody>
              <% 
                boolean hayCitas = false;
                while (rsCitas.next()) { 
                  hayCitas = true;
                  int cId = rsCitas.getInt("id_cita");
                  String est = rsCitas.getString("estado");
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
                    <div><%= esc(rsCitas.getString("ag_nombres")) %> <%= esc(rsCitas.getString("ag_apellidos")) %></div>
                    <div class="text-muted"><i class="bi bi-telephone"></i> <%= esc(rsCitas.getString("ag_tel")) %></div>
                  </td>
                  <td>
                    <span class="badge bg-<%= colorEstadoCita(est) %>"><%= est %></span>
                  </td>
                  <td class="text-center">
                    <% if ("SOLICITADA".equalsIgnoreCase(est) || "CONFIRMADA".equalsIgnoreCase(est)) { %>
                      <a href="<%= ctx %>/cliente/acciones_cita.jsp?accion=cancelar&id_cita=<%= cId %>" 
                         class="btn btn-outline-danger btn-sm" 
                         onclick="return confirm('&iquest;Est&aacute; seguro de cancelar esta cita?');"
                         title="Cancelar Cita">
                        <i class="bi bi-x-circle"></i> Cancelar
                      </a>
                    <% } else { %>
                      <span class="text-muted small">Sin acciones</span>
                    <% } %>
                  </td>
                </tr>
              <% } %>

              <% if (!hayCitas) { %>
                <tr>
                  <td colspan="5" class="text-center py-4 text-muted">
                    <i class="bi bi-calendar-x display-6 d-block mb-2 text-secondary"></i>
                    No tiene citas agendadas actualmente.
                  </td>
                </tr>
              <% } %>
            </tbody>
          </table>
        </div>

        <!-- Acceso directo a Favoritos para Agendar -->
        <div class="mt-4 pt-3 border-top">
          <h6 class="fw-bold text-navy mb-2"><i class="bi bi-heart-fill text-danger me-1"></i> Agendar desde mis Favoritos:</h6>
          <div class="d-flex flex-wrap gap-2">
            <% 
              boolean hayFavs = false;
              while (rsFavs.next()) { 
                hayFavs = true;
            %>
              <a href="<%= ctx %>/cliente/agendar_cita.jsp?id=<%= rsFavs.getInt("id_propiedad") %>" class="btn btn-sm btn-outline-secondary">
                <i class="bi bi-calendar-plus text-primary me-1"></i> <%= esc(rsFavs.getString("titulo")) %>
              </a>
            <% } %>
            <% if (!hayFavs) { %>
              <small class="text-muted">A&uacute;n no tiene inmuebles en favoritos.</small>
            <% } %>
          </div>
        </div>

      </div>
    </div>

  </div>

</div>

<%@ include file="/WEB-INF/jspf/pie.jspf" %>
<%
    } catch (SQLException ex) {
        out.println("<div class='alert alert-danger'>Error al cargar citas: " + esc(ex.getMessage()) + "</div>");
    } finally {
        cerrar(rsFavs, psFavs, rsCitas, psCitas, rsProps, psProps, con);
    }
%>
