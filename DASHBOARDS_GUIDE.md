# VJNT Dashboards Guide

## Overview
The VJNT Class Management System now includes three role-based dashboards with comprehensive statistics and data visualization.

## Dashboard Types

### 1. 🎓 Division Dashboard
**Access Level**: Division Administrator
**URL**: `/division-dashboard.jsp`
**Users**: `div_latur_division`, etc.

#### Features:
- **Overview Statistics**
  - Total students across all districts
  - Number of districts
  - Number of schools (UDISE count)
  - Total users in division

- **Gender Distribution**
  - Male/Female student count with progress bars
  - Percentage visualization

- **District-wise Statistics**
  - Student count per district
  - Percentage distribution
  - Visual progress indicators

- **Top 10 Schools**
  - Ranked by student count
  - UDISE number display
  - Status indicators

- **User Management Summary**
  - Count by user type (Division, District Coordinators, School staff)
  - Active status display

**Color Theme**: Purple gradient (667eea to 764ba2)

---

### 2. 🏛️ District Dashboard
**Access Level**: District Coordinator, District 2nd Coordinator
**URL**: `/district-dashboard.jsp`
**Users**: `dist_coord_dharashiv`, `dist_coord2_dharashiv`, etc.

#### Features:
- **Overview Statistics**
  - Total students in district
  - Number of schools (UDISE)
  - Male/Female student counts

- **Breadcrumb Navigation**
  - Division → District hierarchy

- **Class-wise Distribution**
  - Students per class
  - Visual chart display

- **School-wise Statistics**
  - Complete list of schools with UDISE numbers
  - Student count per school
  - Gender breakdown per school
  - Status indicators

- **Recent Student Records**
  - Last 20 students added
  - Student PEN, Name, Class, Section, Gender

**Color Theme**: Blue gradient (4facfe to 00f2fe)

---

### 3. 🏫 School Dashboard
**Access Level**: School Coordinator, Head Master
**URL**: `/school-dashboard.jsp`
**Users**: `school_coord_10001`, `headmaster_10001`, etc.

#### Features:
- **Overview Statistics**
  - Total students in school
  - Number of classes
  - Number of sections
  - Male/Female student counts

- **Breadcrumb Navigation**
  - Division → District → School (UDISE)

- **Class-wise Distribution**
  - Students per class
  - Visual chart display

- **Section-wise Distribution**
  - Students per section (A, B, C, etc.)
  - Visual chart display

- **Performance Levels (स्तर)**
  - मराठी भाषा स्तर (Marathi Level)
  - गणित स्तर (Math Level)
  - इंग्रजी स्तर (English Level)
  - Student count per level

- **Class-Section Matrix**
  - Grid view of all class-section combinations
  - Student count in each cell
  - Row and column totals

- **Complete Student List**
  - All students sorted by Class and Section
  - Student PEN, Name, Class, Section, Gender, Category
  - Searchable and scrollable table

**Color Theme**: Green gradient (43e97b to 38f9d7)

---

## User Login & Access

### Test Credentials

#### Division Level
```
Username: div_latur_division
Password: Pass@123
Access: All districts and schools in Latur Division
```

#### District Level
```
Username: dist_coord_dharashiv
Password: Pass@123
Access: All schools in Dharashiv district

Username: dist_coord2_dharashiv
Password: Pass@123
Access: All schools in Dharashiv district (2nd Coordinator)
```

#### School Level
```
Username: school_coord_10001
Password: Pass@123
Access: Only UDISE 10001 students

Username: headmaster_10001
Password: Pass@123
Access: Only UDISE 10001 students
```

---

## Navigation Flow

### Login Flow
1. User logs in at `/login.jsp`
2. System validates credentials
3. Based on `UserType`, redirects to appropriate dashboard:
   - `DIVISION` → `/division-dashboard.jsp`
   - `DISTRICT_COORDINATOR` / `DISTRICT_2ND_COORDINATOR` → `/district-dashboard.jsp`
   - `SCHOOL_COORDINATOR` / `HEAD_MASTER` → `/school-dashboard.jsp`

### Common Features on All Dashboards
- ✅ Welcome message with user name
- ✅ Role display
- ✅ Change Password button
- ✅ Logout button
- ✅ Hierarchical breadcrumb (where applicable)
- ✅ Responsive design
- ✅ Hover effects on cards
- ✅ Professional color coding

---

## Data Access Control

### Division Administrator
- Can view all students in their division
- Can see all districts under their division
- Can see all schools (UDISE) in their division
- Can view all user accounts created under their division

### District Coordinator
- Can view all students in their district only
- Can see all schools (UDISE) in their district
- Cannot see other districts' data
- Limited to their assigned district

### School Coordinator / Head Master
- Can view only students in their school (UDISE)
- Cannot see other schools' data
- Limited to their assigned UDISE number

---

## Statistics & Metrics

