"""
Secure Student Records Management System (SRMS) - Enhanced GUI
Fully Interactive Implementation with All Features
"""

import tkinter as tk
from tkinter import ttk, messagebox, scrolledtext
import pyodbc
from datetime import datetime

class DatabaseConnection:
    """Handles all database connections and operations"""
    
    def __init__(self):
        self.connection_string = (
            "Driver={SQL Server};"
            "Server=MOHAMMED_SALAH;"
            "Database=SecureStudentRecords;"
            "Trusted_Connection=yes;"
        )
        self.connection = None
    
    def connect(self):
        try:
            self.connection = pyodbc.connect(self.connection_string)
            return True
        except Exception as e:
            messagebox.showerror("Connection Error", f"Failed to connect:\n{str(e)}")
            return False
    
    def execute_procedure(self, proc_name, params=None):
        try:
            cursor = self.connection.cursor()
            if params:
                placeholders = ', '.join(['?'] * len(params))
                query = f"EXEC {proc_name} {placeholders}"
                cursor.execute(query, params)
            else:
                cursor.execute(f"EXEC {proc_name}")
            
            try:
                results = cursor.fetchall()
                columns = [column[0] for column in cursor.description] if cursor.description else []
                cursor.commit()
                return results, columns
            except:
                cursor.commit()
                return [], []
        except Exception as e:
            return None, str(e)
    
    def close(self):
        if self.connection:
            self.connection.close()


