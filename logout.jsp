<%--
  logout.jsp - Cierra la sesión activa y redirige a la página de aterrizaje
  Proyecto: InmobiliariaWeb
--%>
<%@ page contentType="text/html" pageEncoding="UTF-8" %>
<%
    if (session != null) {
        session.invalidate();
    }
    response.sendRedirect(request.getContextPath() + "/landing.jsp?msg=logout");
%>
