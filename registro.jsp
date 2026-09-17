<%--
  registro.jsp - Formulario de registro público para nuevos clientes
  Proyecto: InmobiliariaWeb
  Implementa Modelo 1 procesando el POST y capturando SQLIntegrityConstraintViolationException
--%>
<%@ page contentType="text/html" pageEncoding="UTF-8" %>
<%@ page import="java.sql.SQLIntegrityConstraintViolationException" %>
<%@ include file="/WEB-INF/jspf/conexion.jspf" %>
<%@ include file="/WEB-INF/jspf/utilidades.jspf" %>
<%
    request.setCharacterEncoding("UTF-8");
    String ctx = request.getContextPath();
    String error = null;

    // Variables de formulario para repoblar si ocurre un error
    String nombres   = request.getParameter("nombres");
    String apellidos = request.getParameter("apellidos");
    String documento = request.getParameter("documento");
    String telefono  = request.getParameter("telefono");
    String direccion = request.getParameter("direccion");
    String correo    = request.getParameter("correo");
    String clave     = request.getParameter("clave");
    String clave2    = request.getParameter("clave2");

    if ("POST".equalsIgnoreCase(request.getMethod())) {
        if (nombres == null || nombres.trim().isEmpty()
            || apellidos == null || apellidos.trim().isEmpty()
            || documento == null || documento.trim().isEmpty()
            || telefono == null || telefono.trim().isEmpty()
            || correo == null || correo.trim().isEmpty()
            || clave == null || clave.trim().isEmpty()
            || clave2 == null || clave2.trim().isEmpty()) {
            
            error = "Todos los campos obligatorios deben ser diligenciados.";
        } else if (!clave.equals(clave2)) {
            error = "Las contrase&ntilde;as ingresadas no coinciden. Por favor verif&iacute;quelas.";
        } else if (clave.length() < 4) {
            error = "La contrase&ntilde;a debe tener al menos 4 caracteres.";
        } else {
            // Datos limpios
            nombres   = nombres.trim();
            apellidos = apellidos.trim();
            documento = documento.trim();
            telefono  = telefono.trim();
            direccion = (direccion != null) ? direccion.trim() : "";
            correo    = correo.trim().toLowerCase();

            Connection con = null;
            PreparedStatement psRol = null;
            ResultSet rsRol = null;
            PreparedStatement psUsuario = null;
            ResultSet rsUsuario = null;
            PreparedStatement psUsuarioRol = null;
            PreparedStatement psPerfil = null;

            try {
                con = abrirConexion();
                con.setAutoCommit(false); // Inicio de transacción atómica

                // 1) Obtener id del rol CLIENTE
                int idRolCliente = 3;
                psRol = con.prepareStatement("SELECT id_rol FROM rol WHERE nombre = 'CLIENTE'");
                rsRol = psRol.executeQuery();
                if (rsRol.next()) {
                    idRolCliente = rsRol.getInt("id_rol");
                }

                // 2) Insertar usuario con clave cifrada en SHA-256 y salt 'correo:clave'
                String hash = claveCifrada(correo, clave);
                psUsuario = con.prepareStatement(
                    "INSERT INTO usuario (correo, password_hash, activo, fecha_registro) VALUES (?, ?, 1, NOW())",
                    Statement.RETURN_GENERATED_KEYS
                );
                psUsuario.setString(1, correo);
                psUsuario.setString(2, hash);
                psUsuario.executeUpdate();

                rsUsuario = psUsuario.getGeneratedKeys();
                int idUsuarioCreado = 0;
                if (rsUsuario.next()) {
                    idUsuarioCreado = rsUsuario.getInt(1);
                } else {
                    throw new SQLException("No se pudo obtener el ID del usuario generado.");
                }

                // 3) Asignar rol CLIENTE en usuario_rol (relación N:M)
                psUsuarioRol = con.prepareStatement(
                    "INSERT INTO usuario_rol (id_usuario, id_rol, fecha_asignacion) VALUES (?, ?, NOW())"
                );
                psUsuarioRol.setInt(1, idUsuarioCreado);
                psUsuarioRol.setInt(2, idRolCliente);
                psUsuarioRol.executeUpdate();

                // 4) Insertar datos personales en perfil (relación 1:1 con id_usuario UNIQUE)
                psPerfil = con.prepareStatement(
                    "INSERT INTO perfil (id_usuario, nombres, apellidos, documento, telefono, direccion, foto) "
                  + "VALUES (?, ?, ?, ?, ?, ?, 'default-avatar.png')"
                );
                psPerfil.setInt(1, idUsuarioCreado);
                psPerfil.setString(2, nombres);
                psPerfil.setString(3, apellidos);
                psPerfil.setString(4, documento);
                psPerfil.setString(5, telefono);
                psPerfil.setString(6, direccion);
                psPerfil.executeUpdate();

                // Si todo fue exitoso, consolidamos la transacción
                con.commit();

                // Redirigir a login informando el éxito
                response.sendRedirect(ctx + "/login.jsp?msg=registrado");
                return;

            } catch (SQLIntegrityConstraintViolationException exIntegridad) {
                // Requisito explícito: Captura obligatoria de SQLIntegrityConstraintViolationException
                deshacer(con);
                String msgErr = exIntegridad.getMessage();
                if (msgErr != null && (msgErr.contains("correo") || msgErr.contains("uq_usuario_correo"))) {
                    error = "El correo electr&oacute;nico '" + esc(correo) + "' ya se encuentra registrado en el sistema. Por favor inicie sesi&oacute;n o utilice otra cuenta de correo.";
                } else if (msgErr != null && (msgErr.contains("documento") || msgErr.contains("uq_perfil_documento"))) {
                    error = "El n&uacute;mero de documento '" + esc(documento) + "' ya se encuentra registrado con otro usuario.";
                } else {
                    error = "No fue posible registrar la cuenta debido a una restricci&oacute;n de datos duplicados: " + esc(exIntegridad.getMessage());
                }
            } catch (SQLException exSql) {
                deshacer(con);
                error = "Error al procesar la solicitud en la base de datos: " + esc(exSql.getMessage());
            } finally {
                cerrar(rsUsuario, psUsuario, rsRol, psRol, psUsuarioRol, psPerfil, con);
            }
        }
    }