class LoginWindow:
    def __init__(self, root, db, on_login_success):
        self.root = root
        self.db = db
        self.on_login_success = on_login_success
        
        self.root.title("SRMS - Secure Login")
        self.root.geometry("500x450")
        self.root.configure(bg='#2c3e50')
        self.center_window()
        self.create_widgets()
    
    def center_window(self):
        self.root.update_idletasks()
        width = 500
        height = 450
        x = (self.root.winfo_screenwidth() // 2) - (width // 2)
        y = (self.root.winfo_screenheight() // 2) - (height // 2)
        self.root.geometry(f'{width}x{height}+{x}+{y}')
    
    def create_widgets(self):
        # Header
        header_frame = tk.Frame(self.root, bg='#34495e', height=100)
        header_frame.pack(fill='x')
        header_frame.pack_propagate(False)
        
        tk.Label(header_frame, text="🔒 SRMS", font=('Arial', 20, 'bold'),
                bg='#34495e', fg='white').pack(pady=10)
        tk.Label(header_frame, text="Secure Student Records Management System",
                font=('Arial', 11), bg='#34495e', fg='#3498db').pack()
        
        # Form
        form_frame = tk.Frame(self.root, bg='#2c3e50')
        form_frame.pack(expand=True, fill='both', padx=50, pady=20)
        
        tk.Label(form_frame, text="Username:", font=('Arial', 11, 'bold'),
                bg='#2c3e50', fg='white').pack(anchor='w', pady=(0, 5))
        self.username_entry = tk.Entry(form_frame, font=('Arial', 12))
        self.username_entry.pack(fill='x', pady=(0, 15))
        
        tk.Label(form_frame, text="Password:", font=('Arial', 11, 'bold'),
                bg='#2c3e50', fg='white').pack(anchor='w', pady=(0, 5))
        self.password_entry = tk.Entry(form_frame, font=('Arial', 12), show='●')
        self.password_entry.pack(fill='x', pady=(0, 25))
        
        tk.Button(form_frame, text="LOGIN", font=('Arial', 12, 'bold'),
                 bg='#27ae60', fg='white', command=self.login,
                 cursor='hand2', relief='flat', padx=20, pady=12).pack(fill='x')
        
        self.password_entry.bind('<Return>', lambda e: self.login())
        
        self.status_label = tk.Label(form_frame, text="", font=('Arial', 10),
                                     bg='#2c3e50', fg='#e74c3c')
        self.status_label.pack(pady=10)
        
        # Quick login hints
        hints_frame = tk.Frame(self.root, bg='#2c3e50')
        hints_frame.pack(pady=10)
        tk.Label(hints_frame, text="Quick Login: admin1 / Admin@123",
                font=('Arial', 9), bg='#2c3e50', fg='#95a5a6').pack()
    
    def login(self):
        username = self.username_entry.get().strip()
        password = self.password_entry.get()
        
        if not username or not password:
            self.status_label.config(text="Please enter username and password")
            return
        
        results, columns = self.db.execute_procedure('sp_Login', [username, password])
        
        if results and len(results) > 0:
            result_dict = dict(zip(columns, results[0]))
            if result_dict.get('Result') == 'Success':
                user_info = {
                    'UserID': result_dict.get('UserID'),
                    'Username': result_dict.get('Username'),
                    'Role': result_dict.get('Role'),
                    'ClearanceLevel': result_dict.get('ClearanceLevel')
                }
                self.on_login_success(user_info)
            else:
                self.status_label.config(text=result_dict.get('Message', 'Login failed'))
        else:
            self.status_label.config(text="Invalid credentials")


class MainApplication:
    def __init__(self, root, db, user_info):
        self.root = root
        self.db = db
        self.user_info = user_info
        
        self.root.title(f"SRMS - {user_info['Role']} Dashboard")
        self.root.geometry("1400x800")
        self.root.configure(bg='#ecf0f1')
        self.create_widgets()
    
    def create_widgets(self):
        # Header
        header = tk.Frame(self.root, bg='#34495e', height=70)
        header.pack(fill='x')
        header.pack_propagate(False)
        
        tk.Label(header, text=f"👤 {self.user_info['Username']} ({self.user_info['Role']})",
                font=('Arial', 13, 'bold'), bg='#34495e', fg='white').pack(side='left', padx=20, pady=20)
        
        tk.Label(header, text=f"🔒 Clearance: Level {self.user_info['ClearanceLevel']}",
                font=('Arial', 11), bg='#34495e', fg='#3498db').pack(side='left', padx=10)
        
        tk.Button(header, text="Logout", font=('Arial', 10, 'bold'),
                 bg='#e74c3c', fg='white', command=self.logout,
                 cursor='hand2', relief='flat', padx=15, pady=8).pack(side='right', padx=20)
        
        # Content
        content = tk.Frame(self.root, bg='#ecf0f1')
        content.pack(fill='both', expand=True)
        
        # Sidebar
        sidebar = tk.Frame(content, bg='#2c3e50', width=220)
        sidebar.pack(side='left', fill='y')
        sidebar.pack_propagate(False)
        
        self.main_panel = tk.Frame(content, bg='#ecf0f1')
        self.main_panel.pack(side='right', fill='both', expand=True)
        
        self.create_navigation(sidebar)
        self.show_dashboard()
    
    def create_navigation(self, sidebar):
        tk.Label(sidebar, text="📋 MENU", font=('Arial', 12, 'bold'),
                bg='#2c3e50', fg='white').pack(pady=20)
        
        role = self.user_info['Role']
        
        self.nav_btn("📊 Dashboard", self.show_dashboard, sidebar)
        
        if role == 'Admin':
            self.nav_btn("👥 Users", self.show_users, sidebar)
            self.nav_btn("📝 Role Requests", self.show_role_requests, sidebar)
            self.nav_btn("🎓 Students", self.show_students, sidebar)
            self.nav_btn("📚 Courses", self.show_courses, sidebar)
            self.nav_btn("📊 Grades", self.show_grades, sidebar)
            self.nav_btn("📅 Attendance", self.show_attendance, sidebar)
        
        elif role == 'Instructor':
            self.nav_btn("📚 My Courses", self.show_my_courses, sidebar)
            self.nav_btn("✏️ Enter Grades", self.show_enter_grades, sidebar)
            self.nav_btn("📊 View Grades", self.show_grades, sidebar)
            self.nav_btn("📅 Attendance", self.show_attendance, sidebar)
        
        elif role == 'TA':
            self.nav_btn("📚 My Courses", self.show_ta_courses, sidebar)
            self.nav_btn("📅 Attendance", self.show_attendance, sidebar)
            self.nav_btn("🔄 Request Upgrade", self.show_role_request, sidebar)
        
        elif role == 'Student':
            self.nav_btn("📚 My Courses", self.show_student_courses, sidebar)
            self.nav_btn("📊 My Grades", self.show_my_grades, sidebar)
            self.nav_btn("📅 My Attendance", self.show_my_attendance, sidebar)
            self.nav_btn("🔄 Request Upgrade", self.show_role_request, sidebar)
        
        elif role == 'Guest':
            self.nav_btn("📚 View Courses", self.show_public_courses, sidebar)
    
    def nav_btn(self, text, command, parent):
        btn = tk.Button(parent, text=text, font=('Arial', 10), bg='#34495e',
                       fg='white', command=command, cursor='hand2', relief='flat',
                       anchor='w', padx=20, pady=12)
        btn.pack(fill='x', padx=5, pady=2)
        btn.bind('<Enter>', lambda e: btn.config(bg='#3498db'))
        btn.bind('<Leave>', lambda e: btn.config(bg='#34495e'))
    
    def clear_panel(self):
        for widget in self.main_panel.winfo_children():
            widget.destroy()
    
    def show_dashboard(self):
        self.clear_panel()
        
        tk.Label(self.main_panel, text=f"{self.user_info['Role']} Dashboard",
                font=('Arial', 22, 'bold'), bg='#ecf0f1', fg='#2c3e50').pack(pady=30)
        
        cards = tk.Frame(self.main_panel, bg='#ecf0f1')
        cards.pack(pady=20)
        
        self.card(cards, "🔒 Clearance", f"Level {self.user_info['ClearanceLevel']}",
                 self.get_clearance_name(self.user_info['ClearanceLevel']))
        self.card(cards, "👤 Role", self.user_info['Role'], "Active")
        self.card(cards, "✅ Status", "Logged In", datetime.now().strftime("%H:%M"))
    
    def card(self, parent, title, value, subtitle):
        c = tk.Frame(parent, bg='white', relief='raised', bd=2)
        c.pack(side='left', padx=15, ipadx=30, ipady=20)
        tk.Label(c, text=title, font=('Arial', 11), bg='white', fg='#7f8c8d').pack()
        tk.Label(c, text=value, font=('Arial', 16, 'bold'), bg='white', fg='#2c3e50').pack(pady=5)
        tk.Label(c, text=subtitle, font=('Arial', 9), bg='white', fg='#95a5a6').pack()
    
    def get_clearance_name(self, level):
        return {1: "Unclassified", 2: "Confidential", 3: "Secret", 4: "Top Secret"}.get(level, "Unknown")
    
    def show_users(self):
        self.clear_panel()
        tk.Label(self.main_panel, text="User Management", font=('Arial', 18, 'bold'),
                bg='#ecf0f1', fg='#2c3e50').pack(pady=20)
        
        tk.Button(self.main_panel, text="➕ Add User", font=('Arial', 11, 'bold'),
                 bg='#27ae60', fg='white', command=self.add_user_dialog,
                 cursor='hand2', relief='flat', padx=20, pady=10).pack(pady=10)
        
        # Show users table
        results, columns = self.db.execute_procedure(
            "SELECT UserID, Username, Role, ClearanceLevel, IsActive, LastLogin FROM Users")
        
        if results:
            self.create_table(self.main_panel, 
                            ['UserID', 'Username', 'Role', 'Clearance', 'Active', 'Last Login'], 
                            results)
    
    def add_user_dialog(self):
        dialog = tk.Toplevel(self.root)
        dialog.title("Add New User")
        dialog.geometry("450x500")
        dialog.configure(bg='#ecf0f1')
        
        tk.Label(dialog, text="Create New User", font=('Arial', 16, 'bold'),
                bg='#ecf0f1').pack(pady=20)
        
        form = tk.Frame(dialog, bg='white', relief='raised', bd=2)
        form.pack(padx=30, pady=10, fill='both', expand=True)
        
        tk.Label(form, text="Username:", font=('Arial', 10, 'bold'), bg='white').pack(pady=5)
        username_entry = tk.Entry(form, font=('Arial', 11))
        username_entry.pack(pady=5)
        
        tk.Label(form, text="Password:", font=('Arial', 10, 'bold'), bg='white').pack(pady=5)
        password_entry = tk.Entry(form, font=('Arial', 11), show='●')
        password_entry.pack(pady=5)
        
        tk.Label(form, text="Role:", font=('Arial', 10, 'bold'), bg='white').pack(pady=5)
        role_var = tk.StringVar()
        ttk.Combobox(form, textvariable=role_var, 
                    values=['Admin', 'Instructor', 'TA', 'Student', 'Guest'],
                    state='readonly').pack(pady=5)
        
        def save():
            username = username_entry.get()
            password = password_entry.get()
            role = role_var.get()
            
            if not all([username, password, role]):
                messagebox.showerror("Error", "All fields required")
                return
            
            clearance = {'Admin': 4, 'Instructor': 3, 'TA': 2, 'Student': 1, 'Guest': 1}[role]
            results, _ = self.db.execute_procedure('sp_RegisterUser',
                                                   [username, password, role, clearance, self.user_info['UserID']])
            
            if results and dict(zip(['Result'], results[0])).get('Result') == 'Success':
                messagebox.showinfo("Success", "User created!")
                dialog.destroy()
                self.show_users()
            else:
                messagebox.showerror("Error", "Failed to create user")
        
        tk.Button(form, text="Create User", command=save, bg='#27ae60',
                 fg='white', font=('Arial', 11, 'bold'), padx=20, pady=10).pack(pady=20)
    
    def show_role_requests(self):
        self.clear_panel()
        tk.Label(self.main_panel, text="Role Requests", font=('Arial', 18, 'bold'),
                bg='#ecf0f1', fg='#2c3e50').pack(pady=20)
        
        results, columns = self.db.execute_procedure('sp_ViewPendingRoleRequests',
                                                     [self.user_info['UserID']])
        
        if not results:
            tk.Label(self.main_panel, text="No pending requests", font=('Arial', 12),
                    bg='#ecf0f1', fg='#7f8c8d').pack(pady=50)
            return
        
        tree = self.create_table(self.main_panel, columns, results)
        
        btn_frame = tk.Frame(self.main_panel, bg='#ecf0f1')
        btn_frame.pack(pady=15)
        
        def approve():
            sel = tree.selection()
            if not sel:
                messagebox.showwarning("Warning", "Select a request")
                return
            request_id = tree.item(sel[0])['values'][0]
            self.db.execute_procedure('sp_ProcessRoleRequest',
                                     [request_id, self.user_info['UserID'], 'Approve', None])
            messagebox.showinfo("Success", "Request approved")
            self.show_role_requests()
        
        def deny():
            sel = tree.selection()
            if not sel:
                messagebox.showwarning("Warning", "Select a request")
                return
            request_id = tree.item(sel[0])['values'][0]
            self.db.execute_procedure('sp_ProcessRoleRequest',
                                     [request_id, self.user_info['UserID'], 'Deny', None])
            messagebox.showinfo("Success", "Request denied")
            self.show_role_requests()
        
        tk.Button(btn_frame, text="✓ Approve", command=approve, bg='#27ae60',
                 fg='white', font=('Arial', 11, 'bold'), padx=25, pady=10).pack(side='left', padx=10)
        tk.Button(btn_frame, text="✗ Deny", command=deny, bg='#e74c3c',
                 fg='white', font=('Arial', 11, 'bold'), padx=25, pady=10).pack(side='left', padx=10)
    
    def show_role_request(self):
        self.clear_panel()
        tk.Label(self.main_panel, text="Request Role Upgrade", font=('Arial', 18, 'bold'),
                bg='#ecf0f1', fg='#2c3e50').pack(pady=20)
        
        form = tk.Frame(self.main_panel, bg='white', relief='raised', bd=2)
        form.pack(padx=50, pady=20, fill='both', expand=True)
        
        tk.Label(form, text=f"Current Role: {self.user_info['Role']}",
                font=('Arial', 12, 'bold'), bg='white').pack(pady=10)
        
        tk.Label(form, text="Requested Role:", font=('Arial', 11, 'bold'), bg='white').pack(pady=5)
        role_var = tk.StringVar()
        
        roles = {'Student': ['TA', 'Instructor'], 'TA': ['Instructor']}.get(self.user_info['Role'], [])
        ttk.Combobox(form, textvariable=role_var, values=roles, state='readonly').pack(pady=5)
        
        tk.Label(form, text="Reason:", font=('Arial', 11, 'bold'), bg='white').pack(pady=5)
        reason_text = scrolledtext.ScrolledText(form, height=5, width=60)
        reason_text.pack(pady=5)
        
        tk.Label(form, text="Comments:", font=('Arial', 11, 'bold'), bg='white').pack(pady=5)
        comments_text = scrolledtext.ScrolledText(form, height=5, width=60)
        comments_text.pack(pady=5)
        
        def submit():
            role = role_var.get()
            reason = reason_text.get('1.0', 'end-1c')
            comments = comments_text.get('1.0', 'end-1c')
            
            if not role or not reason:
                messagebox.showerror("Error", "Fill required fields")
                return
            
            results, columns = self.db.execute_procedure('sp_SubmitRoleRequest',
                                                         [self.user_info['UserID'], role, reason, comments])
            
            if results:
                result = dict(zip(columns, results[0]))
                if result.get('Result') == 'Success':
                    messagebox.showinfo("Success", result.get('Message'))
                    reason_text.delete('1.0', 'end')
                    comments_text.delete('1.0', 'end')
                else:
                    messagebox.showerror("Error", result.get('ErrorMessage'))
        
        tk.Button(form, text="Submit Request", command=submit, bg='#3498db',
                 fg='white', font=('Arial', 11, 'bold'), padx=20, pady=10).pack(pady=20)
    
    def show_students(self):
        self.clear_panel()
        tk.Label(self.main_panel, text="Student Management", font=('Arial', 18, 'bold'),
                bg='#ecf0f1', fg='#2c3e50').pack(pady=20)
        
        results, _ = self.db.execute_procedure(
            "SELECT StudentID, FullName, Email, Department FROM Student")
        
        if results:
            self.create_table(self.main_panel, 
                            ['ID', 'Name', 'Email', 'Department'], results)
    
    def show_courses(self):
        self.clear_panel()
        tk.Label(self.main_panel, text="Course Management", font=('Arial', 18, 'bold'),
                bg='#ecf0f1', fg='#2c3e50').pack(pady=20)
        
        results, columns = self.db.execute_procedure('sp_ViewCourses',
                                                     [self.user_info['UserID'], self.user_info['Role']])
        
        if results:
            self.create_table(self.main_panel, columns, results)
    
    def show_grades(self):
        self.clear_panel()
        tk.Label(self.main_panel, text="Grades View", font=('Arial', 18, 'bold'),
                bg='#ecf0f1', fg='#2c3e50').pack(pady=20)
        
        results, columns = self.db.execute_procedure('sp_ViewGrades',
                                                     [None, None, self.user_info['UserID'], 
                                                      self.user_info['ClearanceLevel']])
        
        if results:
            self.create_table(self.main_panel, columns, results)
        else:
            tk.Label(self.main_panel, text="No grades available or insufficient clearance",
                    font=('Arial', 12), bg='#ecf0f1', fg='#7f8c8d').pack(pady=50)
    
    def show_enter_grades(self):
        self.clear_panel()
        tk.Label(self.main_panel, text="Enter Grades", font=('Arial', 18, 'bold'),
                bg='#ecf0f1', fg='#2c3e50').pack(pady=20)
        
        form = tk.Frame(self.main_panel, bg='white', relief='raised', bd=2)
        form.pack(padx=50, pady=20, fill='both', expand=True)
        
        tk.Label(form, text="Student ID:", font=('Arial', 11, 'bold'), bg='white').pack(pady=5)
        student_entry = tk.Entry(form, font=('Arial', 11))
        student_entry.pack(pady=5)
        
        tk.Label(form, text="Course ID:", font=('Arial', 11, 'bold'), bg='white').pack(pady=5)
        course_entry = tk.Entry(form, font=('Arial', 11))
        course_entry.pack(pady=5)
        
        tk.Label(form, text="Grade (0-100):", font=('Arial', 11, 'bold'), bg='white').pack(pady=5)
        grade_entry = tk.Entry(form, font=('Arial', 11))
        grade_entry.pack(pady=5)
        
        def submit():
            try:
                student_id = int(student_entry.get())
                course_id = int(course_entry.get())
                grade = float(grade_entry.get())
                
                results, columns = self.db.execute_procedure('sp_EnterGrade',
                                                             [student_id, course_id, grade,
                                                              self.user_info['UserID'],
                                                              self.user_info['ClearanceLevel']])
                
                if results:
                    result = dict(zip(columns, results[0]))
                    if result.get('Result') == 'Success':
                        messagebox.showinfo("Success", "Grade entered successfully")
                        student_entry.delete(0, 'end')
                        course_entry.delete(0, 'end')
                        grade_entry.delete(0, 'end')
                    else:
                        messagebox.showerror("Error", result.get('ErrorMessage'))
            except ValueError:
                messagebox.showerror("Error", "Invalid input")
        
        tk.Button(form, text="Submit Grade", command=submit, bg='#27ae60',
                 fg='white', font=('Arial', 11, 'bold'), padx=20, pady=10).pack(pady=20)
    
    def show_attendance(self):
        self.clear_panel()
        tk.Label(self.main_panel, text="Attendance Management", font=('Arial', 18, 'bold'),
                bg='#ecf0f1', fg='#2c3e50').pack(pady=20)
        
        results, columns = self.db.execute_procedure('sp_ViewAttendance',
                                                     [None, None, self.user_info['UserID'],
                                                      self.user_info['ClearanceLevel']])
        
        if results:
            self.create_table(self.main_panel, columns, results)
        else:
            tk.Label(self.main_panel, text="No attendance records",
                    font=('Arial', 12), bg='#ecf0f1', fg='#7f8c8d').pack(pady=50)
    
    def show_my_grades(self):
        self.clear_panel()
        tk.Label(self.main_panel, text="My Grades", font=('Arial', 18, 'bold'),
                bg='#ecf0f1', fg='#2c3e50').pack(pady=20)
        
        results, columns = self.db.execute_procedure('sp_StudentViewOwnGrades',
                                                     [self.user_info['UserID']])
        
        if results:
            self.create_table(self.main_panel, columns, results)
        else:
            tk.Label(self.main_panel, text="No grades available",
                    font=('Arial', 12), bg='#ecf0f1', fg='#7f8c8d').pack(pady=50)
    
    def show_my_attendance(self):
        self.clear_panel()
        tk.Label(self.main_panel, text="My Attendance", font=('Arial', 18, 'bold'),
                bg='#ecf0f1', fg='#2c3e50').pack(pady=20)
        
        results, columns = self.db.execute_procedure('sp_StudentViewOwnAttendance',
                                                     [self.user_info['UserID'], None])
        
        if results:
            self.create_table(self.main_panel, columns, results)
        else:
            tk.Label(self.main_panel, text="No attendance records",
                    font=('Arial', 12), bg='#ecf0f1', fg='#7f8c8d').pack(pady=50)
    
    def show_my_courses(self):
        self.show_courses()
    
    def show_ta_courses(self):
        self.show_courses()
    
    def show_student_courses(self):
        self.show_courses()
    
    def show_public_courses(self):
        self.clear_panel()
        tk.Label(self.main_panel, text="Available Courses", font=('Arial', 18, 'bold'),
                bg='#ecf0f1', fg='#2c3e50').pack(pady=20)
        
        results, columns = self.db.execute_procedure('sp_ViewCourses',
                                                     [self.user_info['UserID'], 'Guest'])
        
        if results:
            self.create_table(self.main_panel, columns, results)
    
    def create_table(self, parent, columns, data):
        frame = tk.Frame(parent, bg='white')
        frame.pack(padx=20, pady=10, fill='both', expand=True)
        
        tree = ttk.Treeview(frame, columns=columns, show='headings', height=20)
        
        for col in columns:
            tree.heading(col, text=col)
            tree.column(col, width=120)
        
        for row in data:
            tree.insert('', 'end', values=row)
        
        tree.pack(side='left', fill='both', expand=True)
        
        scrollbar = ttk.Scrollbar(frame, orient='vertical', command=tree.yview)
        scrollbar.pack(side='right', fill='y')
        tree.configure(yscrollcommand=scrollbar.set)
        
        return tree
    
    def logout(self):
        if messagebox.askyesno("Logout", "Logout?"):
            self.root.destroy()
            start_application()


def start_application():
    root = tk.Tk()
    db = DatabaseConnection()
    
    if not db.connect():
        root.destroy()
        return
    
    def on_login_success(user_info):
        root.destroy()
        main_root = tk.Tk()
        MainApplication(main_root, db, user_info)
        main_root.mainloop()
    
    LoginWindow(root, db, on_login_success)
    root.mainloop()


if __name__ == "__main__":
    start_application()
