<%--
  detalle_propiedad.jsp - Ficha técnica y comercial completa del inmueble
  Proyecto: InmobiliariaWeb
  Evidencia las relaciones 1:N (galería de fotos) y N:M (características con iconos),
  datos de contacto del agente responsable y botón de agendamiento de visitas.
--%>
<%@ page contentType="text/html" pageEncoding="UTF-8" %>
<%@ page import="java.util.List, java.util.ArrayList" %>
<%@ include file="/WEB-INF/jspf/conexion.jspf" %>
<%@ include file="/WEB-INF/jspf/utilidades.jspf" %>
<%
    request.setCharacterEncoding("UTF-8");
    int idPropiedad = aEntero(request.getParameter("id"), 0);

    if (idPropiedad <= 0) {
        response.sendRedirect(request.getContextPath() + "/landing.jsp#catalogo");
        return;
    }

    Connection con = null;
    PreparedStatement psProp = null;
    ResultSet rsProp = null;
    PreparedStatement psImgs = null;
    ResultSet rsImgs = null;
    PreparedStatement psCaracts = null;
    ResultSet rsCaracts = null;

    // Variables de la propiedad
    String codigo = "", matricula = "", titulo = "", descripcion = "", negocio = "", direccion = "";
    String ciudad = "", depto = "", tipo = "", estado = "";
    double precio = 0, area = 0;
    int habitaciones = 0, banos = 0, parqueaderos = 0, estrato = 0;
    boolean destacada = false;
    String fechaPub = "";

    // Variables del agente
    int idAgente = 0;
    String agenteCorreo = "", agenteNombre = "", agenteTelefono = "", agenteFoto = "";

    // Listas para relaciones 1:N y N:M
    List<String> listaImagenes = new ArrayList<>();
    List<String> titulosImagenes = new ArrayList<>();

    class CaracteristicaItem {
        String nombre;
        String icono;
        String valor;
        CaracteristicaItem(String n, String i, String v) {
            this.nombre = n; this.icono = i; this.valor = v;
        }
    }
    List<CaracteristicaItem> listaCaracts = new ArrayList<>();

    try {
        con = abrirConexion();

        // 1) Consulta principal de la propiedad y del agente responsable
        String sqlProp = 
            "SELECT p.id_propiedad, p.codigo, p.matricula_inmobiliaria, p.titulo, p.descripcion, "
          + "       p.precio, p.tipo_negocio, p.direccion, p.area_m2, p.habitaciones, p.banos, "
          + "       p.parqueaderos, p.estrato, p.estado, p.destacada, p.fecha_publicacion, "
          + "       c.nombre AS ciudad, c.departamento, tp.nombre AS tipo, "
          + "       u.id_usuario AS id_agente, u.correo AS agente_correo, "
          + "       perf.nombres AS agente_nombres, perf.apellidos AS agente_apellidos, "
          + "       perf.telefono AS agente_telefono, perf.foto AS agente_foto "
          + "FROM propiedad p "
          + "JOIN ciudad c ON c.id_ciudad = p.id_ciudad "
          + "JOIN tipo_propiedad tp ON tp.id_tipo = p.id_tipo "
          + "JOIN usuario u ON u.id_usuario = p.id_agente "
          + "LEFT JOIN perfil perf ON perf.id_usuario = u.id_usuario "
          + "WHERE p.id_propiedad = ? AND p.activo = 1";

        psProp = con.prepareStatement(sqlProp);
        psProp.setInt(1, idPropiedad);
        rsProp = psProp.executeQuery();

        if (!rsProp.next()) {
            response.sendRedirect(request.getContextPath() + "/landing.jsp#catalogo");
            return;
        }

        codigo = rsProp.getString("codigo");
        matricula = rsProp.getString("matricula_inmobiliaria");
        titulo = rsProp.getString("titulo");
        descripcion = rsProp.getString("descripcion");
        precio = rsProp.getDouble("precio");
        negocio = rsProp.getString("tipo_negocio");
        direccion = rsProp.getString("direccion");
        area = rsProp.getDouble("area_m2");
        habitaciones = rsProp.getInt("habitaciones");
        banos = rsProp.getInt("banos");
        parqueaderos = rsProp.getInt("parqueaderos");
        estrato = rsProp.getInt("estrato");
        estado = rsProp.getString("estado");
        destacada = rsProp.getBoolean("destacada");
        fechaPub = rsProp.getString("fecha_publicacion");
        ciudad = rsProp.getString("ciudad");
        depto = rsProp.getString("departamento");
        tipo = rsProp.getString("tipo");

        idAgente = rsProp.getInt("id_agente");
        agenteCorreo = rsProp.getString("agente_correo");
        String aNom = rsProp.getString("agente_nombres");
        String aApe = rsProp.getString("agente_apellidos");
        agenteNombre = (aNom != null ? aNom : "") + (aApe != null ? " " + aApe : "");
        if (agenteNombre.trim().isEmpty()) agenteNombre = "Asesor Inmobiliario";
        agenteTelefono = rsProp.getString("agente_telefono");
        if (agenteTelefono == null) agenteTelefono = "315-789-0123";
        agenteFoto = rsProp.getString("agente_foto");

        // 2) Galería de imágenes (Relación 1:N)
        psImgs = con.prepareStatement(
            "SELECT url_imagen, titulo FROM imagen_propiedad "
          + "WHERE id_propiedad = ? ORDER BY es_principal DESC, orden ASC"
        );
        psImgs.setInt(1, idPropiedad);
        rsImgs = psImgs.executeQuery();
        while (rsImgs.next()) {
            listaImagenes.add(rsImgs.getString("url_imagen"));
            titulosImagenes.add(rsImgs.getString("titulo"));
        }
        if (listaImagenes.isEmpty()) {
            listaImagenes.add("https://images.unsplash.com/photo-1560518883-ce09059eeffa?w=1200");
            titulosImagenes.add(titulo);
        }

        // 3) Características y amenidades con iconos (Relación N:M)
        psCaracts = con.prepareStatement(
            "SELECT c.nombre, c.icono, pc.valor "
          + "FROM propiedad_caracteristica pc "
          + "JOIN caracteristica c ON c.id_caracteristica = pc.id_caracteristica "
          + "WHERE pc.id_propiedad = ? AND c.activo = 1 "
          + "ORDER BY c.nombre"
        );
        psCaracts.setInt(1, idPropiedad);
        rsCaracts = psCaracts.executeQuery();
        while (rsCaracts.next()) {
            listaCaracts.add(new CaracteristicaItem(
                rsCaracts.getString("nombre"),
                rsCaracts.getString("icono"),
                rsCaracts.getString("valor")
            ));
        }

    } catch (SQLException ex) {
        out.println("<div class='alert alert-danger'>Error de base de datos: " + esc(ex.getMessage()) + "</div>");
    } finally {
        cerrar(rsCaracts, psCaracts, rsImgs, psImgs, rsProp, psProp, con);
    }

    String tituloPagina = titulo + " - " + ciudad;
