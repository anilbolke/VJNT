<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" isELIgnored="true"%>
<%@ page import="java.util.Calendar" %>
<%
    Calendar _cal   = Calendar.getInstance();
    int _month      = _cal.get(Calendar.MONTH); // 0-indexed: 5 = June
    int _year       = _cal.get(Calendar.YEAR);
    String _ayStart, _ayEnd;
    if (_month >= 5) { // June or later = new year started
        _ayStart = String.valueOf(_year);
        _ayEnd   = String.valueOf(_year + 1).substring(2);
    } else {
        _ayStart = String.valueOf(_year - 1);
        _ayEnd   = String.valueOf(_year).substring(2);
    }
    String currentAcademicYear = _ayStart + "-" + _ayEnd;
%>
<div style="background:linear-gradient(90deg,#667eea,#764ba2);color:#fff;text-align:center;
            padding:6px 16px;font-size:13px;font-weight:600;letter-spacing:0.5px;
            font-family:'Segoe UI',Tahoma,Geneva,Verdana,sans-serif;">
    शैक्षणिक वर्ष / Academic Year : <%= currentAcademicYear %>
</div>
