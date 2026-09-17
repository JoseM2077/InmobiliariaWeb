<%--
  inicio.jsp - Tablero principal diferenciado por rol
  Proyecto: InmobiliariaWeb
--%>
<%@ page contentType="text/html" pageEncoding="UTF-8" %>
<%
    String[] rolesPermitidos = {"ADMIN", "AGENTE", "CLIENTE"};
%>
<%@ include file="/WEB-INF/jspf/seguridad.jspf" %>
<%@ include file="/WEB-INF/jspf/conexion.jspf" %>
<%@ include file="/WEB-INF/jspf/utilidades.jspf" %>
<%
    String tituloPagina = "Panel de Control (" + rolSesion + ")";
    
    // Estadísticas según el rol del usuario autenticado
    int contador1 = 0, contador2 = 0, contador3 = 0, contador4 = 0;
    
    Connection con = null;
    PreparedStatement psEst = null;
    ResultSet rsEst = null;

    try {
        con = abrirConexion();

        if ("ADMIN".equalsIgnoreCase(rolSesion)) {
            // Stats para Administrador
            psEst = con.prepareStatement(
                "SELECT "
              + " (SELECT COUNT(*) FROM usuario WHERE activo = 1) AS c1, "
              + " (SELECT COUNT(*) FROM propiedad WHERE activo = 1) AS c2, "
              + " (SELECT COUNT(*) FROM cita WHERE estado = 'SOLICITADA' OR estado = 'CONFIRMADA') AS c3, "
              + " (SELECT COUNT(*) FROM solicitud WHERE estado = 'PENDIENTE' OR estado = 'EN_REVISION') AS c4"
            );
            rsEst = psEst.executeQuery();
            if (rsEst.next()) {
                contador1 = rsEst.getInt("c1"); // Usuarios
                contador2 = rsEst.getInt("c2"); // Propiedades
                contador3 = rsEst.getInt("c3"); // Citas activas
                contador4 = rsEst.getInt("c4"); // Solicitudes en curso
            }
        } else if ("AGENTE".equalsIgnoreCase(rolSesion)) {
            // Stats para Agente
            psEst = con.prepareStatement(
                "SELECT "
              + " (SELECT COUNT(*) FROM propiedad WHERE id_agente = ? AND activo = 1) AS c1, "
              + " (SELECT COUNT(*) FROM cita WHERE id_agente = ? AND estado = 'SOLICITADA') AS c2, "
              + " (SELECT COUNT(*) FROM cita WHERE id_agente = ? AND estado = 'CONFIRMADA') AS c3, "
              + " (SELECT COUNT(*) FROM solicitud s JOIN propiedad p ON p.id_propiedad = s.id_propiedad WHERE p.id_agente = ? AND s.estado = 'PENDIENTE') AS c4"
            );
            psEst.setInt(1, idUsuarioSesion);
            psEst.setInt(2, idUsuarioSesion);
            psEst.setInt(3, idUsuarioSesion);
            psEst.setInt(4, idUsuarioSesion);
            rsEst = psEst.executeQuery();
            if (rsEst.next()) {
                contador1 = rsEst.getInt("c1"); // Mis Inmuebles
                contador2 = rsEst.getInt("c2"); // Citas por confirmar
                contador3 = rsEst.getInt("c3"); // Citas confirmadas
                contador4 = rsEst.getInt("c4"); // Solicitudes pendientes
            }
        } else {
            // Stats para Cliente
            psEst = con.prepareStatement(
                "SELECT "
              + " (SELECT COUNT(*) FROM favorito WHERE id_usuario = ?) AS c1, "
              + " (SELECT COUNT(*) FROM cita WHERE id_cliente = ?) AS c2, "
              + " (SELECT COUNT(*) FROM solicitud WHERE id_cliente = ?) AS c3, "
              + " (SELECT COUNT(*) FROM propiedad WHERE activo = 1 AND estado = 'DISPONIBLE') AS c4"
            );
            psEst.setInt(1, idUsuarioSesion);
            psEst.setInt(2, idUsuarioSesion);
            psEst.setInt(3, idUsuarioSesion);
            rsEst = psEst.executeQuery();
            if (rsEst.next()) {
                contador1 = rsEst.getInt("c1"); // Favoritos
                contador2 = rsEst.getInt("c2"); // Mis Citas
                contador3 = rsEst.getInt("c3"); // Mis Solicitudes
                contador4 = rsEst.getInt("c4"); // Catálogo disponible
            }
        }
    } catch (SQLException ex) {
        // En caso de error continúa con contadores en 0
    } finally {
        cerrar(rsEst, psEst, con);
    }
