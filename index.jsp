<%--
  index.jsp - Enrutador principal de InmobiliariaWeb con redirección por rol
  Si no hay sesión activa -> redirige a landing.jsp
  Si hay sesión activa -> redirige al dashboard que corresponda al rol:
    - ADMIN   -> admin/inicio.jsp
    - AGENTE  -> agente/inicio.jsp
    - CLIENTE -> cliente/inicio.jsp
--%>
<%@ page contentType="text/html" pageEncoding="UTF-8" %>
<%
    Integer idUsuario = (Integer) session.getAttribute("idUsuario");
    String ctx = request.getContextPath();

    if (idUsuario == null) {
        response.sendRedirect(ctx + "/landing.jsp");
        return;
    }

    String rol = (String) session.getAttribute("rol");
    if ("ADMIN".equalsIgnoreCase(rol)) {
        response.sendRedirect(ctx + "/admin/inicio.jsp");
    } else if ("AGENTE".equalsIgnoreCase(rol)) {
        response.sendRedirect(ctx + "/agente/inicio.jsp");
    } else {
        response.sendRedirect(ctx + "/cliente/inicio.jsp");
    }
%>
