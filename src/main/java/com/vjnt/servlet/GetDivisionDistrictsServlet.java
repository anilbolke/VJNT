package com.vjnt.servlet;

import com.vjnt.util.DatabaseConnection;
import com.google.gson.Gson;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.sql.*;
import java.util.*;

@WebServlet("/GetDivisionDistrictsServlet")
public class GetDivisionDistrictsServlet extends HttpServlet {
    
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        
        String division = request.getParameter("division");
        List<String> districts = new ArrayList<>();
        
        Connection conn = null;
        PreparedStatement pstmt = null;
        ResultSet rs = null;
        
        try {
            conn = DatabaseConnection.getConnection();
            
            String sql = "SELECT DISTINCT sch.district_name FROM schools sch " +
                        "INNER JOIN students st ON sch.udise_no = st.udise_no " +
                        "WHERE st.division = ? " +
                        "ORDER BY sch.district_name";
            
            pstmt = conn.prepareStatement(sql);
            pstmt.setString(1, division);
            rs = pstmt.executeQuery();
            
            while (rs.next()) {
                districts.add(rs.getString("district_name"));
            }
            
        } catch (Exception e) {
            System.err.println("Error fetching districts: " + e.getMessage());
            e.printStackTrace();
        } finally {
            if (rs != null) try { rs.close(); } catch (SQLException e) { }
            if (pstmt != null) try { pstmt.close(); } catch (SQLException e) { }
            if (conn != null) try { conn.close(); } catch (SQLException e) { }
        }
        
        Gson gson = new Gson();
        response.getWriter().write(gson.toJson(districts));
    }
}