%>
<%@ include file="/WEB-INF/jspf/cabecera.jspf" %>

<div class="container my-4">

  <!-- Navegación de migas de pan (Breadcrumb) -->
  <nav aria-label="breadcrumb" class="mb-3">
    <ol class="breadcrumb small">
      <li class="breadcrumb-item"><a href="<%= ctx %>/landing.jsp" class="text-decoration-none">Inicio</a></li>
      <li class="breadcrumb-item"><a href="<%= ctx %>/landing.jsp#catalogo" class="text-decoration-none">Catálogo</a></li>
      <li class="breadcrumb-item text-muted"><%= esc(ciudad) %></li>
      <li class="breadcrumb-item active" aria-current="page"><code><%= esc(codigo) %></code></li>
    </ol>
  </nav>

  <!-- Encabezado de la Propiedad -->
  <div class="card border-0 shadow-sm rounded-4 p-4 bg-white mb-4">
    <div class="row align-items-center">
      <div class="col-lg-8">
        <div class="d-flex flex-wrap align-items-center gap-2 mb-2">
          <span class="badge <%= "VENTA".equalsIgnoreCase(negocio) ? "bg-primary" : "bg-success" %> px-3 py-2 text-uppercase fw-bold">
            <%= negocio %>
          </span>
          <span class="badge bg-navy text-white px-3 py-2">
            <i class="bi bi-tag-fill me-1"></i> <%= esc(tipo) %>
          </span>
          <span class="badge bg-<%= colorEstadoPropiedad(estado) %> px-3 py-2">
            <%= estado %>
          </span>
          <% if (destacada) { %>
            <span class="badge bg-warning text-dark px-3 py-2 fw-bold">
              <i class="bi bi-lightning-fill"></i> Inmueble Destacado
            </span>
          <% } %>
        </div>
        <h2 class="fw-bold text-navy mb-1"><%= esc(titulo) %></h2>
        <p class="text-muted mb-0">
          <i class="bi bi-geo-alt-fill text-danger me-1"></i> <%= esc(direccion) %>, <%= esc(ciudad) %> (<%= esc(depto) %>)
        </p>
      </div>

      <div class="col-lg-4 text-lg-end mt-3 mt-lg-0">
        <span class="text-muted small d-block">Precio de <%= negocio %></span>
        <h2 class="fw-bold text-primary mb-1"><%= pesos(precio) %></h2>
        <div class="small text-muted">
          <span>Matr&iacute;cula: <code><%= esc(matricula) %></code></span>
        </div>
      </div>
    </div>
  </div>

  <div class="row g-4">
    
    <!-- Columna Izquierda (8 cols): Galería 1:N, Especificaciones, Descripción y Características N:M -->
    <div class="col-lg-8">
      
      <!-- ================= 1) GALERÍA DE IMÁGENES (Relación 1:N) ================= -->
      <div class="card border-0 shadow-sm rounded-4 overflow-hidden bg-white mb-4">
        <div id="carruselPropiedad" class="carousel slide" data-bs-ride="carousel">
          
          <div class="carousel-indicators">
            <% for (int i = 0; i < listaImagenes.size(); i++) { %>
              <button type="button" data-bs-target="#carruselPropiedad" data-bs-slide-to="<%= i %>" 
                      class="<%= (i == 0 ? "active" : "") %>" aria-label="Foto <%= i + 1 %>"></button>
            <% } %>
          </div>

          <div class="carousel-inner" style="max-height: 480px;">
            <% for (int i = 0; i < listaImagenes.size(); i++) { %>
              <div class="carousel-item <%= (i == 0 ? "active" : "") %>">
                <img src="<%= listaImagenes.get(i) %>" class="d-block w-100 object-fit-cover" 
                     style="height: 480px;" alt="<%= esc(titulosImagenes.get(i)) %>">
                <% if (titulosImagenes.get(i) != null && !titulosImagenes.get(i).isEmpty()) { %>
                  <div class="carousel-caption d-none d-md-block bg-dark bg-opacity-50 rounded px-3 py-1">
                    <p class="mb-0 small"><%= esc(titulosImagenes.get(i)) %></p>
                  </div>
                <% } %>
              </div>
            <% } %>
          </div>

          <% if (listaImagenes.size() > 1) { %>
            <button class="carousel-control-prev" type="button" data-bs-target="#carruselPropiedad" data-bs-slide="prev">
              <span class="carousel-control-prev-icon" aria-hidden="true"></span>
              <span class="visually-hidden">Anterior</span>
            </button>
            <button class="carousel-control-next" type="button" data-bs-target="#carruselPropiedad" data-bs-slide="next">
              <span class="carousel-control-next-icon" aria-hidden="true"></span>
              <span class="visually-hidden">Siguiente</span>
            </button>
          <% } %>

        </div>

        <!-- Miniaturas de la galería -->
        <% if (listaImagenes.size() > 1) { %>
          <div class="p-3 bg-light d-flex gap-2 overflow-auto">
            <% for (int i = 0; i < listaImagenes.size(); i++) { %>
              <img src="<%= listaImagenes.get(i) %>" alt="Miniatura" class="rounded-2 object-fit-cover border" 
                   style="width: 80px; height: 60px; cursor: pointer;" 
                   onclick="var c = new bootstrap.Carousel(document.getElementById('carruselPropiedad')); c.to(<%= i %>);">
            <% } %>
          </div>
        <% } %>
      </div>

      <!-- Especificaciones Principales -->
      <div class="card border-0 shadow-sm rounded-4 p-4 bg-white mb-4">
        <h5 class="fw-bold text-navy mb-3"><i class="bi bi-rulers text-primary me-2"></i> Especificaciones del Inmueble</h5>
        <div class="row g-3 text-center">
          <div class="col-6 col-md-3">
            <div class="p-3 bg-light rounded-3">
              <i class="bi bi-aspect-ratio display-6 text-primary mb-1 d-block"></i>
              <span class="text-muted small d-block">&Aacute;rea Total</span>
              <strong class="text-navy fs-5"><%= (int)area %> m&sup2;</strong>
            </div>
          </div>
          <div class="col-6 col-md-3">
            <div class="p-3 bg-light rounded-3">
              <i class="bi bi-door-closed display-6 text-primary mb-1 d-block"></i>
              <span class="text-muted small d-block">Habitaciones</span>
              <strong class="text-navy fs-5"><%= habitaciones %></strong>
            </div>
          </div>
          <div class="col-6 col-md-3">
            <div class="p-3 bg-light rounded-3">
              <i class="bi bi-droplet display-6 text-primary mb-1 d-block"></i>
              <span class="text-muted small d-block">Ba&ntilde;os</span>
              <strong class="text-navy fs-5"><%= banos %></strong>
            </div>
          </div>
          <div class="col-6 col-md-3">
            <div class="p-3 bg-light rounded-3">
              <i class="bi bi-p-circle display-6 text-primary mb-1 d-block"></i>
              <span class="text-muted small d-block">Parqueaderos</span>
              <strong class="text-navy fs-5"><%= parqueaderos %></strong>
            </div>
          </div>
        </div>
        <div class="row g-2 mt-2 pt-2 border-top small text-muted">
          <div class="col-sm-6">
            <i class="bi bi-layer-forward text-primary me-1"></i> Estrato socioecon&oacute;mico: <strong><%= estrato %></strong>
          </div>
          <div class="col-sm-6 text-sm-end">
            <i class="bi bi-calendar3 text-primary me-1"></i> Publicado: <strong><%= fechaPub.substring(0, 10) %></strong>
          </div>
        </div>
      </div>

      <!-- Descripción Detallada -->
      <div class="card border-0 shadow-sm rounded-4 p-4 bg-white mb-4">
        <h5 class="fw-bold text-navy mb-3"><i class="bi bi-file-text text-primary me-2"></i> Descripci&oacute;n General</h5>
        <p class="text-secondary leading-relaxed mb-0" style="white-space: pre-line;">
          <%= esc(descripcion) %>
        </p>
      </div>

      <!-- ================= 2) CARACTERÍSTICAS Y AMENIDADES CON ICONOS (Relación N:M) ================= -->
      <div class="card border-0 shadow-sm rounded-4 p-4 bg-white mb-4">
        <h5 class="fw-bold text-navy mb-3">
          <i class="bi bi-stars text-warning me-2"></i> Caracter&iacute;sticas y Amenidades de la Propiedad
        </h5>
        
        <% if (!listaCaracts.isEmpty()) { %>
          <div class="row g-3">
            <% for (CaracteristicaItem item : listaCaracts) { %>
              <div class="col-sm-6 col-md-4">
                <div class="p-3 border rounded-3 bg-light d-flex align-items-center gap-3">
                  <div class="fs-3 text-primary">
                    <i class="bi <%= esc(item.icono) %>"></i>
                  </div>
                  <div>
                    <div class="fw-bold text-navy small"><%= esc(item.nombre) %></div>
                    <div class="text-muted small"><%= esc(item.valor) %></div>
                  </div>
                </div>
              </div>
            <% } %>
          </div>
        <% } else { %>
          <p class="text-muted mb-0">No se han registrado características adicionales para este inmueble.</p>
        <% } %>
      </div>

    </div>

    <!-- Columna Derecha (4 cols): Ficha del Agente y Agendamiento de Cita -->
    <div class="col-lg-4">
      
      <!-- ================= 3) DATOS DEL AGENTE RESPONSABLE ================= -->
      <div class="card border-0 shadow-sm rounded-4 p-4 bg-white mb-4">
        <div class="d-flex align-items-center gap-3 mb-3">
          <div class="bg-primary-subtle text-primary rounded-circle d-flex align-items-center justify-content-center" style="width: 60px; height: 60px;">
            <i class="bi bi-person-badge fs-2"></i>
          </div>
          <div>
            <span class="badge bg-primary text-white text-uppercase small">Asesor Exclusivo</span>
            <h5 class="fw-bold text-navy mb-0"><%= esc(agenteNombre) %></h5>
            <small class="text-muted">Inmobiliaria Horizonte S.A.S.</small>
          </div>
        </div>

        <ul class="list-unstyled small text-secondary mb-3">
          <li class="mb-2">
            <i class="bi bi-telephone-fill text-primary me-2"></i> 
            <a href="tel:<%= agenteTelefono %>" class="text-decoration-none text-secondary fw-semibold"><%= esc(agenteTelefono) %></a>
          </li>
          <li class="mb-2">
            <i class="bi bi-envelope-fill text-primary me-2"></i> 
            <a href="mailto:<%= agenteCorreo %>" class="text-decoration-none text-secondary"><%= esc(agenteCorreo) %></a>
          </li>
          <li class="mb-2">
            <i class="bi bi-patch-check-fill text-success me-2"></i> Agente certificado matriculado
          </li>
        </ul>

        <div class="d-grid gap-2">
          <a href="https://wa.me/57<%= agenteTelefono.replaceAll("[^0-9]", "") %>?text=Hola,%20deseo%20informaci%C3%B3n%20del%20inmueble%20<%= esc(codigo) %>" 
             target="_blank" class="btn btn-success fw-semibold">
            <i class="bi bi-whatsapp me-1"></i> Contactar por WhatsApp
          </a>
        </div>
      </div>

      <!-- ================= 4) BOTÓN PARA AGENDAR VISITA ================= -->
      <div class="card border-0 shadow-sm rounded-4 p-4 bg-navy text-white text-center">
        <i class="bi bi-calendar-check display-4 text-warning mb-3"></i>
        <h4 class="fw-bold mb-2">&iquest;Deseas conocer este inmueble?</h4>
        <p class="text-white-50 small mb-4">
          Agenda una visita presencial con nuestro asesor sin cruce de horarios y con confirmaci&oacute;n inmediata.
        </p>

        <% if (esVisitante) { %>
          <div class="alert alert-warning py-2 small text-dark mb-3">
            <i class="bi bi-info-circle me-1"></i> Inicia sesi&oacute;n o crea tu cuenta de cliente para agendar citas.
          </div>
          <a href="<%= ctx %>/login.jsp" class="btn btn-warning fw-bold w-100 py-2 mb-2 text-dark shadow-sm">
            <i class="bi bi-box-arrow-in-right me-1"></i> Iniciar Sesi&oacute;n para Agendar
          </a>
          <a href="<%= ctx %>/registro.jsp" class="btn btn-outline-light btn-sm w-100">
            <i class="bi bi-person-plus me-1"></i> Registrarse como Cliente
          </a>
        <% } else if ("CLIENTE".equalsIgnoreCase(rolCabecera)) { %>
          <button type="button" class="btn btn-warning fw-bold w-100 py-3 text-dark shadow-sm" data-bs-toggle="modal" data-bs-target="#modalAgendarCita">
            <i class="bi bi-calendar-plus-fill me-1"></i> Agendar Visita Ahora
          </button>
        <% } else { %>
          <div class="badge bg-light text-dark py-2 px-3">
            <i class="bi bi-person-gear"></i> Modo Agente / Admin (<%= rolCabecera %>)
          </div>
          <a href="<%= ctx %>/agente/propiedades.jsp" class="btn btn-outline-light btn-sm mt-3 w-100">
            <i class="bi bi-pencil-square me-1"></i> Gestionar en Panel
          </a>
        <% } %>

      </div>

    </div>

  </div>

