<%--
  index.jsp - Entrada general de la aplicación InmobiliariaWeb
  Redirige al inicio si hay sesión activa, o a la landing page pública si es visitante.
--%>
<%@ page contentType="text/html" pageEncoding="UTF-8" %>
<%
    if (session.getAttribute("idUsuario") != null) {
        response.sendRedirect(request.getContextPath() + "/inicio.jsp");
    } else {
        response.sendRedirect(request.getContextPath() + "/landing.jsp");
    }
%>
