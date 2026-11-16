-- 1. Sector Domain Metadata
CREATE TABLE IF NOT EXISTS sector_metadata (
    sector_name VARCHAR(64) PRIMARY KEY,
    icon VARCHAR(16) DEFAULT '🏢',
    default_departments TEXT[] DEFAULT ARRAY['Operations', 'Administration']
);

INSERT INTO sector_metadata (sector_name, icon, default_departments)
VALUES 
('Hospital', '🏥', ARRAY['Emergency', 'Nursing', 'Diagnostics', 'Pharmacy']),
('Manufacturing', '🏭', ARRAY['Production', 'Quality', 'Tooling']),
('Construction', '🏗️', ARRAY['Civil', 'Safety', 'Electrical']),
('Corporate', '🏢', ARRAY['Engineering', 'Product', 'Operations'])
ON CONFLICT (sector_name) DO NOTHING;

-- 2. Organizations / Multi-Tenant Entities
CREATE TABLE IF NOT EXISTS organizations (
    org_id VARCHAR(32) PRIMARY KEY,
    sector VARCHAR(64) REFERENCES sector_metadata(sector_name) ON UPDATE CASCADE ON DELETE RESTRICT,
    name VARCHAR(255) NOT NULL,
    address TEXT,
    icon VARCHAR(16) DEFAULT '🏢',
    total_staff INT DEFAULT 0,
    present_count INT DEFAULT 0,
    working_count INT DEFAULT 0,
    late_count INT DEFAULT 0,
    absent_count INT DEFAULT 0
);

INSERT INTO organizations (org_id, sector, name, address, icon, total_staff, present_count, working_count, late_count, absent_count)
VALUES 
('HOSP-001', 'Hospital', 'Apex Healthcare & Research Institute (Main Branch)', 'Cyberabad', '🏥', 248, 221, 187, 16, 27),
('MFG-001', 'Manufacturing', 'Precision Forgings & Industrial Plant', 'Pune', '🏭', 412, 388, 350, 18, 24),
('CON-001', 'Construction', 'Skyline Infra & Metro Construction', 'Bengaluru', '🏗️', 310, 274, 260, 21, 36),
('CORP-001', 'Corporate', 'Aether Technologies Global HQ', 'Hyderabad', '🏢', 195, 182, 174, 7, 13)
ON CONFLICT (org_id) DO NOTHING;

-- 3. Users Table (Superadmin, Admins, Employees)
CREATE TABLE IF NOT EXISTS users (
    id VARCHAR(64) PRIMARY KEY,
    org_id VARCHAR(32) REFERENCES organizations(org_id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255),
    password_hash VARCHAR(255) NOT NULL,
    role VARCHAR(32) NOT NULL, -- 'superadmin', 'admin', 'employee'
    department VARCHAR(128),
    designation VARCHAR(128),
    shift_window VARCHAR(128),
    status VARCHAR(32) DEFAULT 'Present',
    login_time VARCHAR(32) DEFAULT '08:54',
    logout_time VARCHAR(32) DEFAULT '—',
    current_task VARCHAR(255) DEFAULT 'General Duty',
    base_pay NUMERIC(12, 2) DEFAULT 60000,
    ot_pay NUMERIC(12, 2) DEFAULT 0,
    deductions NUMERIC(12, 2) DEFAULT 7200,
    pay_status VARCHAR(32) DEFAULT 'Paid',
    casual_leaves INT DEFAULT 6,
    sick_leaves INT DEFAULT 4,
    privilege_leaves INT DEFAULT 12,
    comp_off INT DEFAULT 0,
    pan_number VARCHAR(16),
    pf_number VARCHAR(64)
);