</div>

<!-- Modal para Agendar Cita (Cliente Autenticado) -->
<% if (!esVisitante && "CLIENTE".equalsIgnoreCase(rolCabecera)) { %>
<div class="modal fade" id="modalAgendarCita" tabindex="-1" aria-labelledby="modalAgendarCitaLabel" aria-hidden="true">
  <div class="modal-dialog modal-dialog-centered">
    <div class="modal-content rounded-4 border-0 shadow">
      <div class="modal-header bg-navy text-white">
        <h5 class="modal-title fw-bold" id="modalAgendarCitaLabel">
          <i class="bi bi-calendar2-week text-warning me-2"></i> Agendar Cita de Visita
        </h5>
        <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal" aria-label="Close"></button>
      </div>
      <form method="post" action="<%= ctx %>/cliente/acciones_cita.jsp">
        <input type="hidden" name="accion" value="agendar">
        <input type="hidden" name="id_propiedad" value="<%= idPropiedad %>">
        <input type="hidden" name="id_agente" value="<%= idAgente %>">
        <div class="modal-body p-4">
          <p class="small text-muted mb-3">
            Inmueble: <strong><%= esc(titulo) %></strong> (<code><%= esc(codigo) %></code>)
          </p>
          <div class="mb-3">
            <label for="fecha_hora" class="form-label small fw-semibold text-secondary">Fecha y Hora de la Visita *</label>
            <input type="datetime-local" class="form-control" id="fecha_hora" name="fecha_hora" required>
            <div class="form-text">Nuestro sistema valida la disponibilidad para evitar cruce de horarios.</div>
          </div>
          <div class="mb-3">
            <label for="mensaje_cita" class="form-label small fw-semibold text-secondary">Mensaje o Inquietudes Adicionales</label>
            <textarea class="form-control" id="mensaje_cita" name="mensaje" rows="3" placeholder="Ej: Me gustaría revisar los parqueaderos y el área de la cocina."></textarea>
          </div>
        </div>
        <div class="modal-footer bg-light">
          <button type="button" class="btn btn-outline-secondary" data-bs-dismiss="modal">Cancelar</button>
          <button type="submit" class="btn btn-warning fw-bold text-dark">
            <i class="bi bi-check-circle-fill me-1"></i> Confirmar Solicitud
          </button>
        </div>
      </form>
    </div>
  </div>
</div>
<% } %>

<%@ include file="/WEB-INF/jspf/pie.jspf" %>