%>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Registro de Clientes | Inmobiliaria Horizonte</title>
    <!-- Google Fonts -->
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@300;400;500;600;700&display=swap" rel="stylesheet">
    <!-- Bootstrap 5.3 CSS -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <!-- Bootstrap Icons -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.css" rel="stylesheet">
    <link href="<%= ctx %>/css/estilos.css" rel="stylesheet">
</head>
<body class="bg-navy py-5">

<div class="container">
  <div class="row justify-content-center">
    <div class="col-12 col-lg-8 col-xl-7">
      
      <div class="text-center mb-4">
        <a href="<%= ctx %>/landing.jsp" class="text-decoration-none d-inline-flex align-items-center gap-2 text-white">
          <i class="bi bi-buildings-fill text-warning display-6"></i>
          <span class="fs-2 fw-bold">Inmobiliaria <span class="text-warning">Horizonte</span></span>
        </a>
      </div>

      <div class="card auth-card auth-card-wide shadow-lg mx-auto">
        <div class="card-body p-4 p-md-5">
          <div class="text-center mb-4">
            <span class="badge bg-success-subtle text-success px-3 py-1 fw-bold text-uppercase mb-2">Nuevo Cliente</span>
            <h3 class="fw-bold text-navy mb-1">Crea tu Cuenta</h3>
            <p class="text-muted small">Reg&iacute;strate para agendar citas, radicar documentos y guardar tus inmuebles favoritos.</p>
          </div>

          <% if (error != null) { %>
            <div class="alert alert-danger alert-dismissible fade show small" role="alert">
              <i class="bi bi-exclamation-octagon-fill me-2"></i> <%= error %>
              <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
            </div>
          <% } %>

          <form method="post" action="<%= ctx %>/registro.jsp" class="row g-3">
            
            <div class="col-md-6">
              <label for="nombres" class="form-label small fw-semibold text-secondary">Nombres *</label>
              <div class="input-group">
                <span class="input-group-text bg-light"><i class="bi bi-person"></i></span>
                <input type="text" class="form-control" id="nombres" name="nombres" 
                       required placeholder="Ej: Juan José" value="<%= esc(nombres) %>">
              </div>
            </div>

            <div class="col-md-6">
              <label for="apellidos" class="form-label small fw-semibold text-secondary">Apellidos *</label>
              <div class="input-group">
                <span class="input-group-text bg-light"><i class="bi bi-person"></i></span>
                <input type="text" class="form-control" id="apellidos" name="apellidos" 
                       required placeholder="Ej: P&eacute;rez Rueda" value="<%= esc(apellidos) %>">
              </div>
            </div>

            <div class="col-md-6">
              <label for="documento" class="form-label small fw-semibold text-secondary">Documento de Identidad *</label>
              <div class="input-group">
                <span class="input-group-text bg-light"><i class="bi bi-card-text"></i></span>
                <input type="text" class="form-control" id="documento" name="documento" 
                       required placeholder="Ej: 1098123456" value="<%= esc(documento) %>">
              </div>
            </div>

            <div class="col-md-6">
              <label for="telefono" class="form-label small fw-semibold text-secondary">Tel&eacute;fono M&oacute;vil *</label>
              <div class="input-group">
                <span class="input-group-text bg-light"><i class="bi bi-telephone"></i></span>
                <input type="tel" class="form-control" id="telefono" name="telefono" 
                       required placeholder="Ej: 3157890123" value="<%= esc(telefono) %>">
              </div>
            </div>

            <div class="col-12">
              <label for="direccion" class="form-label small fw-semibold text-secondary">Direcci&oacute;n Residencial</label>
              <div class="input-group">
                <span class="input-group-text bg-light"><i class="bi bi-geo-alt"></i></span>
                <input type="text" class="form-control" id="direccion" name="direccion" 
                       placeholder="Ej: Calle 35 # 28-15 Bucaramanga" value="<%= esc(direccion) %>">
              </div>
            </div>

            <div class="col-12">
              <label for="correo" class="form-label small fw-semibold text-secondary">Correo Electr&oacute;nico (Credencial de Ingreso) *</label>
              <div class="input-group">
                <span class="input-group-text bg-light"><i class="bi bi-envelope-at"></i></span>
                <input type="email" class="form-control" id="correo" name="correo" 
                       required placeholder="juan.perez@gmail.com" value="<%= esc(correo) %>">
              </div>
            </div>

            <div class="col-md-6">
              <label for="clave" class="form-label small fw-semibold text-secondary">Contrase&ntilde;a *</label>
              <div class="input-group">
                <span class="input-group-text bg-light"><i class="bi bi-key"></i></span>
                <input type="password" class="form-control" id="clave" name="clave" 
                       required placeholder="M&iacute;nimo 4 caracteres">
              </div>
            </div>

            <div class="col-md-6">
              <label for="clave2" class="form-label small fw-semibold text-secondary">Confirmar Contrase&ntilde;a *</label>
              <div class="input-group">
                <span class="input-group-text bg-light"><i class="bi bi-check-all"></i></span>
                <input type="password" class="form-control" id="clave2" name="clave2" 
                       required placeholder="Repita la contrase&ntilde;a">
              </div>
            </div>

            <div class="col-12 mt-4">
              <button type="submit" class="btn btn-warning w-100 fw-bold py-2 shadow-sm text-dark">
                <i class="bi bi-person-check-fill me-1"></i> Registrar Cuenta de Cliente
              </button>
            </div>

          </form>

          <div class="border-top pt-3 mt-4 text-center">
            <p class="text-muted small mb-2">&iquest;Ya tienes una cuenta registrada?</p>
            <a href="<%= ctx %>/login.jsp" class="btn btn-outline-primary btn-sm px-4 fw-semibold">
              <i class="bi bi-box-arrow-in-right"></i> Iniciar Sesi&oacute;n
            </a>
          </div>

          <div class="mt-3 text-center">
            <a href="<%= ctx %>/landing.jsp" class="text-decoration-none text-muted small">
              <i class="bi bi-arrow-left"></i> Volver a la p&aacute;gina principal
            </a>
          </div>

        </div>
      </div>

    </div>
  </div>
</div>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>
