<%--
  agente/propiedades.jsp - Gestión integral de inmuebles para el rol AGENTE
  Proyecto: InmobiliariaWeb
  Incluye listado con estado, precio, baja lógica y formulario de alta con selección de características N:M.
--%>
<%@ page contentType="text/html" pageEncoding="UTF-8" %>
<%@ page import="java.util.List, java.util.ArrayList" %>
<%@ include file="/WEB-INF/jspf/conexion.jspf" %>
<%@ include file="/WEB-INF/jspf/utilidades.jspf" %>
<%
    String[] rolesPermitidos = {"AGENTE", "ADMIN"};
%>
<%@ include file="/WEB-INF/jspf/seguridad.jspf" %>
<%
    String tituloPagina = "Administración de Inmuebles";
    request.setCharacterEncoding("UTF-8");

    String filtroTexto = request.getParameter("q");
    int filtroCiudad   = aEntero(request.getParameter("ciudad"), 0);
    String filtroEst   = request.getParameter("estado");

    Connection con = null;
    PreparedStatement psProps = null;
    ResultSet rsProps = null;
    PreparedStatement psCiudades = null;
    ResultSet rsCiudades = null;
    PreparedStatement psTipos = null;
    ResultSet rsTipos = null;
    PreparedStatement psCaracts = null;
    ResultSet rsCaracts = null;

    try {
        con = abrirConexion();

        // 1) Carga de catálogos para filtros y formulario
        psCiudades = con.prepareStatement("SELECT id_ciudad, nombre, departamento FROM ciudad WHERE activo = 1 ORDER BY nombre");
        rsCiudades = psCiudades.executeQuery();

        psTipos = con.prepareStatement("SELECT id_tipo, nombre FROM tipo_propiedad WHERE activo = 1 ORDER BY nombre");
        rsTipos = psTipos.executeQuery();

        psCaracts = con.prepareStatement("SELECT id_caracteristica, nombre, icono FROM caracteristica WHERE activo = 1 ORDER BY nombre");
        rsCaracts = psCaracts.executeQuery();

        // 2) Consulta de inmuebles del agente (o todos si es ADMIN)
        StringBuilder sql = new StringBuilder();
        sql.append("SELECT p.id_propiedad, p.codigo, p.matricula_inmobiliaria, p.titulo, p.precio, ")
           .append("       p.tipo_negocio, p.direccion, p.area_m2, p.habitaciones, p.banos, p.estado, ")
           .append("       p.activo, p.destacada, c.nombre AS ciudad, tp.nombre AS tipo, ")
           .append("       (SELECT ip.url_imagen FROM imagen_propiedad ip WHERE ip.id_propiedad = p.id_propiedad ORDER BY ip.es_principal DESC, ip.orden ASC LIMIT 1) AS imagen ")
           .append("FROM propiedad p ")
           .append("JOIN ciudad c ON c.id_ciudad = p.id_ciudad ")
           .append("JOIN tipo_propiedad tp ON tp.id_tipo = p.id_tipo ")
           .append("WHERE 1=1 ");

        if (!"ADMIN".equalsIgnoreCase(rolSesion)) {
            sql.append(" AND p.id_agente = ? ");
        }
        if (filtroCiudad > 0) {
            sql.append(" AND p.id_ciudad = ? ");
        }
        if (filtroEst != null && !filtroEst.isEmpty() && !"TODOS".equalsIgnoreCase(filtroEst)) {
            sql.append(" AND p.estado = ? ");
        }
        if (filtroTexto != null && !filtroTexto.trim().isEmpty()) {
            sql.append(" AND (p.titulo LIKE ? OR p.codigo LIKE ? OR p.matricula_inmobiliaria LIKE ?) ");
        }

        sql.append(" ORDER BY p.id_propiedad DESC");

        psProps = con.prepareStatement(sql.toString());
        int pIdx = 1;
        if (!"ADMIN".equalsIgnoreCase(rolSesion)) {
            psProps.setInt(pIdx++, idUsuarioSesion);
        }
        if (filtroCiudad > 0) {
            psProps.setInt(pIdx++, filtroCiudad);
        }
        if (filtroEst != null && !filtroEst.isEmpty() && !"TODOS".equalsIgnoreCase(filtroEst)) {
            psProps.setString(pIdx++, filtroEst.trim().toUpperCase());
        }
        if (filtroTexto != null && !filtroTexto.trim().isEmpty()) {
            String patron = "%" + filtroTexto.trim() + "%";
            psProps.setString(pIdx++, patron);
            psProps.setString(pIdx++, patron);
            psProps.setString(pIdx++, patron);
        }

        rsProps = psProps.executeQuery();
%>
<%@ include file="/WEB-INF/jspf/cabecera.jspf" %>

<div class="container my-4">

  <!-- Mensajes de Alerta -->
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

  <!-- Barra de Acciones y Filtros -->
  <div class="card border-0 shadow-sm rounded-4 p-4 bg-white mb-4">
    <div class="d-flex flex-wrap justify-content-between align-items-center gap-3 mb-3">
      <div>
        <h3 class="fw-bold text-navy mb-1">
          <i class="bi bi-buildings-fill text-primary me-2"></i> Gestión de Inmuebles
        </h3>
        <p class="text-muted small mb-0">
          <%= "ADMIN".equalsIgnoreCase(rolSesion) ? "Supervisando catálogo global de propiedades" : "Inventario inmobiliario bajo su asesoría" %>
        </p>
      </div>
      <div>
        <button type="button" class="btn btn-warning fw-bold px-4 shadow-sm text-dark" data-bs-toggle="modal" data-bs-target="#modalNuevaPropiedad">
          <i class="bi bi-plus-circle-fill me-1"></i> Publicar Nuevo Inmueble
        </button>
      </div>
    </div>

    <!-- Filtros de Listado -->
    <form method="get" action="<%= ctx %>/agente/propiedades.jsp" class="row g-2 align-items-end pt-2 border-top">
      <div class="col-md-4">
        <label for="q" class="form-label small text-secondary fw-semibold">Buscar por Título / Código / Matrícula</label>
        <div class="input-group input-group-sm">
          <span class="input-group-text bg-light"><i class="bi bi-search"></i></span>
          <input type="text" class="form-control" id="q" name="q" placeholder="Ej: MAT-300 o Cabecera" value="<%= esc(filtroTexto) %>">
        </div>
      </div>

      <div class="col-md-3">
        <label for="ciudad" class="form-label small text-secondary fw-semibold">Ciudad</label>
        <select class="form-select form-select-sm" id="ciudad" name="ciudad">
          <option value="0">Todas las ciudades</option>
          <% 
            rsCiudades.beforeFirst();
            while (rsCiudades.next()) { 
              int cId = rsCiudades.getInt("id_ciudad");
          %>
            <option value="<%= cId %>" <%= (filtroCiudad == cId ? "selected" : "") %>>
              <%= esc(rsCiudades.getString("nombre")) %>
            </option>
          <% } %>
        </select>
      </div>

      <div class="col-md-3">
        <label for="estado" class="form-label small text-secondary fw-semibold">Estado</label>
        <select class="form-select form-select-sm" id="estado" name="estado">
          <option value="TODOS" <%= ("TODOS".equalsIgnoreCase(filtroEst) ? "selected" : "") %>>Todos los estados</option>
          <option value="DISPONIBLE" <%= ("DISPONIBLE".equalsIgnoreCase(filtroEst) ? "selected" : "") %>>Disponible</option>
          <option value="RESERVADA"  <%= ("RESERVADA".equalsIgnoreCase(filtroEst) ? "selected" : "") %>>Reservada</option>
          <option value="VENDIDA"    <%= ("VENDIDA".equalsIgnoreCase(filtroEst) ? "selected" : "") %>>Vendida</option>
          <option value="ARRENDADA"  <%= ("ARRENDADA".equalsIgnoreCase(filtroEst) ? "selected" : "") %>>Arrendada</option>
          <option value="INACTIVA"   <%= ("INACTIVA".equalsIgnoreCase(filtroEst) ? "selected" : "") %>>Inactiva</option>
        </select>
      </div>

      <div class="col-md-2 d-grid">
        <button type="submit" class="btn btn-outline-primary btn-sm fw-semibold">
          <i class="bi bi-funnel"></i> Filtrar
        </button>
      </div>
    </form>
  </div>

  <!-- Tabla de Inmuebles -->
  <div class="card border-0 shadow-sm rounded-4 bg-white overflow-hidden">
    <div class="table-responsive">
      <table class="table table-hover align-middle mb-0">
        <thead class="table-navy bg-navy text-white">
          <tr>
            <th style="width: 80px;">Foto</th>
            <th>Código / Matrícula</th>
            <th>Título y Ubicación</th>
            <th>Ciudad / Tipo</th>
            <th class="text-end">Precio</th>
            <th class="text-center">Estado</th>
            <th class="text-center">Baja Lógica</th>
            <th class="text-center">Acciones</th>
          </tr>
        </thead>
        <tbody>
          <% 
            boolean hayFilas = false;
            while (rsProps.next()) { 
              hayFilas = true;
              int pId = rsProps.getInt("id_propiedad");
              String pCodigo = rsProps.getString("codigo");
              String pMatricula = rsProps.getString("matricula_inmobiliaria");
              String pTitulo = rsProps.getString("titulo");
              double pPrecio = rsProps.getDouble("precio");
              String pNegocio = rsProps.getString("tipo_negocio");
              String pCiudad = rsProps.getString("ciudad");
              String pTipo = rsProps.getString("tipo");
              String pEstado = rsProps.getString("estado");
              boolean pActivo = rsProps.getBoolean("activo");
              String pImg = rsProps.getString("imagen");
              if (pImg == null || pImg.isEmpty()) pImg = "https://images.unsplash.com/photo-1560518883-ce09059eeffa?w=200";
          %>
            <tr class="<%= !pActivo ? "table-light text-muted opacity-75" : "" %>">
              <td>
                <img src="<%= pImg %>" alt="Foto" class="rounded-3 object-fit-cover shadow-sm" style="width: 70px; height: 55px;">
              </td>
              <td>
                <div class="fw-bold"><code><%= esc(pCodigo) %></code></div>
                <small class="text-muted">Mat: <%= esc(pMatricula) %></small>
              </td>
              <td>
                <div class="fw-semibold text-navy"><%= esc(pTitulo) %></div>
                <small class="text-muted"><%= esc(rsProps.getString("direccion")) %></small>
              </td>
              <td class="small">
                <div><%= esc(pCiudad) %></div>
                <span class="badge bg-light text-dark border"><%= esc(pTipo) %></span>
              </td>
              <td class="text-end">
                <span class="fw-bold text-navy"><%= pesos(pPrecio) %></span>
                <div class="small text-muted"><%= pNegocio %></div>
              </td>
              <td class="text-center">
                <span class="badge bg-<%= colorEstadoPropiedad(pEstado) %>"><%= pEstado %></span>
              </td>
              
              <!-- BAJA LÓGICA / REACTIVACIÓN -->
              <td class="text-center">
                <% if (pActivo) { %>
                  <a href="<%= ctx %>/agente/acciones_propiedad.jsp?accion=baja_logica&id_propiedad=<%= pId %>&activo=0" 
                     class="btn btn-outline-danger btn-sm" 
                     onclick="return confirm('¿Está seguro de dar de baja lógica este inmueble? Pasará a estado INACTIVA y no será visible en el catálogo público.');"
                     title="Dar de baja lógica">
                    <i class="bi bi-trash3 me-1"></i> Desactivar
                  </a>
                <% } else { %>
                  <a href="<%= ctx %>/agente/acciones_propiedad.jsp?accion=baja_logica&id_propiedad=<%= pId %>&activo=1" 
                     class="btn btn-outline-success btn-sm" 
                     onclick="return confirm('¿Desea reactivar este inmueble en el catálogo disponible?');"
                     title="Reactivar inmueble">
                    <i class="bi bi-arrow-repeat me-1"></i> Reactivar
                  </a>
                <% } %>
              </td>

              <td class="text-center">
                <a href="<%= ctx %>/detalle_propiedad.jsp?id=<%= pId %>" class="btn btn-sm btn-outline-primary" title="Ver detalle público">
                  <i class="bi bi-eye"></i>
                </a>
              </td>
            </tr>
          <% } %>

          <% if (!hayFilas) { %>
            <tr>
              <td colspan="8" class="text-center py-5 text-muted">
                <i class="bi bi-houses display-6 d-block mb-2 text-secondary"></i>
                No se encontraron inmuebles registrados con los filtros aplicados.
              </td>
            </tr>
          <% } %>
        </tbody>
      </table>
    </div>
  </div>

</div>

<!-- ================= MODAL: CREAR NUEVA PROPIEDAD ================= -->
<div class="modal fade" id="modalNuevaPropiedad" tabindex="-1" aria-labelledby="modalNuevaPropiedadLabel" aria-hidden="true">
  <div class="modal-dialog modal-xl modal-dialog-centered modal-dialog-scrollable">
    <div class="modal-content rounded-4 border-0 shadow">
      
      <div class="modal-header bg-navy text-white">
        <h5 class="modal-title fw-bold" id="modalNuevaPropiedadLabel">
          <i class="bi bi-house-add-fill text-warning me-2"></i> Publicar Nuevo Inmueble
        </h5>
        <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal" aria-label="Close"></button>
      </div>

      <form method="post" action="<%= ctx %>/agente/acciones_propiedad.jsp">
        <input type="hidden" name="accion" value="crear">
        
        <div class="modal-body p-4">
          <div class="row g-3">
            
            <div class="col-md-3">
              <label for="codigo" class="form-label small fw-semibold text-secondary">Código del Inmueble *</label>
              <input type="text" class="form-control" id="codigo" name="codigo" required placeholder="Ej: INM-011" maxlength="20">
            </div>

            <div class="col-md-3">
              <label for="matricula_inmobiliaria" class="form-label small fw-semibold text-secondary">
                Matrícula Inmobiliaria (Única) *
              </label>
              <input type="text" class="form-control" id="matricula_inmobiliaria" name="matricula_inmobiliaria" 
                     required placeholder="Ej: MAT-300-100211" maxlength="30">
            </div>

            <div class="col-md-6">
              <label for="titulo" class="form-label small fw-semibold text-secondary">Título Publicación *</label>
              <input type="text" class="form-control" id="titulo" name="titulo" required placeholder="Ej: Apartamento con Balcón en Cabecera" maxlength="120">
            </div>

            <div class="col-md-3">
              <label for="precio" class="form-label small fw-semibold text-secondary">Precio (COP) *</label>
              <input type="number" class="form-control" id="precio" name="precio" required min="100000" step="100000" placeholder="Ej: 350000000">
            </div>

            <div class="col-md-3">
              <label for="tipo_negocio" class="form-label small fw-semibold text-secondary">Tipo de Negocio *</label>
              <select class="form-select" id="tipo_negocio" name="tipo_negocio" required>
                <option value="VENTA">Venta</option>
                <option value="ARRIENDO">Arriendo</option>
              </select>
            </div>

            <div class="col-md-3">
              <label for="id_ciudad" class="form-label small fw-semibold text-secondary">Ciudad *</label>
              <select class="form-select" id="id_ciudad" name="id_ciudad" required>
                <option value="">Seleccione Ciudad...</option>
                <% 
                  rsCiudades.beforeFirst();
                  while (rsCiudades.next()) { 
                %>
                  <option value="<%= rsCiudades.getInt("id_ciudad") %>">
                    <%= esc(rsCiudades.getString("nombre")) %> (<%= esc(rsCiudades.getString("departamento")) %>)
                  </option>
                <% } %>
              </select>
            </div>

            <div class="col-md-3">
              <label for="id_tipo" class="form-label small fw-semibold text-secondary">Tipo de Inmueble *</label>
              <select class="form-select" id="id_tipo" name="id_tipo" required>
                <option value="">Seleccione Tipo...</option>
                <% 
                  rsTipos.beforeFirst();
                  while (rsTipos.next()) { 
                %>
                  <option value="<%= rsTipos.getInt("id_tipo") %>">
                    <%= esc(rsTipos.getString("nombre")) %>
                  </option>
                <% } %>
              </select>
            </div>

            <div class="col-md-8">
              <label for="direccion" class="form-label small fw-semibold text-secondary">Dirección Exacta *</label>
              <input type="text" class="form-control" id="direccion" name="direccion" required placeholder="Ej: Calle 48 # 33-80">
            </div>

            <div class="col-md-2">
              <label for="area_m2" class="form-label small fw-semibold text-secondary">Área (m²) *</label>
              <input type="number" class="form-control" id="area_m2" name="area_m2" required min="1" step="0.5" placeholder="85">
            </div>

            <div class="col-md-2">
              <label for="estrato" class="form-label small fw-semibold text-secondary">Estrato *</label>
              <select class="form-select" id="estrato" name="estrato">
                <option value="1">1</option>
                <option value="2">2</option>
                <option value="3">3</option>
                <option value="4" selected>4</option>
                <option value="5">5</option>
                <option value="6">6</option>
              </select>
            </div>

            <div class="col-md-3">
              <label for="habitaciones" class="form-label small fw-semibold text-secondary">Habitaciones</label>
              <input type="number" class="form-control" id="habitaciones" name="habitaciones" min="0" value="3">
            </div>

            <div class="col-md-3">
              <label for="banos" class="form-label small fw-semibold text-secondary">Baños</label>
              <input type="number" class="form-control" id="banos" name="banos" min="0" value="2">
            </div>

            <div class="col-md-3">
              <label for="parqueaderos" class="form-label small fw-semibold text-secondary">Parqueaderos</label>
              <input type="number" class="form-control" id="parqueaderos" name="parqueaderos" min="0" value="1">
            </div>

            <div class="col-md-3 d-flex align-items-center pt-4">
              <div class="form-check">
                <input class="form-check-input" type="checkbox" id="destacada" name="destacada" value="1">
                <label class="form-check-label small fw-semibold text-navy" for="destacada">
                  Inmueble Destacado en Vitrina
                </label>
              </div>
            </div>

            <div class="col-12">
              <label for="url_imagen" class="form-label small fw-semibold text-secondary">URL de Fotografía Principal</label>
              <input type="url" class="form-control" id="url_imagen" name="url_imagen" placeholder="https://images.unsplash.com/photo-...">
              <div class="form-text">Si no ingresa una URL, el sistema asignará una imagen de alta calidad por defecto.</div>
            </div>

            <div class="col-12">
              <label for="descripcion" class="form-label small fw-semibold text-secondary">Descripción Detallada *</label>
              <textarea class="form-control" id="descripcion" name="descripcion" rows="3" required placeholder="Describa distribución, acabados, cercanía a vías principales..."></textarea>
            </div>

            <!-- SELECCIÓN MÚLTIPLE DE CARACTERÍSTICAS (Relación N:M) -->
            <div class="col-12">
              <label class="form-label small fw-bold text-navy mb-2">
                <i class="bi bi-check2-square text-primary me-1"></i> Características y Amenidades (Relación N:M)
              </label>
              <div class="p-3 border rounded-3 bg-light">
                <div class="row g-2">
                  <% 
                    rsCaracts.beforeFirst();
                    while (rsCaracts.next()) { 
                      int carId = rsCaracts.getInt("id_caracteristica");
                      String carNom = rsCaracts.getString("nombre");
                      String carIco = rsCaracts.getString("icono");
                  %>
                    <div class="col-sm-6 col-md-4 col-lg-3">
                      <div class="form-check">
                        <input class="form-check-input" type="checkbox" name="caracteristicas" value="<%= carId %>" id="car_<%= carId %>">
                        <label class="form-check-label small" for="car_<%= carId %>">
                          <i class="bi <%= esc(carIco) %> text-primary me-1"></i> <%= esc(carNom) %>
                        </label>
                      </div>
                    </div>
                  <% } %>
                </div>
              </div>
            </div>

          </div>
        </div>

        <div class="modal-footer bg-light">
          <button type="button" class="btn btn-outline-secondary" data-bs-dismiss="modal">Cancelar</button>
          <button type="submit" class="btn btn-warning fw-bold text-dark px-4 shadow-sm">
            <i class="bi bi-cloud-arrow-up-fill me-1"></i> Guardar y Publicar Inmueble
          </button>
        </div>

      </form>

    </div>
  </div>
</div>

<%@ include file="/WEB-INF/jspf/pie.jspf" %>
<%
    } catch (SQLException ex) {
        out.println("<div class='alert alert-danger'>Error al cargar propiedades: " + esc(ex.getMessage()) + "</div>");
    } finally {
        cerrar(rsCaracts, psCaracts, rsTipos, psTipos, rsCiudades, psCiudades, rsProps, psProps, con);
    }
%>