INSERT INTO users (id, org_id, name, email, password_hash, role, department, designation, shift_window, status, login_time, logout_time, current_task, base_pay, ot_pay, deductions, pay_status, casual_leaves, sick_leaves, privilege_leaves)
VALUES 
('admin', 'HOSP-001', 'Hospital Admin', 'admin@apexhealth.org', 'admin123', 'admin', 'Administration', 'Sector Lead', 'General', 'Present', '08:30', '—', 'Facility Oversight', 120000, 0, 15000, 'Paid', 6, 4, 12),
('E-1024', 'HOSP-001', 'Dr. Ananya Rao', 'a.rao@apexhealth.org', 'password123', 'employee', 'Emergency', 'Chief Trauma Specialist', 'Morning A (08:00 - 16:30)', 'Present', '08:54', '—', 'Trauma Ward Acute Care', 180000, 14500, 22000, 'Paid', 6, 4, 12),
('E-1041', 'HOSP-001', 'Rahul Menon', 'r.menon@apexhealth.org', 'password123', 'employee', 'Nursing', 'Senior Staff Nurse', 'General (09:00 - 17:30)', 'Late', '09:18', '—', 'Ward B Post-Op Monitoring', 65000, 4200, 6800, 'Generated', 5, 3, 10),
('E-1088', 'HOSP-001', 'Priya Shah', 'p.shah@apexhealth.org', 'password123', 'employee', 'Diagnostics', 'Senior Radiologist', 'Morning B (08:30 - 17:00)', 'Present', '08:41', '17:32', 'CT/MRI Diagnostic Queue', 140000, 8000, 16500, 'Paid', 7, 5, 14),
('M-2041', 'MFG-001', 'Ravi Kumar', 'r.kumar@precisionmfg.com', 'password123', 'employee', 'Production', 'CNC Lead Operator', 'Shift 1 (07:00 - 15:30)', 'Present', '07:54', '—', 'Automated Line 02 Milling', 48000, 7600, 5100, 'Paid', 5, 4, 10),
('C-3011', 'CON-001', 'Arjun Reddy', 'a.reddy@skylineinfra.com', 'password123', 'employee', 'Civil', 'Site Resident Engineer', 'Site Day (08:00 - 17:00)', 'Present', '08:06', '—', 'Tower B - Deck 8 Slab Pour', 82000, 9800, 9100, 'Paid', 6, 3, 12),
('P-4012', 'CORP-001', 'Neha Sharma', 'n.sharma@aethertech.io', 'password123', 'employee', 'Engineering', 'Principal Architect', 'Flexible (09:00 - 18:00)', 'Present', '09:02', '—', 'Project Orion Cloud Infrastructure', 210000, 0, 28000, 'Paid', 8, 5, 15)
ON CONFLICT (id) DO NOTHING;

-- 4. Biometric Attendance Punch Logs
CREATE TABLE IF NOT EXISTS attendance_logs (
    id SERIAL PRIMARY KEY,
    org_id VARCHAR(32) REFERENCES organizations(org_id) ON DELETE CASCADE,
    user_id VARCHAR(64) REFERENCES users(id) ON DELETE CASCADE,
    clock_in TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    clock_out TIMESTAMP WITH TIME ZONE,
    location_verified VARCHAR(255) DEFAULT 'Facility Perimeter',
    status VARCHAR(32) DEFAULT 'Present'
);