### Calculated Metrics
1. **Student Count**: Total, Male, Female
2. **School Count**: Unique UDISE numbers
3. **District Count**: Unique districts (Division level only)
4. **Class Distribution**: Students per class
5. **Section Distribution**: Students per section
6. **Performance Levels**: Marathi, Math, English proficiency
7. **Gender Ratio**: Male to Female percentage
8. **Class-Section Matrix**: Cross-tabulation view

### Visual Elements
- 📊 Progress bars for percentages
- 📈 Stat cards with icons
- 📋 Sortable data tables
- 🎨 Color-coded badges
- 📊 Chart containers with visual data

---

## Database Queries

### DAO Methods Used
```java
// StudentDAO
- getStudentsByDivision(divisionName)
- getStudentsByDistrict(districtName)
- getStudentsByUdise(udiseNo)

// UserDAO
- getUsersByDivision(divisionName)
- getUsersByDistrict(districtName)
- getUsersByUdise(udiseNo)
```

---

## Customization Guide

### Change Color Theme
Edit the gradient in each dashboard's `<style>` section:

**Division Dashboard**:
```css
background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
```

**District Dashboard**:
```css
background: linear-gradient(135deg, #4facfe 0%, #00f2fe 100%);
```

**School Dashboard**:
```css
background: linear-gradient(135deg, #43e97b 0%, #38f9d7 100%);
```

### Add New Metrics
1. Calculate metric in JSP `<% ... %>` section
2. Add stat card in `dashboard-grid` div
3. Create corresponding section with table/chart

### Modify Table Columns
Edit the `<thead>` and corresponding `<tbody>` sections in each table.

---

## Performance Optimization

### Caching Strategy
- Dashboard data is fetched fresh on each page load
- Consider adding session-based caching for large datasets
- Use pagination for student lists with >100 records

### Future Enhancements
1. **Export to Excel**: Add export buttons for reports
2. **Search & Filter**: Add search boxes for student names
3. **Date Range Filters**: Filter by enrollment date
4. **Charts & Graphs**: Add Chart.js for visual analytics
5. **Print View**: Add print-friendly CSS
6. **Mobile Responsive**: Optimize for tablets/phones

---

## Troubleshooting

### Issue: Dashboard shows no data
**Solution**: 
1. Ensure students are imported via `ExcelStudentLoader`
2. Check user's division/district/UDISE matches student data
3. Verify database connection

### Issue: Access denied
**Solution**:
1. Verify user is logged in
2. Check user's `UserType` matches dashboard requirement
3. Clear browser cache and re-login

### Issue: Incorrect statistics
**Solution**:
1. Re-import student data
2. Check for null values in database
3. Verify gender/class fields are properly populated

---

## Security Notes

- ✅ All dashboards check user session
- ✅ User type validation on each page
- ✅ Redirect to login if not authenticated
- ✅ Data access limited by user's assigned scope
- ✅ SQL injection protected by PreparedStatements

---

## Testing Checklist

### Division Dashboard
- [ ] Login as `div_latur_division`
- [ ] Verify total student count
- [ ] Check district list
- [ ] Verify top schools display
- [ ] Test user management summary

### District Dashboard
- [ ] Login as `dist_coord_dharashiv`
- [ ] Verify breadcrumb shows correct hierarchy
- [ ] Check class-wise distribution
- [ ] Verify school list shows only district schools
- [ ] Test recent students section

### School Dashboard
- [ ] Login as `school_coord_10001`
- [ ] Verify breadcrumb shows Division → District → School
- [ ] Check class-section matrix
- [ ] Verify complete student list
- [ ] Test performance levels (if data available)

---

## System URLs

### Production URLs
- Login: `http://localhost:8080/vjnt-class-management/login.jsp`
- Division: `http://localhost:8080/vjnt-class-management/division-dashboard.jsp`
- District: `http://localhost:8080/vjnt-class-management/district-dashboard.jsp`
- School: `http://localhost:8080/vjnt-class-management/school-dashboard.jsp`

### API Endpoints
- Login: `POST /login`
- Logout: `GET /logout`
- Change Password: `GET /change-password`

---

## File Structure

```
src/main/webapp/
├── division-dashboard.jsp     (Division Administrator view)
├── district-dashboard.jsp     (District Coordinator view)
├── school-dashboard.jsp       (School Coordinator/Head Master view)
├── login.jsp                  (Login page)
└── change-password.jsp        (Password change)

src/main/java/com/vjnt/
├── dao/
│   ├── StudentDAO.java        (Student database operations)
│   └── UserDAO.java           (User database operations)
├── model/
│   ├── Student.java           (Student model)
│   └── User.java              (User model)
└── servlet/
    ├── LoginServlet.java      (Handles login & routing)
    └── LogoutServlet.java     (Handles logout)
```

---

## Success! 🎉

All three dashboards are fully functional with:
- ✅ Role-based access control
- ✅ Comprehensive statistics
- ✅ Visual data representation
- ✅ Hierarchical navigation
- ✅ Responsive design
- ✅ Professional UI/UX
- ✅ Real-time data from database
