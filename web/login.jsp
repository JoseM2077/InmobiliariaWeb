<%--
  login.jsp - Formulario de inicio de sesión
  Proyecto: InmobiliariaWeb
--%>
<%@ page contentType="text/html" pageEncoding="UTF-8" %>
<%@ include file="/WEB-INF/jspf/utilidades.jspf" %>
<%
    String ctx = request.getContextPath();
    String error = request.getParameter("error");
    String msg   = request.getParameter("msg");

    String mensajeError = null;
    if ("clave".equals(error))    mensajeError = "Correo electrónico o contraseña incorrectos.";
    if ("sesion".equals(error))   mensajeError = "Su sesión ha expirado o requiere autenticación para ingresar.";
    if ("vacio".equals(error))    mensajeError = "Por favor ingrese tanto el correo electrónico como la contraseña.";
    if ("inactivo".equals(error)) mensajeError = "Su cuenta de usuario se encuentra temporalmente inactiva.";

    String mensajeExito = null;
    if ("registrado".equals(msg)) mensajeExito = "¡Cuenta creada exitosamente! Ahora puede iniciar sesión con sus credenciales.";
%>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Iniciar Sesión | Inmobiliaria Horizonte</title>
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
<body class="bg-navy d-flex align-items-center justify-content-center" style="min-height: 100vh;">

<div class="container py-4">
  <div class="row justify-content-center">
    <div class="col-12 col-sm-10 col-md-8 col-lg-5 col-xl-4">
      
      <div class="text-center mb-4">
        <a href="<%= ctx %>/landing.jsp" class="text-decoration-none d-inline-flex align-items-center gap-2 text-white">
          <i class="bi bi-buildings-fill text-warning display-5"></i>
          <span class="fs-3 fw-bold">Inmobiliaria <span class="text-warning">Horizonte</span></span>
        </a>
      </div>

      <div class="card auth-card shadow-lg">
        <div class="card-body p-4 p-sm-5">
          <div class="text-center mb-4">
            <h4 class="fw-bold text-navy mb-1">Acceso al Sistema</h4>
            <p class="text-muted small">Ingrese sus credenciales registradas</p>
          </div>

          <% if (mensajeError != null) { %>
            <div class="alert alert-danger alert-dismissible fade show py-2 small" role="alert">
              <i class="bi bi-exclamation-triangle-fill me-1"></i> <%= esc(mensajeError) %>
              <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
            </div>
          <% } %>

          <% if (mensajeExito != null) { %>
            <div class="alert alert-success alert-dismissible fade show py-2 small" role="alert">
              <i class="bi bi-check-circle-fill me-1"></i> <%= esc(mensajeExito) %>
              <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
            </div>
          <% } %>

          <!-- Envío seguro por método POST a acceso.jsp -->
          <form method="post" action="<%= ctx %>/acceso.jsp">
            
            <div class="mb-3">
              <label class="form-label text-secondary small fw-semibold" for="correo">
                Correo Electrónico
              </label>
              <div class="input-group">
                <span class="input-group-text bg-light text-muted"><i class="bi bi-envelope"></i></span>
                <input type="email" class="form-control" id="correo" name="correo" 
                       required autofocus placeholder="ejemplo@horizonte.com">
              </div>
            </div>

            <div class="mb-4">
              <div class="d-flex justify-content-between align-items-center">
                <label class="form-label text-secondary small fw-semibold mb-0" for="clave">
                  Contraseña
                </label>
                <small class="text-muted">Prueba: <code>1234</code></small>
              </div>
              <div class="input-group mt-1">
                <span class="input-group-text bg-light text-muted"><i class="bi bi-shield-lock"></i></span>
                <input type="password" class="form-control" id="clave" name="clave" 
                       required placeholder="••••••••">
              </div>
            </div>

            <button type="submit" class="btn btn-warning w-100 fw-bold py-2 shadow-sm text-dark mb-3">
              <i class="bi bi-box-arrow-in-right me-1"></i> Ingresar al Portal
            </button>

          </form>

          <div class="border-top pt-3 text-center">
            <p class="text-muted small mb-2">¿Aún no tienes una cuenta de cliente?</p>
            <a href="<%= ctx %>/registro.jsp" class="btn btn-outline-primary btn-sm w-100 fw-semibold">
              <i class="bi bi-person-plus"></i> Crear Cuenta de Cliente
            </a>
          </div>

          <div class="mt-3 text-center">
            <a href="<%= ctx %>/landing.jsp" class="text-decoration-none text-muted small">
              <i class="bi bi-arrow-left"></i> Volver a la página de inicio
            </a>
          </div>

        </div>
      </div>

      <div class="text-center text-white-50 small mt-4">
        Inmobiliaria Horizonte &middot; Java Web EE UTS &middot; 2026
      </div>

    </div>
  </div>
</div>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>