-- 5. Tasks & Assignments Table
CREATE TABLE IF NOT EXISTS tasks (
    id VARCHAR(32) PRIMARY KEY,
    org_id VARCHAR(32) REFERENCES organizations(org_id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    zone VARCHAR(128),
    assignee_id VARCHAR(64) REFERENCES users(id) ON DELETE SET NULL,
    assignee_name VARCHAR(255),
    priority VARCHAR(32) DEFAULT 'Normal',
    progress INT DEFAULT 0,
    status VARCHAR(32) DEFAULT 'In Progress'
);

INSERT INTO tasks (id, org_id, title, zone, assignee_name, priority, progress, status)
VALUES 
('TSK-H1', 'HOSP-001', 'Emergency Trauma Unit Duty', 'Ward A / Trauma', 'Dr. Ananya Rao', 'High', 85, 'In Progress'),
('TSK-H2', 'HOSP-001', 'Dialysis Calibration & Log Verification', 'Nephrology Wing', 'Rahul Menon', 'Medium', 100, 'Completed')
ON CONFLICT (id) DO NOTHING;

-- 6. Shifts & Schedules Roster
CREATE TABLE IF NOT EXISTS shifts (
    id SERIAL PRIMARY KEY,
    org_id VARCHAR(32) REFERENCES organizations(org_id) ON DELETE CASCADE,
    name VARCHAR(128) NOT NULL,
    hours VARCHAR(64) NOT NULL,
    required INT NOT NULL,
    allocated INT NOT NULL,
    status VARCHAR(32) DEFAULT 'Optimal'
);

INSERT INTO shifts (org_id, name, hours, required, allocated, status)
VALUES 
('HOSP-001', 'Morning Shift (Ward Coverage)', '07:00 - 15:30', 85, 88, 'Optimal'),
('HOSP-001', 'General Administration & OPD', '09:00 - 17:30', 90, 86, 'Adequate')
ON CONFLICT DO NOTHING;

-- 7. Inbound Staff Resignations
CREATE TABLE IF NOT EXISTS resignations (
    id VARCHAR(32) PRIMARY KEY,
    org_id VARCHAR(32) REFERENCES organizations(org_id) ON DELETE CASCADE,
    user_id VARCHAR(64) REFERENCES users(id) ON DELETE CASCADE,
    user_name VARCHAR(255) NOT NULL,
    department VARCHAR(128),
    submitted_date DATE DEFAULT CURRENT_DATE,
    notice_days INT DEFAULT 30,
    proposed_lwd DATE NOT NULL,
    official_lwd DATE,
    reason TEXT NOT NULL,
    letter TEXT NOT NULL,
    status VARCHAR(64) DEFAULT 'Pending Review',
    admin_remarks TEXT
);

INSERT INTO resignations (id, org_id, user_id, user_name, department, submitted_date, notice_days, proposed_lwd, official_lwd, reason, letter, status)
VALUES ('RSG-401', 'HOSP-001', 'E-1041', 'Rahul Menon', 'Nursing', '2026-10-25', 30, '2026-11-24', '2026-11-24', 'Relocation / Family Relocation', 'Dear Management, I am tendering my resignation due to family relocation.', 'Pending Review')
ON CONFLICT (id) DO NOTHING;

-- 8. Deletion & Retention Audits
CREATE TABLE IF NOT EXISTS deletion_audits (
    audit_id VARCHAR(32) PRIMARY KEY,
    org_id VARCHAR(32) REFERENCES organizations(org_id) ON DELETE CASCADE,
    sector VARCHAR(64) NOT NULL,
    emp_snapshot JSONB NOT NULL,
    reason TEXT NOT NULL,
    notes TEXT,
    deleted_by VARCHAR(64),
    timestamp VARCHAR(64),
    super_admin_query_sent BOOLEAN DEFAULT TRUE,
    admin_response VARCHAR(32) DEFAULT 'pending',
    audit_status VARCHAR(32) DEFAULT 'Action Required'
);

INSERT INTO deletion_audits (audit_id, org_id, sector, emp_snapshot, reason, notes, deleted_by, timestamp, audit_status, admin_response, super_admin_query_sent)
VALUES ('DEL-8091', 'HOSP-001', 'Hospital', '{"id":"E-1033","name":"Suresh Pillai","dept":"Administration","role":"Operations Coordinator","basePay":52000}'::jsonb, 'Resignation - Relocated to another city', 'Employee submitted formal notice on 15 Oct.', 'admin', '2026-10-25 11:30 AM', 'Action Required', 'Pending Sector Admin Response', TRUE)
ON CONFLICT (audit_id) DO NOTHING;

-- 9. Direct Messages
CREATE TABLE IF NOT EXISTS chat_messages (
    id SERIAL PRIMARY KEY,
    org_id VARCHAR(32) REFERENCES organizations(org_id) ON DELETE CASCADE,
    emp_id VARCHAR(64) REFERENCES users(id) ON DELETE CASCADE,
    sender VARCHAR(16) NOT NULL,
    message TEXT NOT NULL,
    sent_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO chat_messages (org_id, emp_id, sender, message)
VALUES 
('HOSP-001', 'E-1024', 'emp', 'Good morning Admin! Shift registered on roster.'),
('HOSP-001', 'E-1024', 'admin', 'Verified Dr. Rao. Have a great shift.')
ON CONFLICT DO NOTHING;

-- 10. Support & Escalated Queries (Super Admin Desk)
CREATE TABLE IF NOT EXISTS support_queries (
    id VARCHAR(32) PRIMARY KEY,
    org_id VARCHAR(32) REFERENCES organizations(org_id) ON DELETE CASCADE,
    sector VARCHAR(64) NOT NULL,
    raised_by VARCHAR(255) NOT NULL,
    role VARCHAR(32) NOT NULL,
    target_role VARCHAR(32) DEFAULT 'superadmin',
    subject VARCHAR(255) NOT NULL,
    category VARCHAR(128),
    priority VARCHAR(32) DEFAULT 'Medium',
    message TEXT,
    status VARCHAR(32) DEFAULT 'Open',
    response TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO support_queries (id, org_id, sector, raised_by, role, target_role, subject, category, priority, message, status)
VALUES 
('QRY-1001', 'HOSP-001', 'Hospital', 'Dr. Ananya Rao (Staff E-1024)', 'employee', 'superadmin', 'Biometric terminal sync lag in Trauma Bay 1', 'Hardware / RFID Exception', 'High', 'The biometric fingerprint sensor in Trauma Bay 1 experiences a 9-minute sync delay.', 'In Review'),
('QRY-1002', 'MFG-001', 'Manufacturing', 'Manufacturing Sector Admin', 'admin', 'superadmin', 'Request custom 3rd night-shift rotation rule', 'Policy / Shift Bounds', 'Medium', 'We need an exception rule added to allow 12-hour CNC shifts for automated milling.', 'Open')
ON CONFLICT (id) DO NOTHING;