
<p align="center">
  <img src="https://svg-banners.vercel.app/api?type=origin&text1=DBSecurity&%250Project&width=900&height=150&color=blue" />
</p>

<h1 align="center" style="color:#3498DB;">
  
</h1>
## Secure Student Records Management System (SRMS)

---

## 📌 Project Overview
The **Secure Student Records Management System (SRMS)** is a database security project
designed to apply advanced security concepts in a realistic academic environment.

The system manages **highly sensitive academic data** such as:
- Student profiles
- Grades
- Attendance records
- Staff and instructor information

The project enforces strict security policies to ensure that users can only access
data and operations permitted by their **role and clearance level**.

---

## 🎯 Project Objectives
This project fulfills the following objectives:

1. Design a secure database schema.
2. Enforce **Role-Based Access Control (RBAC)**.
3. Implement **Inference Control** to prevent sensitive data deduction.
4. Apply **Flow Control** to prevent illegal information movement.
5. Implement **Multilevel Security (MLS)** using clearance levels.
6. Secure sensitive data using **Encryption (At Rest)**.
7. Develop a functional **GUI application** connected securely to the database.

---

## 👥 User Roles
The system supports multiple user roles with different access privileges:

- **Admin**
- **Instructor**
- **Teaching Assistant (TA)**
- **Student**
- **Guest**

Each role can only perform operations allowed by its **assigned role and clearance level**.

---

## 🔐 Security Features Implemented

### 🔹 Role-Based Access Control (RBAC)
- Roles are defined at the database level.
- Privileges are granted according to user responsibilities.
- Unauthorized access is strictly restricted.

### 🔹 Inference Control
- Prevents deduction of sensitive information through indirect queries.
- Limits aggregation and inference-based attacks.

### 🔹 Flow Control
- Prevents illegal information flow between different security levels.
- Ensures data does not move from higher clearance to lower clearance improperly.

### 🔹 Multilevel Security (MLS)
- Implements security levels using clearance classification.
- Enforces Bell–LaPadula principles:
  - No Read Up
  - No Write Down

### 🔹 Encryption (At Rest)
- Sensitive data is stored securely using encryption techniques.
- Protects data even in case of unauthorized database access.

---

## 🖥 GUI Application
A GUI application is implemented to interact securely with the database.

- Technology: **Python**
- Purpose:
  - Secure login
  - Role-based interaction
  - Controlled access to database operations

File:
- `SRMS_GUI_Enhanced.py`

---

## 📂 Project Structure

### 🔹 SQL Scripts
| File | Description |
|----|----|
| `01_DatabaseSetup.sql` | Database initialization |
| `02_Tables.sql` | Secure table creation |
| `03_Roles_Permissions.sql` | RBAC implementation |
| `04_Views_MS.sql` | Secure views & MLS |
| `05_StoredProcedures_Part1.sql` | Core logic procedures |
| `06_StoredProcedures_Part2.sql` | Advanced procedures |
| `07_InferenceControl.sql` | Inference control |
| `08_FlowControl.sql` | Flow control rules |
| `09_SampleData.sql` | Sample test data |
| `10_TestingScript.sql` | Security testing |

---

## 🧪 Testing & Verification
The system is tested using structured security testing scripts and verification matrices.

Relevant files:
- `SECURITY_TESTING_GUIDE.md`
- `SECURITY_MATRIX_VERIFICATION.md`
- `TESTING_QUICK_REFERENCE.txt`


---

## 📑 Documentation
- `FINAL_SECURITY_REPORT.md`
- `PROJECT_SUMMARY.md`
- `IMPLEMENTATION_SUMMARY.md`
- `FLOW_CONTROL_SECURITY.md`
- `GUI_REQUIREMENTS_VERIFICATION.md`
- `SECURITY_QUICK_REFERENCE.md`


to demonstrate secure database design and implementation following academic
and real-world security principles.