%>
<%@ include file="/WEB-INF/jspf/cabecera.jspf" %>

<!-- Banner de Bienvenida -->
<div class="row mb-4">
  <div class="col-12">
    <div class="card border-0 shadow-sm bg-white p-4 rounded-4">
      <div class="d-flex flex-wrap justify-content-between align-items-center gap-3">
        <div>
          <span class="badge <%= "ADMIN".equalsIgnoreCase(rolSesion) ? "text-bg-danger" : ("AGENTE".equalsIgnoreCase(rolSesion) ? "text-bg-primary" : "text-bg-success") %> px-3 py-1 mb-2">
            <%= rolSesion %>
          </span>
          <h2 class="fw-bold text-navy mb-1">&iexcl;Bienvenido(a), <%= esc(nombreSesion) %>!</h2>
          <p class="text-muted mb-0">
            <i class="bi bi-calendar-check me-1"></i> Sesi&oacute;n iniciada con <code><%= esc(correoSesion) %></code>
          </p>
        </div>
        <div>
          <a href="<%= ctx %>/landing.jsp#catalogo" class="btn btn-warning fw-semibold shadow-sm">
            <i class="bi bi-search me-1"></i> Explorar Cat&aacute;logo P&uacute;blico
          </a>
        </div>
      </div>
    </div>
  </div>
</div>

