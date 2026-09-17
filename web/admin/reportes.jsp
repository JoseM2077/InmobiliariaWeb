<%--
  admin/reportes.jsp - Consola de reportes y consultas consolidadas para el ADMINISTRADOR
  Proyecto: InmobiliariaWeb
  Implementa las 5 consultas SQL obligatorias solicitadas por el docente:
    (1) INNER JOIN entre 4 tablas: Inmuebles con Ciudad, Tipo y Agente Asignado
    (2) INNER JOIN entre 4 tablas: Trazabilidad completa de Citas (Inmueble, Cliente y Asesor)
    (3) Consulta de relación N:M: Características y amenidades agrupadas por propiedad (GROUP_CONCAT)
    (4) LEFT JOIN: Propiedades sin visitas ni citas agendadas
    (5) Agregación con GROUP BY y HAVING: Inventario y valorización potencial agrupado por ciudad
--%>
<%@ page contentType="text/html" pageEncoding="UTF-8" %>
<%@ include file="/WEB-INF/jspf/conexion.jspf" %>
<%@ include file="/WEB-INF/jspf/utilidades.jspf" %>
<%
    String[] rolesPermitidos = {"ADMIN"};
%>
<%@ include file="/WEB-INF/jspf/seguridad.jspf" %>
<%
    String tituloPagina = "Reportes Consolidados";

    Connection con = null;
    Statement st1 = null; ResultSet rs1 = null;
    Statement st2 = null; ResultSet rs2 = null;
    Statement st3 = null; ResultSet rs3 = null;
    Statement st4 = null; ResultSet rs4 = null;
    Statement st5 = null; ResultSet rs5 = null;

    try {
        con = abrirConexion();

        // ---------------------------------------------------------------------
        // 1) CONSULTA 1: INNER JOIN ENTRE CUATRO TABLAS
        // Propiedades con su ciudad, tipo y agente inmobiliario con teléfono y correo
        // ---------------------------------------------------------------------
        String sql1 = 
            "SELECT p.codigo, p.matricula_inmobiliaria, p.titulo, p.precio, p.tipo_negocio, "
          + "       c.nombre AS ciudad, tp.nombre AS tipo, "
          + "       CONCAT(perf.nombres, ' ', perf.apellidos) AS agente, perf.telefono AS agente_tel, u.correo AS agente_correo "
          + "FROM propiedad p "
          + "INNER JOIN ciudad c ON c.id_ciudad = p.id_ciudad "
          + "INNER JOIN tipo_propiedad tp ON tp.id_tipo = p.id_tipo "
          + "INNER JOIN usuario u ON u.id_usuario = p.id_agente "
          + "INNER JOIN perfil perf ON perf.id_usuario = u.id_usuario "
          + "WHERE p.activo = 1 "
          + "ORDER BY p.id_propiedad DESC";
        st1 = con.createStatement();
        rs1 = st1.executeQuery(sql1);

        // ---------------------------------------------------------------------
        // 2) CONSULTA 2: INNER JOIN ENTRE CUATRO TABLAS (TRAZABILIDAD DE CITAS)
        // Citas con cliente interesado, agente responsable e inmueble
        // ---------------------------------------------------------------------
        String sql2 = 
            "SELECT c.id_cita, p.codigo AS cod_inmueble, p.titulo AS propiedad, c.fecha_hora, c.estado, "
          + "       CONCAT(pcli.nombres, ' ', pcli.apellidos) AS cliente, pcli.telefono AS cli_telefono, "
          + "       CONCAT(pag.nombres, ' ', pag.apellidos) AS agente "
          + "FROM cita c "
          + "INNER JOIN propiedad p ON p.id_propiedad = c.id_propiedad "
          + "INNER JOIN perfil pcli ON pcli.id_usuario = c.id_cliente "
          + "INNER JOIN perfil pag ON pag.id_usuario = c.id_agente "
          + "ORDER BY c.fecha_hora DESC";
        st2 = con.createStatement();
        rs2 = st2.executeQuery(sql2);

        // ---------------------------------------------------------------------
        // 3) CONSULTA 3: RESOLUCIÓN DE RELACIÓN MUCHOS A MUCHOS (N:M)
        // Características y amenidades por propiedad con GROUP_CONCAT y conteo
        // ---------------------------------------------------------------------
        String sql3 = 
            "SELECT p.codigo, p.titulo, "
          + "       COUNT(pc.id_caracteristica) AS total_amenidades, "
          + "       GROUP_CONCAT(CONCAT(c.nombre, ' (', pc.valor, ')') ORDER BY c.nombre SEPARATOR ', ') AS amenidades "
          + "FROM propiedad p "
          + "INNER JOIN propiedad_caracteristica pc ON pc.id_propiedad = p.id_propiedad "
          + "INNER JOIN caracteristica c ON c.id_caracteristica = pc.id_caracteristica "
          + "WHERE p.activo = 1 "
          + "GROUP BY p.id_propiedad, p.codigo, p.titulo "
          + "ORDER BY total_amenidades DESC";
        st3 = con.createStatement();
        rs3 = st3.executeQuery(sql3);

        // ---------------------------------------------------------------------
        // 4) CONSULTA 4: LEFT JOIN (INMUEBLES SIN CITAS AGENDADAS)
        // Identifica propiedades que no han tenido solicitudes de visita
        // ---------------------------------------------------------------------
        String sql4 = 
            "SELECT p.id_propiedad, p.codigo, p.matricula_inmobiliaria, p.titulo, p.precio, p.tipo_negocio, "
          + "       c.nombre AS ciudad, tp.nombre AS tipo "
          + "FROM propiedad p "
          + "INNER JOIN ciudad c ON c.id_ciudad = p.id_ciudad "
          + "INNER JOIN tipo_propiedad tp ON tp.id_tipo = p.id_tipo "
          + "LEFT JOIN cita ci ON ci.id_propiedad = p.id_propiedad "
          + "WHERE ci.id_cita IS NULL AND p.activo = 1 "
          + "ORDER BY p.precio DESC";
        st4 = con.createStatement();
        rs4 = st4.executeQuery(sql4);

        // ---------------------------------------------------------------------
        // 5) CONSULTA 5: AGREGACIÓN CON GROUP BY Y HAVING
        // Total de propiedades, inventario total y promedios por ciudad (HAVING > 0)
        // ---------------------------------------------------------------------
        String sql5 = 
            "SELECT c.nombre AS ciudad, c.departamento, "
          + "       COUNT(p.id_propiedad) AS total_propiedades, "
          + "       SUM(p.precio) AS inventario_total, "
          + "       AVG(p.precio) AS precio_promedio, "
          + "       MIN(p.precio) AS precio_minimo, "
          + "       MAX(p.precio) AS precio_maximo "
          + "FROM ciudad c "
          + "INNER JOIN propiedad p ON p.id_ciudad = c.id_ciudad "
          + "WHERE p.activo = 1 "
          + "GROUP BY c.id_ciudad, c.nombre, c.departamento "
          + "HAVING COUNT(p.id_propiedad) > 0 "
          + "ORDER BY inventario_total DESC";
        st5 = con.createStatement();
        rs5 = st5.executeQuery(sql5);
%>
<%@ include file="/WEB-INF/jspf/cabecera.jspf" %>

<div class="container my-4">

  <!-- Encabezado de Reportes -->
  <div class="card border-0 shadow-sm rounded-4 p-4 bg-white mb-4">
    <div class="d-flex flex-wrap justify-content-between align-items-center gap-3">
      <div>
        <span class="badge bg-danger text-white px-3 py-1 mb-2">UTS Programación Java EE</span>
        <h2 class="fw-bold text-navy mb-1">
          <i class="bi bi-file-earmark-bar-graph-fill text-danger me-2"></i> Reportes y Consultas SQL Obligatorias
        </h2>
        <p class="text-muted small mb-0">
          Demostración del dominio del modelo de datos normalizado en 3FN mediante sentencias SQL con INNER JOIN, LEFT JOIN, N:M y agregación con GROUP BY / HAVING.
        </p>
      </div>
      <div>
        <button onclick="window.print();" class="btn btn-outline-secondary fw-semibold shadow-sm">
          <i class="bi bi-printer me-1"></i> Imprimir Reportes
        </button>
      </div>
    </div>
  </div>

  <!-- NAVEGACIÓN POR PESTAÑAS PARA LOS 5 REPORTES -->
  <ul class="nav nav-pills mb-4 nav-fill gap-2 p-1 bg-white rounded-4 shadow-sm" id="reportesTab" role="tablist">
    <li class="nav-item" role="presentation">
      <button class="nav-link active fw-semibold" id="rep1-tab" data-bs-toggle="tab" data-bs-target="#rep1" type="button" role="tab">
        1. Inmuebles (INNER JOIN 4 Tablas)
      </button>
    </li>
    <li class="nav-item" role="presentation">
      <button class="nav-link fw-semibold" id="rep2-tab" data-bs-toggle="tab" data-bs-target="#rep2" type="button" role="tab">
        2. Citas (INNER JOIN M&uacute;ltiple)
      </button>
    </li>
    <li class="nav-item" role="presentation">
      <button class="nav-link fw-semibold" id="rep3-tab" data-bs-toggle="tab" data-bs-target="#rep3" type="button" role="tab">
        3. Amenidades (Relaci&oacute;n N:M)
      </button>
    </li>
    <li class="nav-item" role="presentation">
      <button class="nav-link fw-semibold" id="rep4-tab" data-bs-toggle="tab" data-bs-target="#rep4" type="button" role="tab">
        4. Inmuebles Sin Citas (LEFT JOIN)
      </button>
    </li>
    <li class="nav-item" role="presentation">
      <button class="nav-link fw-semibold" id="rep5-tab" data-bs-toggle="tab" data-bs-target="#rep5" type="button" role="tab">
        5. Inventario Ciudad (GROUP BY / HAVING)
      </button>
    </li>
  </ul>

  <div class="tab-content" id="reportesTabContent">

    <!-- ================= REPORTE 1: INNER JOIN 4 TABLAS ================= -->
    <div class="tab-pane fade show active" id="rep1" role="tabpanel">
      <div class="card border-0 shadow-sm rounded-4 p-4 bg-white">
        <div class="d-flex justify-content-between align-items-center mb-3">
          <h5 class="fw-bold text-navy mb-0">
            <i class="bi bi-link-45deg text-primary me-1"></i> Reporte 1: Propiedades con Ciudad, Tipo y Agente Asignado
          </h5>
          <span class="badge bg-primary">INNER JOIN (4 tablas)</span>
        </div>
        <div class="bg-light p-3 rounded-3 mb-3 small">
          <code><%= esc(sql1) %></code>
        </div>
        <div class="table-responsive">
          <table class="table table-hover align-middle mb-0">
            <thead class="table-navy bg-navy text-white">
              <tr>
                <th>C&oacute;digo / Matr&iacute;cula</th>
                <th>T&iacute;tulo</th>
                <th>Ciudad</th>
                <th>Tipo</th>
                <th class="text-end">Precio</th>
                <th>Asesor Asignado</th>
                <th>Contacto</th>
              </tr>
            </thead>
            <tbody>
              <% while (rs1.next()) { %>
                <tr>
                  <td>
                    <code><%= esc(rs1.getString("codigo")) %></code>
                    <div class="small text-muted"><%= esc(rs1.getString("matricula_inmobiliaria")) %></div>
                  </td>
                  <td class="fw-semibold text-navy"><%= esc(rs1.getString("titulo")) %></td>
                  <td><%= esc(rs1.getString("ciudad")) %></td>
                  <td><span class="badge bg-light text-dark border"><%= esc(rs1.getString("tipo")) %></span></td>
                  <td class="text-end fw-bold text-navy"><%= pesos(rs1.getDouble("precio")) %></td>
                  <td><%= esc(rs1.getString("agente")) %></td>
                  <td class="small text-muted">
                    <div><i class="bi bi-telephone me-1"></i> <%= esc(rs1.getString("agente_tel")) %></div>
                    <div><i class="bi bi-envelope me-1"></i> <%= esc(rs1.getString("agente_correo")) %></div>
                  </td>
                </tr>
              <% } %>
            </tbody>
          </table>
        </div>
      </div>
    </div>

    <!-- ================= REPORTE 2: INNER JOIN MÚLTIPLE DE CITAS ================= -->
    <div class="tab-pane fade" id="rep2" role="tabpanel">
      <div class="card border-0 shadow-sm rounded-4 p-4 bg-white">
        <div class="d-flex justify-content-between align-items-center mb-3">
          <h5 class="fw-bold text-navy mb-0">
            <i class="bi bi-calendar2-range text-primary me-1"></i> Reporte 2: Trazabilidad Completa de Citas Agendadas
          </h5>
          <span class="badge bg-primary">INNER JOIN (Cita, Inmueble, Perfil Cliente, Perfil Agente)</span>
        </div>
        <div class="bg-light p-3 rounded-3 mb-3 small">
          <code><%= esc(sql2) %></code>
        </div>
        <div class="table-responsive">
          <table class="table table-hover align-middle mb-0">
            <thead class="table-navy bg-navy text-white">
              <tr>
                <th># Cita</th>
                <th>Inmueble</th>
                <th>Fecha y Hora</th>
                <th>Cliente Solicitante</th>
                <th>Asesor Responsable</th>
                <th class="text-center">Estado</th>
              </tr>
            </thead>
            <tbody>
              <% while (rs2.next()) { 
                  String est = rs2.getString("estado");
              %>
                <tr>
                  <td><code>#<%= rs2.getInt("id_cita") %></code></td>
                  <td>
                    <div class="fw-semibold text-navy"><%= esc(rs2.getString("propiedad")) %></div>
                    <small class="text-muted">C&oacute;d: <code><%= esc(rs2.getString("cod_inmueble")) %></code></small>
                  </td>
                  <td class="fw-semibold text-secondary"><%= rs2.getString("fecha_hora").substring(0, 16) %></td>
                  <td>
                    <div><%= esc(rs2.getString("cliente")) %></div>
                    <small class="text-muted"><i class="bi bi-telephone"></i> <%= esc(rs2.getString("cli_telefono")) %></small>
                  </td>
                  <td><%= esc(rs2.getString("agente")) %></td>
                  <td class="text-center"><span class="badge bg-<%= colorEstadoCita(est) %>"><%= est %></span></td>
                </tr>
              <% } %>
            </tbody>
          </table>
        </div>
      </div>
    </div>

    <!-- ================= REPORTE 3: RELACIÓN MUCHOS A MUCHOS (N:M) ================= -->
    <div class="tab-pane fade" id="rep3" role="tabpanel">
      <div class="card border-0 shadow-sm rounded-4 p-4 bg-white">
        <div class="d-flex justify-content-between align-items-center mb-3">
          <h5 class="fw-bold text-navy mb-0">
            <i class="bi bi-stars text-warning me-1"></i> Reporte 3: Caracter&iacute;sticas Vinculadas por Inmueble
          </h5>
          <span class="badge bg-warning text-dark">Relaci&oacute;n N:M (propiedad_caracteristica con GROUP_CONCAT)</span>
        </div>
        <div class="bg-light p-3 rounded-3 mb-3 small">
          <code><%= esc(sql3) %></code>
        </div>
        <div class="table-responsive">
          <table class="table table-hover align-middle mb-0">
            <thead class="table-navy bg-navy text-white">
              <tr>
                <th>C&oacute;digo</th>
                <th>T&iacute;tulo del Inmueble</th>
                <th class="text-center">Total Amenidades</th>
                <th>Listado Detallado de Caracter&iacute;sticas (N:M)</th>
              </tr>
            </thead>
            <tbody>
              <% while (rs3.next()) { %>
                <tr>
                  <td><code><%= esc(rs3.getString("codigo")) %></code></td>
                  <td class="fw-semibold text-navy"><%= esc(rs3.getString("titulo")) %></td>
                  <td class="text-center">
                    <span class="badge bg-primary-subtle text-primary fw-bold px-3 py-2">
                      <%= rs3.getInt("total_amenidades") %>
                    </span>
                  </td>
                  <td class="small text-secondary"><%= esc(rs3.getString("amenidades")) %></td>
                </tr>
              <% } %>
            </tbody>
          </table>
        </div>
      </div>
    </div>

    <!-- ================= REPORTE 4: LEFT JOIN ================= -->
    <div class="tab-pane fade" id="rep4" role="tabpanel">
      <div class="card border-0 shadow-sm rounded-4 p-4 bg-white">
        <div class="d-flex justify-content-between align-items-center mb-3">
          <h5 class="fw-bold text-navy mb-0">
            <i class="bi bi-calendar-x text-danger me-1"></i> Reporte 4: Propiedades que A&uacute;n No Tienen Citas Agendadas
          </h5>
          <span class="badge bg-info text-dark">LEFT JOIN (ci.id_cita IS NULL)</span>
        </div>
        <div class="bg-light p-3 rounded-3 mb-3 small">
          <code><%= esc(sql4) %></code>
        </div>
        <div class="table-responsive">
          <table class="table table-hover align-middle mb-0">
            <thead class="table-navy bg-navy text-white">
              <tr>
                <th>C&oacute;digo / Matr&iacute;cula</th>
                <th>Inmueble Disponible</th>
                <th>Ciudad</th>
                <th>Tipo</th>
                <th>Negocio</th>
                <th class="text-end">Precio</th>
              </tr>
            </thead>
            <tbody>
              <% 
                boolean haySinCitas = false;
                while (rs4.next()) { 
                  haySinCitas = true;
              %>
                <tr>
                  <td>
                    <code><%= esc(rs4.getString("codigo")) %></code>
                    <div class="small text-muted"><%= esc(rs4.getString("matricula_inmobiliaria")) %></div>
                  </td>
                  <td class="fw-semibold text-navy"><%= esc(rs4.getString("titulo")) %></td>
                  <td><%= esc(rs4.getString("ciudad")) %></td>
                  <td><span class="badge bg-light text-dark border"><%= esc(rs4.getString("tipo")) %></span></td>
                  <td><span class="badge bg-secondary"><%= esc(rs4.getString("tipo_negocio")) %></span></td>
                  <td class="text-end fw-bold text-navy"><%= pesos(rs4.getDouble("precio")) %></td>
                </tr>
              <% } %>
              <% if (!haySinCitas) { %>
                <tr>
                  <td colspan="6" class="text-center py-4 text-muted">Todos los inmuebles tienen al menos una cita agendada.</td>
                </tr>
              <% } %>
            </tbody>
          </table>
        </div>
      </div>
    </div>

    <!-- ================= REPORTE 5: GROUP BY Y HAVING ================= -->
    <div class="tab-pane fade" id="rep5" role="tabpanel">
      <div class="card border-0 shadow-sm rounded-4 p-4 bg-white">
        <div class="d-flex justify-content-between align-items-center mb-3">
          <h5 class="fw-bold text-navy mb-0">
            <i class="bi bi-bar-chart-line-fill text-success me-1"></i> Reporte 5: Inventario y Valorizaci&oacute;n Agrupado por Ciudad
          </h5>
          <span class="badge bg-success">GROUP BY Ciudad + HAVING COUNT(*) > 0</span>
        </div>
        <div class="bg-light p-3 rounded-3 mb-3 small">
          <code><%= esc(sql5) %></code>
        </div>
        <div class="table-responsive">
          <table class="table table-hover align-middle mb-0">
            <thead class="table-navy bg-navy text-white">
              <tr>
                <th>Ciudad</th>
                <th>Departamento</th>
                <th class="text-center">Total Inmuebles</th>
                <th class="text-end">Valor Total Cartera</th>
                <th class="text-end">Precio Promedio</th>
                <th class="text-end">Precio M&iacute;nimo</th>
                <th class="text-end">Precio M&aacute;ximo</th>
              </tr>
            </thead>
            <tbody>
              <% while (rs5.next()) { %>
                <tr>
                  <td class="fw-bold text-navy"><%= esc(rs5.getString("ciudad")) %></td>
                  <td class="text-secondary"><%= esc(rs5.getString("departamento")) %></td>
                  <td class="text-center">
                    <span class="badge bg-primary px-3 py-2 rounded-pill"><%= rs5.getInt("total_propiedades") %></span>
                  </td>
                  <td class="text-end fw-bold text-success"><%= pesos(rs5.getDouble("inventario_total")) %></td>
                  <td class="text-end"><%= pesos(rs5.getDouble("precio_promedio")) %></td>
                  <td class="text-end small text-muted"><%= pesos(rs5.getDouble("precio_minimo")) %></td>
                  <td class="text-end small text-muted"><%= pesos(rs5.getDouble("precio_maximo")) %></td>
                </tr>
              <% } %>
            </tbody>
          </table>
        </div>
      </div>
    </div>

  </div>

</div>

<%@ include file="/WEB-INF/jspf/pie.jspf" %>
<%
    } catch (SQLException ex) {
        out.println("<div class='alert alert-danger'>Error al ejecutar reportes: " + esc(ex.getMessage()) + "</div>");
    } finally {
        cerrar(rs5, st5, rs4, st4, rs3, st3, rs2, st2, rs1, st1, con);
    }
%>
