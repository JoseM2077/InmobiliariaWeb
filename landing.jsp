<%--
  landing.jsp - Página pública de aterrizaje y catálogo de propiedades
  Proyecto: InmobiliariaWeb
--%>
<%@ page contentType="text/html" pageEncoding="UTF-8" %>
<%@ include file="/WEB-INF/jspf/conexion.jspf" %>
<%@ include file="/WEB-INF/jspf/utilidades.jspf" %>
<%
    String tituloPagina = "Portal Inmobiliario - Propiedades Exclusivas";
    request.setCharacterEncoding("UTF-8");

    // Parámetros del buscador rápido
    int filtroCiudad  = aEntero(request.getParameter("ciudad"), 0);
    int filtroTipo    = aEntero(request.getParameter("tipo"), 0);
    String filtroNegocio = request.getParameter("negocio");
    if (filtroNegocio != null) filtroNegocio = filtroNegocio.trim();
    double filtroPrecioMax = aDoble(request.getParameter("precioMax"), 0.0);

    Connection con = null;
    PreparedStatement psCiudades = null;
    ResultSet rsCiudades = null;
    PreparedStatement psTipos = null;
    ResultSet rsTipos = null;
    PreparedStatement psProps = null;
    ResultSet rsProps = null;

    try {
        con = abrirConexion();

        // 1) Listado de ciudades activas para el combo
        psCiudades = con.prepareStatement("SELECT id_ciudad, nombre, departamento FROM ciudad WHERE activo = 1 ORDER BY nombre");
        rsCiudades = psCiudades.executeQuery();

        // 2) Listado de tipos de propiedad para el combo
        psTipos = con.prepareStatement("SELECT id_tipo, nombre FROM tipo_propiedad WHERE activo = 1 ORDER BY nombre");
        rsTipos = psTipos.executeQuery();

        // 3) Consulta dinámica de propiedades con filtros
        StringBuilder sql = new StringBuilder();
        sql.append("SELECT p.id_propiedad, p.codigo, p.matricula_inmobiliaria, p.titulo, p.descripcion, ")
           .append("       p.precio, p.tipo_negocio, p.direccion, p.area_m2, p.habitaciones, p.banos, ")
           .append("       p.parqueaderos, p.estado, p.destacada, c.nombre AS ciudad, tp.nombre AS tipo, ")
           .append("       (SELECT ip.url_imagen FROM imagen_propiedad ip WHERE ip.id_propiedad = p.id_propiedad ORDER BY ip.es_principal DESC, ip.orden ASC LIMIT 1) AS imagen ")
           .append("FROM propiedad p ")
           .append("JOIN ciudad c ON c.id_ciudad = p.id_ciudad ")
           .append("JOIN tipo_propiedad tp ON tp.id_tipo = p.id_tipo ")
           .append("WHERE p.activo = 1 AND p.estado = 'DISPONIBLE' ");

        if (filtroCiudad > 0) sql.append(" AND p.id_ciudad = ? ");
        if (filtroTipo > 0)   sql.append(" AND p.id_tipo = ? ");
        if (filtroNegocio != null && !filtroNegocio.isEmpty() && !"TODOS".equalsIgnoreCase(filtroNegocio)) {
            sql.append(" AND p.tipo_negocio = ? ");
        }
        if (filtroPrecioMax > 0) sql.append(" AND p.precio <= ? ");

        sql.append(" ORDER BY p.destacada DESC, p.fecha_publicacion DESC");

        psProps = con.prepareStatement(sql.toString());
        int paramIdx = 1;
        if (filtroCiudad > 0) psProps.setInt(paramIdx++, filtroCiudad);
        if (filtroTipo > 0)   psProps.setInt(paramIdx++, filtroTipo);
        if (filtroNegocio != null && !filtroNegocio.isEmpty() && !"TODOS".equalsIgnoreCase(filtroNegocio)) {
            psProps.setString(paramIdx++, filtroNegocio);
        }
        if (filtroPrecioMax > 0) psProps.setDouble(paramIdx++, filtroPrecioMax);

        rsProps = psProps.executeQuery();
%>
<%@ include file="/WEB-INF/jspf/cabecera.jspf" %>

<%-- Mensaje de alerta por permisos o cierre de sesión --%>
<%
    String msg = request.getParameter("msg");
    String error = request.getParameter("error");
%>
<% if ("logout".equals(msg)) { %>
  <div class="container mt-3">
    <div class="alert alert-info alert-dismissible fade show shadow-sm" role="alert">
      <i class="bi bi-info-circle-fill me-2"></i> Ha cerrado sesión correctamente. ¡Esperamos verle pronto!
      <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
    </div>
  </div>
<% } else if ("permiso".equals(error)) { %>
  <div class="container mt-3">
    <div class="alert alert-warning alert-dismissible fade show shadow-sm" role="alert">
      <i class="bi bi-shield-exclamation me-2"></i> Acceso restringido. Su rol actual no tiene privilegios para ingresar al recurso solicitado.
      <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
    </div>
  </div>
<% } %>

<!-- HERO BANNER -->
<section class="hero-banner text-center text-md-start">
  <div class="container">
    <div class="row align-items-center">
      <div class="col-lg-8">
        <span class="badge bg-warning text-dark px-3 py-2 text-uppercase fw-bold mb-3 shadow-sm">
          <i class="bi bi-star-fill me-1"></i> Excelencia Inmobiliaria en Santander
        </span>
        <h1 class="hero-title mb-3">
          El inmueble ideal para tu familia o tu empresa comienza aquí
        </h1>
        <p class="lead text-white-50 mb-4">
          Explora nuestra selecta oferta de apartamentos, casas campestres, locales comerciales, oficinas y lotes con respaldo legal integral.
        </p>
        <div class="d-flex flex-wrap gap-3">
          <a href="#catalogo" class="btn btn-warning btn-lg px-4 fw-bold">
            <i class="bi bi-search me-1"></i> Explorar Catálogo
          </a>
          <a href="<%= ctx %>/registro.jsp" class="btn btn-outline-light btn-lg px-4">
            <i class="bi bi-person-plus me-1"></i> Crear Cuenta Gratis
          </a>
        </div>
      </div>
    </div>
  </div>
</section>

<!-- BUSCADOR RÁPIDO -->
<div class="container">
  <div class="buscador-card">
    <form method="get" action="<%= ctx %>/landing.jsp#catalogo" class="row g-3 align-items-end">
      
      <div class="col-md-3">
        <label for="ciudad" class="form-label fw-semibold text-secondary small">
          <i class="bi bi-geo-alt text-primary"></i> Ciudad
        </label>
        <select class="form-select" id="ciudad" name="ciudad">
          <option value="0">Todas las ciudades</option>
          <% while (rsCiudades.next()) { 
              int cId = rsCiudades.getInt("id_ciudad");
              String cNombre = rsCiudades.getString("nombre");
              String cDepto = rsCiudades.getString("departamento");
          %>
            <option value="<%= cId %>" <%= (filtroCiudad == cId ? "selected" : "") %>>
              <%= esc(cNombre) %> (<%= esc(cDepto) %>)
            </option>
          <% } %>
        </select>
      </div>

      <div class="col-md-3">
        <label for="tipo" class="form-label fw-semibold text-secondary small">
          <i class="bi bi-house-door text-primary"></i> Tipo de Inmueble
        </label>
        <select class="form-select" id="tipo" name="tipo">
          <option value="0">Todos los tipos</option>
          <% while (rsTipos.next()) { 
              int tId = rsTipos.getInt("id_tipo");
              String tNombre = rsTipos.getString("nombre");
          %>
            <option value="<%= tId %>" <%= (filtroTipo == tId ? "selected" : "") %>>
              <%= esc(tNombre) %>
            </option>
          <% } %>
        </select>
      </div>

      <div class="col-md-2">
        <label for="negocio" class="form-label fw-semibold text-secondary small">
          <i class="bi bi-tags text-primary"></i> Negocio
        </label>
        <select class="form-select" id="negocio" name="negocio">
          <option value="TODOS" <%= ("TODOS".equalsIgnoreCase(filtroNegocio) ? "selected" : "") %>>Todos</option>
          <option value="VENTA" <%= ("VENTA".equalsIgnoreCase(filtroNegocio) ? "selected" : "") %>>En Venta</option>
          <option value="ARRIENDO" <%= ("ARRIENDO".equalsIgnoreCase(filtroNegocio) ? "selected" : "") %>>En Arriendo</option>
        </select>
      </div>

      <div class="col-md-2">
        <label for="precioMax" class="form-label fw-semibold text-secondary small">
          <i class="bi bi-cash-stack text-primary"></i> Presupuesto M&aacute;x.
        </label>
        <input type="number" class="form-control" id="precioMax" name="precioMax" 
               placeholder="Ej: 500000000" value="<%= filtroPrecioMax > 0 ? (long)filtroPrecioMax : "" %>">
      </div>

      <div class="col-md-2 d-grid">
        <button type="submit" class="btn btn-primary py-2 fw-semibold">
          <i class="bi bi-funnel-fill me-1"></i> Filtrar
        </button>
      </div>

    </form>
  </div>
</div>

<!-- CATÁLOGO DE PROPIEDADES DESTACADAS -->
<section id="catalogo" class="container my-5 pt-3">
  <div class="d-flex flex-wrap justify-content-between align-items-center mb-4 pb-2 border-bottom">
    <div>
      <h2 class="fw-bold text-navy mb-1">
        <i class="bi bi-stars text-warning me-2"></i> Inmuebles Destacados y Disponibles
      </h2>
      <p class="text-muted mb-0">Selecci&oacute;n de propiedades verificadas con disponibilidad inmediata</p>
    </div>
    <% if (filtroCiudad > 0 || filtroTipo > 0 || (filtroNegocio != null && !"TODOS".equalsIgnoreCase(filtroNegocio)) || filtroPrecioMax > 0) { %>
      <a href="<%= ctx %>/landing.jsp#catalogo" class="btn btn-outline-secondary btn-sm">
        <i class="bi bi-arrow-counterclockwise"></i> Limpiar Filtros
      </a>
    <% } %>
  </div>

  <div class="row g-4">
    <% 
        boolean hayResultados = false;
        while (rsProps.next()) { 
            hayResultados = true;
            int propId = rsProps.getInt("id_propiedad");
            String propCodigo = rsProps.getString("codigo");
            String propTitulo = rsProps.getString("titulo");
            String propDesc = rsProps.getString("descripcion");
            double propPrecio = rsProps.getDouble("precio");
            String propNegocio = rsProps.getString("tipo_negocio");
            String propDireccion = rsProps.getString("direccion");
            double propArea = rsProps.getDouble("area_m2");
            int propHab = rsProps.getInt("habitaciones");
            int propBanos = rsProps.getInt("banos");
            int propPq = rsProps.getInt("parqueaderos");
            boolean propDestacada = rsProps.getBoolean("destacada");
            String propCiudad = rsProps.getString("ciudad");
            String propTipo = rsProps.getString("tipo");
            String propImg = rsProps.getString("imagen");
            if (propImg == null || propImg.isEmpty()) {
                propImg = "https://images.unsplash.com/photo-1560518883-ce09059eeffa?w=800";
            }
    %>
      <div class="col-lg-4 col-md-6">
        <div class="card card-propiedad h-100">
          <div class="card-img-wrapper">
            <img src="<%= propImg %>" class="card-img-top" alt="<%= esc(propTitulo) %>">
            <span class="badge badge-negocio <%= "VENTA".equalsIgnoreCase(propNegocio) ? "bg-primary" : "bg-success" %> text-white shadow-sm">
              <%= propNegocio %>
            </span>
            <span class="badge-tipo shadow-sm">
              <i class="bi bi-tag-fill me-1"></i> <%= esc(propTipo) %>
            </span>
            <% if (propDestacada) { %>
              <span class="badge-destacada shadow-sm">
                <i class="bi bi-lightning-fill"></i> Destacada
              </span>
            <% } %>
          </div>

          <div class="card-body d-flex flex-column p-4">
            <div class="text-muted small mb-1">
              <i class="bi bi-geo-alt-fill text-danger me-1"></i> <%= esc(propCiudad) %> &middot; <%= esc(propDireccion) %>
            </div>
            <h5 class="card-title fw-bold text-navy mb-2">
              <%= esc(propTitulo) %>
            </h5>
            <p class="card-text text-muted small flex-grow-1">
              <%= esc(propDesc.length() > 95 ? propDesc.substring(0, 95) + "..." : propDesc) %>
            </p>

            <div class="specs-inmueble mb-3">
              <div class="specs-item" title="&Aacute;rea construida">
                <i class="bi bi-aspect-ratio text-primary"></i>
                <span><%= (int)propArea %> m&sup2;</span>
              </div>
              <div class="specs-item" title="Habitaciones">
                <i class="bi bi-door-closed text-primary"></i>
                <span><%= propHab %> Hab</span>
              </div>
              <div class="specs-item" title="Ba&ntilde;os">
                <i class="bi bi-droplet text-primary"></i>
                <span><%= propBanos %> Ba&ntilde;os</span>
              </div>
              <div class="specs-item" title="Parqueaderos">
                <i class="bi bi-p-circle text-primary"></i>
                <span><%= propPq %> Pq</span>
              </div>
            </div>

            <div class="d-flex justify-content-between align-items-center pt-2">
              <div>
                <span class="text-muted small d-block">Valor inversi&oacute;n</span>
                <span class="precio-inmueble"><%= pesos(propPrecio) %></span>
              </div>
              <div>
                <% if (esVisitante) { %>
                  <a href="<%= ctx %>/login.jsp" class="btn btn-outline-primary btn-sm fw-semibold">
                    <i class="bi bi-eye"></i> Ver Detalle
                  </a>
                <% } else { %>
                  <a href="<%= ctx %>/detalle_propiedad.jsp?id=<%= propId %>" class="btn btn-primary btn-sm fw-semibold">
                    <i class="bi bi-eye"></i> Gestionar
                  </a>
                <% } %>
              </div>
            </div>

          </div>
          <div class="card-footer bg-light border-0 px-4 pb-3 pt-0 text-muted small d-flex justify-content-between">
            <span>C&oacute;d: <code><%= esc(propCodigo) %></code></span>
            <span>Matr&iacute;cula: <code><%= esc(rsProps.getString("matricula_inmobiliaria")) %></code></span>
          </div>
        </div>
      </div>
    <% } %>

    <% if (!hayResultados) { %>
      <div class="col-12 py-5 text-center">
        <div class="p-5 bg-white rounded-4 shadow-sm">
          <i class="bi bi-building-slash display-3 text-muted"></i>
          <h4 class="mt-3 fw-bold text-navy">No encontramos inmuebles con los criterios seleccionados</h4>
          <p class="text-muted">Intente cambiar la ciudad, ajustar el presupuesto o remover filtros de b&uacute;squeda.</p>
          <a href="<%= ctx %>/landing.jsp#catalogo" class="btn btn-primary mt-2">
            <i class="bi bi-arrow-repeat"></i> Ver Todo el Cat&aacute;logo
          </a>
        </div>
      </div>
    <% } %>
  </div>
</section>

<!-- SECCIÓN BENEFICIOS / NOSOTROS -->
<section id="nosotros" class="bg-white py-5 border-top border-bottom my-5">
  <div class="container">
    <div class="text-center max-w-700 mx-auto mb-5">
      <span class="badge bg-primary-subtle text-primary fw-bold text-uppercase px-3 py-1">¿Por qué confiar en nosotros?</span>
      <h2 class="fw-bold text-navy mt-2">Respaldamos cada paso de tu transacción inmobiliaria</h2>
      <p class="text-muted">Garantizamos transparencia, agilidad en trámites y asesoría jurídica especializada.</p>
    </div>

    <div class="row g-4">
      <div class="col-md-4">
        <div class="feature-box h-100">
          <div class="feature-icon">
            <i class="bi bi-shield-check"></i>
          </div>
          <h5 class="fw-bold text-navy">Seguridad Jurídica</h5>
          <p class="text-muted small mb-0">Verificamos la tradición, certificados de libertad y gravámenes de cada inmueble antes de su publicación.</p>
        </div>
      </div>

      <div class="col-md-4">
        <div class="feature-box h-100">
          <div class="feature-icon">
            <i class="bi bi-calendar2-check"></i>
          </div>
          <h5 class="fw-bold text-navy">Citas Sin Cruces</h5>
          <p class="text-muted small mb-0">Agende visitas virtuales o presenciales en horarios exactos gracias a nuestro sistema de citas con control de concurrencia.</p>
        </div>
      </div>

      <div class="col-md-4">
        <div class="feature-box h-100">
          <div class="feature-icon">
            <i class="bi bi-file-earmark-lock"></i>
          </div>
          <h5 class="fw-bold text-navy">Radicación Digital</h5>
          <p class="text-muted small mb-0">Radique sus documentos de compra o arriendo 100% en línea y consulte el estado de su estudio en tiempo real.</p>
        </div>
      </div>
    </div>
  </div>
</section>

<!-- SECCIÓN CONTACTO / LLAMADO A LA ACCIÓN -->
<section id="contacto" class="container my-5 py-4">
  <div class="card bg-navy text-white border-0 rounded-4 p-4 p-md-5 shadow-lg">
    <div class="row align-items-center">
      <div class="col-lg-8 mb-4 mb-lg-0">
        <h2 class="fw-bold text-warning mb-2">¿Desea poner en venta o arriendo su propiedad?</h2>
        <p class="text-white-50 lead mb-0">
          Nuestros agentes certificados le asesoran con estudio de mercado, avalúo comercial y promoción en plataformas digitales.
        </p>
      </div>
      <div class="col-lg-4 text-lg-end">
        <a href="<%= ctx %>/registro.jsp" class="btn btn-warning btn-lg fw-bold px-4">
          <i class="bi bi-person-check-fill me-1"></i> Regístrese Ahora
        </a>
      </div>
    </div>
  </div>
</section>

<%@ include file="/WEB-INF/jspf/pie.jspf" %>
<%
    } catch (SQLException ex) {
        out.println("<div class='container my-5'><div class='alert alert-danger'><h4>Error al cargar propiedades</h4><pre>" 
                    + esc(ex.getMessage()) + "</pre></div></div>");
    } finally {
        cerrar(rsProps, psProps, rsTipos, psTipos, rsCiudades, psCiudades, con);
    }
%>