<!-- Tarjetas de Métricas -->
<div class="row g-3 mb-4">
  
  <% if ("ADMIN".equalsIgnoreCase(rolSesion)) { %>
    <div class="col-sm-6 col-xl-3">
      <div class="card border-0 shadow-sm rounded-4 p-3 bg-white">
        <div class="d-flex align-items-center gap-3">
          <div class="feature-icon bg-danger-subtle text-danger mb-0">
            <i class="bi bi-people-fill"></i>
          </div>
          <div>
            <h6 class="text-muted small mb-1">Usuarios Activos</h6>
            <h3 class="fw-bold text-navy mb-0"><%= contador1 %></h3>
          </div>
        </div>
      </div>
    </div>
    <div class="col-sm-6 col-xl-3">
      <div class="card border-0 shadow-sm rounded-4 p-3 bg-white">
        <div class="d-flex align-items-center gap-3">
          <div class="feature-icon bg-primary-subtle text-primary mb-0">
            <i class="bi bi-buildings-fill"></i>
          </div>
          <div>
            <h6 class="text-muted small mb-1">Propiedades Registradas</h6>
            <h3 class="fw-bold text-navy mb-0"><%= contador2 %></h3>
          </div>
        </div>
      </div>
    </div>
    <div class="col-sm-6 col-xl-3">
      <div class="card border-0 shadow-sm rounded-4 p-3 bg-white">
        <div class="d-flex align-items-center gap-3">
          <div class="feature-icon bg-warning-subtle text-warning mb-0">
            <i class="bi bi-calendar-week-fill"></i>
          </div>
          <div>
            <h6 class="text-muted small mb-1">Citas en Tr&aacute;mite</h6>
            <h3 class="fw-bold text-navy mb-0"><%= contador3 %></h3>
          </div>
        </div>
      </div>
    </div>
    <div class="col-sm-6 col-xl-3">
      <div class="card border-0 shadow-sm rounded-4 p-3 bg-white">
        <div class="d-flex align-items-center gap-3">
          <div class="feature-icon bg-success-subtle text-success mb-0">
            <i class="bi bi-folder-check"></i>
          </div>
          <div>
            <h6 class="text-muted small mb-1">Solicitudes por Evaluar</h6>
            <h3 class="fw-bold text-navy mb-0"><%= contador4 %></h3>
          </div>
        </div>
      </div>
    </div>

  <% } else if ("AGENTE".equalsIgnoreCase(rolSesion)) { %>
    <div class="col-sm-6 col-xl-3">
      <div class="card border-0 shadow-sm rounded-4 p-3 bg-white">
        <div class="d-flex align-items-center gap-3">
          <div class="feature-icon bg-primary-subtle text-primary mb-0">
            <i class="bi bi-building-check"></i>
          </div>
          <div>
            <h6 class="text-muted small mb-1">Mis Inmuebles</h6>
            <h3 class="fw-bold text-navy mb-0"><%= contador1 %></h3>
          </div>
        </div>
      </div>
    </div>
    <div class="col-sm-6 col-xl-3">
      <div class="card border-0 shadow-sm rounded-4 p-3 bg-white">
        <div class="d-flex align-items-center gap-3">
          <div class="feature-icon bg-warning-subtle text-warning mb-0">
            <i class="bi bi-calendar-plus-fill"></i>
          </div>
          <div>
            <h6 class="text-muted small mb-1">Citas Solicitadas</h6>
            <h3 class="fw-bold text-navy mb-0"><%= contador2 %></h3>
          </div>
        </div>
      </div>
    </div>
    <div class="col-sm-6 col-xl-3">
      <div class="card border-0 shadow-sm rounded-4 p-3 bg-white">
        <div class="d-flex align-items-center gap-3">
          <div class="feature-icon bg-info-subtle text-info mb-0">
            <i class="bi bi-calendar2-check-fill"></i>
          </div>
          <div>
            <h6 class="text-muted small mb-1">Citas Confirmadas</h6>
            <h3 class="fw-bold text-navy mb-0"><%= contador3 %></h3>
          </div>
        </div>
      </div>
    </div>
    <div class="col-sm-6 col-xl-3">
      <div class="card border-0 shadow-sm rounded-4 p-3 bg-white">
        <div class="d-flex align-items-center gap-3">
          <div class="feature-icon bg-success-subtle text-success mb-0">
            <i class="bi bi-file-earmark-arrow-up-fill"></i>
          </div>
          <div>
            <h6 class="text-muted small mb-1">Solicitudes Pendientes</h6>
            <h3 class="fw-bold text-navy mb-0"><%= contador4 %></h3>
          </div>
        </div>
      </div>
    </div>

  <% } else { %>
    <div class="col-sm-6 col-xl-3">
      <div class="card border-0 shadow-sm rounded-4 p-3 bg-white">
        <div class="d-flex align-items-center gap-3">
          <div class="feature-icon bg-danger-subtle text-danger mb-0">
            <i class="bi bi-heart-fill"></i>
          </div>
          <div>
            <h6 class="text-muted small mb-1">Mis Favoritos</h6>
            <h3 class="fw-bold text-navy mb-0"><%= contador1 %></h3>
          </div>
        </div>
      </div>
    </div>
    <div class="col-sm-6 col-xl-3">
      <div class="card border-0 shadow-sm rounded-4 p-3 bg-white">
        <div class="d-flex align-items-center gap-3">
          <div class="feature-icon bg-primary-subtle text-primary mb-0">
            <i class="bi bi-calendar-event"></i>
          </div>
          <div>
            <h6 class="text-muted small mb-1">Visitas Solicitadas</h6>
            <h3 class="fw-bold text-navy mb-0"><%= contador2 %></h3>
          </div>
        </div>
      </div>
    </div>
    <div class="col-sm-6 col-xl-3">
      <div class="card border-0 shadow-sm rounded-4 p-3 bg-white">
        <div class="d-flex align-items-center gap-3">
          <div class="feature-icon bg-warning-subtle text-warning mb-0">
            <i class="bi bi-file-text-fill"></i>
          </div>
          <div>
            <h6 class="text-muted small mb-1">Tr&aacute;mites Radicados</h6>
            <h3 class="fw-bold text-navy mb-0"><%= contador3 %></h3>
          </div>
        </div>
      </div>
    </div>
    <div class="col-sm-6 col-xl-3">
      <div class="card border-0 shadow-sm rounded-4 p-3 bg-white">
        <div class="d-flex align-items-center gap-3">
          <div class="feature-icon bg-success-subtle text-success mb-0">
            <i class="bi bi-shop"></i>
          </div>
          <div>
            <h6 class="text-muted small mb-1">Inmuebles en Venta/Renta</h6>
            <h3 class="fw-bold text-navy mb-0"><%= contador4 %></h3>
          </div>
        </div>
      </div>
    </div>
  <% } %>

</div>

<!-- Acciones Rápidas del Sprint 1 -->
<div class="row g-4">
  <div class="col-lg-8">
    <div class="card border-0 shadow-sm rounded-4 p-4 bg-white h-100">
      <h5 class="fw-bold text-navy mb-3">
        <i class="bi bi-diagram-3-fill text-primary me-2"></i> M&oacute;dulos Disponibles
      </h5>
      <p class="text-muted small mb-4">
        Este entorno cuenta con la base de datos normalizada en 3FN, autenticaci&oacute;n segura mediante SHA-256 con salt, 
        control estricto de acceso por roles y cat&aacute;logo p&uacute;blico din&aacute;mico.
      </p>

      <div class="row g-3">
        <div class="col-md-6">
          <div class="p-3 border rounded-3 bg-light">
            <h6 class="fw-bold text-navy mb-1"><i class="bi bi-search text-primary me-1"></i> Cat&aacute;logo P&uacute;blico</h6>
            <p class="text-muted small mb-2">Consulte inmuebles por ciudad, tipo y precio con vista de fotos y datos de matr&iacute;cula.</p>
            <a href="<%= ctx %>/landing.jsp#catalogo" class="btn btn-sm btn-outline-primary">Ver Inmuebles</a>
          </div>
        </div>

        <div class="col-md-6">
          <div class="p-3 border rounded-3 bg-light">
            <h6 class="fw-bold text-navy mb-1"><i class="bi bi-person-circle text-primary me-1"></i> Sesi&oacute;n y Seguridad</h6>
            <p class="text-muted small mb-2">Su rol actual es <strong><%= rolSesion %></strong> con permisos validados en el servidor.</p>
            <a href="<%= ctx %>/logout.jsp" class="btn btn-sm btn-outline-danger">Cerrar Sesi&oacute;n</a>
          </div>
        </div>
      </div>
    </div>
  </div>

  <div class="col-lg-4">
    <div class="card border-0 shadow-sm rounded-4 p-4 bg-white h-100">
      <h5 class="fw-bold text-navy mb-3">
        <i class="bi bi-info-circle-fill text-warning me-2"></i> Datos del Proyecto
      </h5>
      <ul class="list-unstyled small text-muted">
        <li class="mb-2"><strong>Asignatura:</strong> Programaci&oacute;n Web Java</li>
        <li class="mb-2"><strong>Instituci&oacute;n:</strong> UTS Santander</li>
        <li class="mb-2"><strong>Arquitectura:</strong> JSP + JSPF + JDBC</li>
        <li class="mb-2"><strong>Motor BD:</strong> MySQL 8 (inmobiliaria_db)</li>
        <li class="mb-2"><strong>Contrase&ntilde;a Cifrada:</strong> SHA-256 (salt correo:clave)</li>
      </ul>
      <hr>
      <div class="text-center">
        <span class="badge bg-success-subtle text-success px-3 py-2 fw-semibold">Plataforma Operativa 100%</span>
      </div>
    </div>
  </div>
</div>

<%@ include file="/WEB-INF/jspf/pie.jspf" %>
