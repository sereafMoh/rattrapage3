from flask import Flask, request, jsonify
from flask_cors import CORS
import mysql.connector
from werkzeug.security import generate_password_hash, check_password_hash
from datetime import date




app = Flask(__name__)
CORS(app)
def get_patient_name(user_id):
    db = get_db()
    c = db.cursor(dictionary=True)
    c.execute("SELECT name FROM users WHERE id=%s", (user_id,))
    row = c.fetchone()
    c.close()
    db.close()
    return row['name'] if row else "Unknown"
def get_db():
    return mysql.connector.connect(
        host="localhost",
        user="root",      # Change if not root
        password="",      # Change if your MySQL password is not empty
        database="diabetes"  # Change if your DB is named differently
    )

def get_user_by_email(email):
    db = get_db()
    cursor = db.cursor(dictionary=True)
    cursor.execute("SELECT * FROM users WHERE email = %s", (email,))
    user = cursor.fetchone()
    cursor.close()
    db.close()
    return user
# --- NEW: Blood Glucose Categorization Utility ---
def categorize_glucose(glucose, context, diabetes_type):
    glucose = float(glucose)
    # ADA rules
    if diabetes_type == "Type 1" or diabetes_type == "Type 2":
        if context == "Fasting":
            if glucose < 80: return "Hypoglycemia"
            elif 80 <= glucose <= 130: return "Normal"
            else: return "Hyperglycemia"
        else:  # Post-meal or Other
            if glucose < 80: return "Hypoglycemia"
            elif glucose <= 180: return "Normal"
            else: return "Hyperglycemia"
    elif diabetes_type == "Gestational":
        if context == "Fasting":
            if glucose < 70: return "Hypoglycemia"
            elif glucose < 95: return "Normal"
            else: return "Hyperglycemia"
        elif context == "Post-meal":
            if glucose < 70: return "Hypoglycemia"
            elif glucose < 140: return "Normal"
            else: return "Hyperglycemia"
        else:  # "Other" (2h post-meal)
            if glucose < 70: return "Hypoglycemia"
            elif glucose < 120: return "Normal"
            else: return "Hyperglycemia"
    elif diabetes_type == "Prediabetes":
        if context == "Fasting":
            if glucose < 100: return "Hypoglycemia"
            elif glucose <= 125: return "Normal"
            else: return "Hyperglycemia"
        else:  # Post-meal or Other
            if glucose < 100: return "Hypoglycemia"
            elif glucose <= 199: return "Normal"
            else: return "Hyperglycemia"
    else:
        if glucose < 70: return "Hypoglycemia"
        elif glucose <= 140: return "Normal"
        else: return "Hyperglycemia"

# --- Registration ---
@app.route("/register", methods=["POST"])
def register():
    data = request.json
    email = data.get("email")
    password = data.get("password")
    confirm_password = data.get("confirm_password")
    name = data.get("name")
    role = data.get("role")
    if not email or not password or not confirm_password or not name or not role:
        return jsonify({"error": "All fields required"}), 400
    if password != confirm_password:
        return jsonify({"error": "Passwords do not match"}), 400
    if get_user_by_email(email):
        return jsonify({"error": "Email already registered"}), 400
    password_hash = generate_password_hash(password)
    db = get_db()
    cursor = db.cursor()
    try:
        cursor.execute(
            "INSERT INTO users (email, password_hash, name, role) VALUES (%s, %s, %s, %s)",
            (email, password_hash, name, role)
        )
        db.commit()
        user_id = cursor.lastrowid

        if role == "patient":
            cursor.execute(
                "INSERT INTO patients (user_id, phone, dob, gender, city, country, diabetes_type, health_background, emergency_contact_name, emergency_contact_phone) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)",
                (
                    user_id,
                    data.get("phone"),
                    data.get("dob"),
                    data.get("gender"),
                    data.get("city"),
                    data.get("country"),
                    data.get("diabetes_type"),
                    data.get("health_background"),
                    data.get("emergency_contact_name"),
                    data.get("emergency_contact_phone")
                )
            )
        elif role == "doctor":
          if not data.get("specialty_id"):
              return jsonify({"error": "Specialty is required"}), 400
          cursor.execute(
             "INSERT INTO doctors (user_id, phone, specialty_id, clinic, geo_lat, geo_lng, city, country, license_number) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)",
             (
                   user_id,
                   data.get("phone"),
                   data.get("specialty_id"),  # <-- specialty_id must be present
                   data.get("clinic"),
                   data.get("geo_lat"),
                   data.get("geo_lng"),
                   data.get("city"),
                   data.get("country"),
                   data.get("license_number")
                )
            )
        db.commit()
    except Exception as e:
        db.rollback()
        cursor.close()
        db.close()
        return jsonify({"error": str(e)}), 500
    cursor.close()
    db.close()
    return jsonify({"message": "User registered successfully!"})

# --- Login ---
@app.route("/login", methods=["POST"])
def login():
    data = request.json
    email = data.get("email")
    password = data.get("password")
    user = get_user_by_email(email)
    if not user or not check_password_hash(user["password_hash"], password):
        return jsonify({"error": "Invalid credentials"}), 401
    return jsonify({
        "id": user["id"],
        "name": user["name"],
        "role": user["role"],
        "email": user["email"]
    })

# --- Patient Profile ---
@app.route("/patient_profile/<int:user_id>", methods=["GET"])
def get_patient_profile(user_id):
    db = get_db()
    c = db.cursor(dictionary=True)
    c.execute("""
        SELECT u.id, u.name, u.email, p.phone, p.dob, p.gender, p.city, p.country, p.diabetes_type,
               p.health_background, p.emergency_contact_name, p.emergency_contact_phone, p.weight_kg, p.hydration_liters
        FROM users u
        JOIN patients p ON u.id = p.user_id
        WHERE u.id = %s
    """, (user_id,))
    profile = c.fetchone()
    c.close()
    db.close()
    return jsonify(profile or {})

@app.route("/patient_profile/<int:user_id>", methods=["PUT"])
def update_patient_profile(user_id):
    data = request.json
    db = get_db()
    c = db.cursor()
    c.execute("""
        UPDATE patients SET phone=%s, dob=%s, gender=%s, city=%s, country=%s, diabetes_type=%s,
            health_background=%s, emergency_contact_name=%s, emergency_contact_phone=%s, weight_kg=%s, hydration_liters=%s
        WHERE user_id=%s
    """, (
        data.get("phone"), data.get("dob"), data.get("gender"), data.get("city"), data.get("country"),
        data.get("diabetes_type"), data.get("health_background"),
        data.get("emergency_contact_name"), data.get("emergency_contact_phone"),
        data.get("weight_kg"), data.get("hydration_liters"), user_id
    ))
    db.commit()
    c.close()
    db.close()
    return jsonify({"message": "Profile updated"})

# --- Doctor Profile ---
@app.route("/doctor_profile/<int:user_id>", methods=["GET"])
def get_doctor_profile(user_id):
    db = get_db()
    c = db.cursor(dictionary=True)
    c.execute("""
        SELECT u.id, u.name, u.email, d.phone, s.name as specialty, d.clinic, d.geo_lat, d.geo_lng, d.city, d.country, d.license_number, d.specialty_id
        FROM users u
        JOIN doctors d ON u.id = d.user_id
        LEFT JOIN specialties s ON d.specialty_id = s.id
        WHERE u.id = %s
    """, (user_id,))
    profile = c.fetchone()
    c.close()
    db.close()
    return jsonify(profile or {})

@app.route("/doctor_profile/<int:user_id>", methods=["PUT"])
def update_doctor_profile(user_id):
    data = request.json
    db = get_db()
    c = db.cursor()
    c.execute("""
        UPDATE doctors SET phone=%s, specialty_id=%s, clinic=%s, geo_lat=%s, geo_lng=%s, city=%s, country=%s, license_number=%s
        WHERE user_id=%s
    """, (
        data.get("phone"), data.get("specialty_id"), data.get("clinic"),
        data.get("geo_lat"), data.get("geo_lng"), data.get("city"),
        data.get("country"), data.get("license_number"), user_id
    ))
    db.commit()
    c.close()
    db.close()
    return jsonify({"message": "Profile updated"})

# --- Doctors List (for patient assignment) ---
# --- Update the /doctors endpoint to return specialty name and city ---

@app.route("/doctors", methods=["GET"])
def get_doctors():
    db = get_db()
    c = db.cursor(dictionary=True)
    c.execute("""
        SELECT u.id, u.name, u.email, s.name as specialty, d.specialty_id, d.clinic, d.city, d.country
        FROM users u
        JOIN doctors d ON u.id = d.user_id
        LEFT JOIN specialties s ON d.specialty_id = s.id
    """)
    doctors = c.fetchall()
    c.close()
    db.close()
    return jsonify(doctors)

# --- Assign Doctor to Patient ---
@app.route("/assign_doctor", methods=["POST"])
def assign_doctor():
    data = request.json
    doctor_id = data.get("doctor_id")
    patient_id = data.get("patient_id")
    if not doctor_id or not patient_id:
        return jsonify({"error": "doctor_id and patient_id required"}), 400
    db = get_db()
    c = db.cursor()
    # Remove old assignment if exists
    c.execute("DELETE FROM doctor_patient WHERE patient_id=%s", (patient_id,))
    # Assign new doctor
    c.execute("INSERT INTO doctor_patient (doctor_id, patient_id) VALUES (%s, %s)", (doctor_id, patient_id))
    db.commit()
    c.close()
    db.close()
    return jsonify({"message": "Doctor assigned"})

@app.route("/mydoctor/<int:patient_id>", methods=["GET"])
def get_my_doctor(patient_id):
    db = get_db()
    c = db.cursor(dictionary=True)
    c.execute("""
        SELECT u.id, u.name, u.email, s.name as specialty, d.specialty_id, d.clinic, d.city, d.country
        FROM doctor_patient dp
        JOIN users u ON dp.doctor_id = u.id
        JOIN doctors d ON u.id = d.user_id
        LEFT JOIN specialties s ON d.specialty_id = s.id
        WHERE dp.patient_id = %s
    """, (patient_id,))
    doctor = c.fetchone()
    c.close()
    db.close()
    return jsonify(doctor or {})

# --- Patients List for a Doctor ---
@app.route("/patients/<int:doctor_id>", methods=["GET"])
def get_patients(doctor_id):
    db = get_db()
    c = db.cursor(dictionary=True)
    c.execute("""
        SELECT u.id, u.name, u.email, p.city, p.country
        FROM doctor_patient dp
        JOIN users u ON dp.patient_id = u.id
        JOIN patients p ON u.id = p.user_id
        WHERE dp.doctor_id = %s
    """, (doctor_id,))
    patients = c.fetchall()
    c.close()
    db.close()
    return jsonify(patients)
#specialities
@app.route("/specialties", methods=["GET"])
def get_specialties():
    db = get_db()
    c = db.cursor(dictionary=True)
    c.execute("SELECT id, name FROM specialties ORDER BY name")
    specialties = c.fetchall()
    c.close()
    db.close()
    return jsonify(specialties)

# --- Glucose Logs ---
# --- REPLACE THIS WHOLE FUNCTION ---
@app.route("/glucose", methods=["POST"])
def add_glucose():
    data = request.json
    user_id = data.get("user_id")
    glucose_level = data.get("glucose_level")
    context = data.get("context", "Other")
    if not user_id or glucose_level is None:
        return jsonify({"error": "user_id and glucose_level required"}), 400
    db = get_db()

    # Get diabetes_type
    cur = db.cursor(dictionary=True)
    cur.execute("SELECT diabetes_type FROM patients WHERE user_id=%s", (user_id,))
    p = cur.fetchone()
    diabetes_type = p["diabetes_type"] if p else "Type 2"
    category = categorize_glucose(glucose_level, context, diabetes_type)

    # Save glucose log
    cur2 = db.cursor()
    cur2.execute(
        "INSERT INTO glucose_logs (user_id, glucose_level, context, category) VALUES (%s, %s, %s, %s)",
        (user_id, glucose_level, context, category)
    )
    db.commit()

    # Find doctor for this patient
    cur3 = db.cursor(dictionary=True)
    cur3.execute("SELECT doctor_id FROM doctor_patient WHERE patient_id=%s", (user_id,))
    doctor_row = cur3.fetchone()
    doctor_id = doctor_row['doctor_id'] if doctor_row else None

    # Get patient name for notification
    cur3.execute("SELECT name FROM users WHERE id=%s", (user_id,))
    row = cur3.fetchone()
    patient_name = row['name'] if row else "Unknown"

    if doctor_id:
        # Always notify doctor: new glucose entry
        notif_title = f"{patient_name} has logged a new blood glucose value"
        notif_body = f"{patient_name} has logged {glucose_level} mg/dL ({context}) for today, check it out!"
        cur3.execute(
            "INSERT INTO notifications (user_id, type, title, body) VALUES (%s, %s, %s, %s)",
            (doctor_id, 'glucose', notif_title, notif_body)
        )
        # Special alert for hypo/hyperglycemia
        if category in ["Hypoglycemia", "Hyperglycemia"]:
            alert_title = f"ALERT: {patient_name} has had a {category.lower()}!"
            alert_body = f"{patient_name} logged {category.lower()} ({glucose_level} mg/dL, {context}). Immediate attention may be needed."
            cur3.execute(
                "INSERT INTO notifications (user_id, type, title, body) VALUES (%s, %s, %s, %s)",
                (doctor_id, 'glucose', alert_title, alert_body)
            )
        db.commit()

    cur3.close()
    cur.close()
    cur2.close()
    db.close()
    return jsonify({"message": "Glucose log added", "category": category, "doctor_id": doctor_id})

# --- REPLACE THIS WHOLE FUNCTION ---
@app.route("/glucose/<int:user_id>", methods=["GET"])
def get_glucose(user_id):
    db = get_db()
    cursor = db.cursor(dictionary=True)
    cursor.execute(
        "SELECT id, timestamp, glucose_level, context, category FROM glucose_logs WHERE user_id=%s ORDER BY timestamp DESC LIMIT 30",
        (user_id,)
    )
    logs = cursor.fetchall()
    cursor.close()
    db.close()
    return jsonify(logs)
# --- NEW: Get today's glucose log count for a patient ---
@app.route("/glucose/daily_count/<int:user_id>", methods=["GET"])
def get_daily_glucose_count(user_id):
    today = date.today()
    db = get_db()
    c = db.cursor()
    c.execute("SELECT COUNT(*) FROM glucose_logs WHERE user_id=%s AND DATE(timestamp)=%s", (user_id, today))
    count = c.fetchone()[0]
    c.close()
    db.close()
    return jsonify({"count": count})

# --- NEW: Doctor adds medication for patient ---
# --- Under your medications endpoints in app.py ---

# --- GET: Active medications for a patient ---
@app.route("/medications/<int:patient_id>", methods=["GET"])
def get_medications(patient_id):
    db = get_db()
    cur = db.cursor(dictionary=True)
    cur.execute(
        "SELECT * FROM medications WHERE patient_id=%s AND is_active=1 ORDER BY prescribed_at DESC, id DESC",
        (patient_id,)
    )
    meds = cur.fetchall()
    cur.close()
    db.close()
    return jsonify(meds)

# --- ADD: Patient or doctor adds medication for patient ---
 #--- ADD: Patient or doctor adds medication for patient ---
@app.route("/medications", methods=["POST"])
def add_medication():
    data = request.json
    patient_id = data.get("patient_id")
    doctor_id = data.get("doctor_id")
    med_name = data.get("med_name")
    dosage = data.get("dosage")
    med_type = data.get("med_type")
    added_by_patient = int(data.get("added_by_patient", 0))

    # FIX: Only require doctor_id if NOT added by patient
    if not (patient_id and med_name and dosage and med_type):
        print("ERROR: Missing required fields")
        return jsonify({"error": "All fields required"}), 400
    if added_by_patient == 0 and not doctor_id:
        print("ERROR: doctor_id required when not added by patient")
        return jsonify({"error": "Doctor ID required"}), 400

    db = get_db()
    cur = db.cursor()
    cur.execute(
        "INSERT INTO medications (patient_id, doctor_id, med_name, dosage, med_type, added_by_patient, is_active) VALUES (%s, %s, %s, %s, %s, %s, 1)",
        (patient_id, doctor_id, med_name, dosage, med_type, added_by_patient)
    )
    # Notify patient if prescribed by doctor
    if doctor_id and int(added_by_patient) == 0:
        doc_cursor = db.cursor(dictionary=True)
        doc_cursor.execute("SELECT name FROM users WHERE id=%s", (doctor_id,))
        doctor_name = (doc_cursor.fetchone() or {}).get('name', 'Your doctor')
        notif_title = f"New prescription from {doctor_name}"
        notif_body = f"{doctor_name} prescribed {med_name} ({med_type}), dosage: {dosage}"
        doc_cursor.execute(
            "INSERT INTO notifications (user_id, type, title, body) VALUES (%s, %s, %s, %s)",
            (patient_id, 'medication', notif_title, notif_body)
        )
        db.commit()
        doc_cursor.close()
    db.commit()
    cur.close()
    db.close()
    print("Medication successfully added!")
    return jsonify({"message": "Medication added"})

# --- UPDATE: Doctor or patient updates medication dosage ---
# --- UPDATE: Doctor or patient updates medication dosage ---
@app.route("/medications/<int:med_id>", methods=["PUT"])
def update_medication(med_id):
    data = request.json
    doctor_id = data.get("doctor_id")
    new_dosage = data.get("dosage")
    if not new_dosage:
        return jsonify({"error": "dosage required"}), 400
    db = get_db()
    cur = db.cursor(dictionary=True)
    cur.execute("SELECT dosage, patient_id, med_name, med_type FROM medications WHERE id=%s", (med_id,))
    old = cur.fetchone()
    old_dosage = old["dosage"] if old else None
    patient_id = old["patient_id"] if old else None
    med_name = old["med_name"] if old else ""
    med_type = old["med_type"] if old else ""
    cur2 = db.cursor()
    cur2.execute("UPDATE medications SET dosage=%s WHERE id=%s", (new_dosage, med_id))
    # Audit log
    if doctor_id:
        cur2.execute(
            "INSERT INTO medication_changes (medication_id, doctor_id, change_type, old_dosage, new_dosage) VALUES (%s, %s, %s, %s, %s)",
            (med_id, doctor_id, "update", old_dosage, new_dosage)
        )
        # Notify patient about dosage change
        doc_cursor = db.cursor(dictionary=True)
        doc_cursor.execute("SELECT name FROM users WHERE id=%s", (doctor_id,))
        doctor_name = (doc_cursor.fetchone() or {}).get('name', 'Your doctor')
        notif_title = f"Medication dosage updated by {doctor_name}"
        notif_body = f"{doctor_name} updated {med_name} ({med_type}) dosage: {old_dosage} → {new_dosage}"
        doc_cursor.execute(
            "INSERT INTO notifications (user_id, type, title, body) VALUES (%s, %s, %s, %s)",
            (patient_id, 'medication', notif_title, notif_body)
        )
        db.commit()
        doc_cursor.close()
    db.commit()
    cur.close()
    cur2.close()
    db.close()
    return jsonify({"message": "Medication updated"})


# --- DELETE: Doctor or patient deactivates a medication ---
# --- DELETE: Doctor or patient deactivates a medication ---
@app.route("/medications/<int:med_id>", methods=["DELETE"])
def delete_medication(med_id):
    doctor_id = request.args.get("doctor_id")
    db = get_db()
    cur = db.cursor(dictionary=True)
    cur.execute("SELECT dosage, patient_id, med_name, med_type FROM medications WHERE id=%s", (med_id,))
    old = cur.fetchone()
    old_dosage = old["dosage"] if old else None
    patient_id = old["patient_id"] if old else None
    med_name = old["med_name"] if old else ""
    med_type = old["med_type"] if old else ""
    cur2 = db.cursor()
    cur2.execute("UPDATE medications SET is_active=0 WHERE id=%s", (med_id,))
    # Audit log
    if doctor_id:
        cur2.execute(
            "INSERT INTO medication_changes (medication_id, doctor_id, change_type, old_dosage, new_dosage) VALUES (%s, %s, %s, %s, %s)",
            (med_id, doctor_id, "delete", old_dosage, None)
        )
        # Notify patient about removal
        doc_cursor = db.cursor(dictionary=True)
        doc_cursor.execute("SELECT name FROM users WHERE id=%s", (doctor_id,))
        doctor_name = (doc_cursor.fetchone() or {}).get('name', 'Your doctor')
        notif_title = f"Medication removed by {doctor_name}"
        notif_body = f"{doctor_name} removed {med_name} ({med_type}), dosage: {old_dosage}"
        doc_cursor.execute(
            "INSERT INTO notifications (user_id, type, title, body) VALUES (%s, %s, %s, %s)",
            (patient_id, 'medication', notif_title, notif_body)
        )
        db.commit()
        doc_cursor.close()
    db.commit()
    cur.close()
    cur2.close()
    db.close()
    return jsonify({"message": "Medication deleted"})

# --- Meal Logs ---
@app.route("/meals", methods=["POST"])
def add_meal():
    data = request.json
    user_id = data.get("user_id")
    description = data.get("description")
    meal_type = data.get("meal_type", "other")
    calories = data.get("calories", 0)
    carbs = data.get("carbs", 0)
    protein = data.get("protein", 0)
    fat = data.get("fat", 0)
    if not user_id or not description:
        return jsonify({"error": "user_id and description required"}), 400
    db = get_db()
    cursor = db.cursor()
    cursor.execute(
        "INSERT INTO meals (user_id, description, meal_type, calories, carbs, protein, fat) VALUES (%s, %s, %s, %s, %s, %s, %s)",
        (user_id, description, meal_type, calories, carbs, protein, fat)
    )
    db.commit()
    cursor.close()
    db.close()
    return jsonify({"message": "Meal added"})

@app.route("/meals/<int:user_id>", methods=["GET"])
def get_meals(user_id):
    db = get_db()
    cursor = db.cursor(dictionary=True)
    cursor.execute(
        "SELECT id, timestamp, description, calories, carbs, protein, fat FROM meals WHERE user_id=%s ORDER BY timestamp DESC LIMIT 20",
        (user_id,)
    )
    meals = cursor.fetchall()
    cursor.close()
    db.close()
    return jsonify(meals)
@app.route("/meals/<int:meal_id>", methods=["DELETE"])
def delete_meal(meal_id):
    db = get_db()
    cursor = db.cursor()
    cursor.execute("DELETE FROM meals WHERE id=%s", (meal_id,))
    db.commit()
    cursor.close()
    db.close()
    return jsonify({"message": "Meal deleted"})

# --- Reminders ---
@app.route("/reminders", methods=["POST"])
def add_reminder():
    data = request.json
    user_id = data.get("user_id")
    title = data.get("title")
    type_ = data.get("type")
    time = data.get("time")
    frequency = data.get("frequency", "once")
    if not user_id or not title or not type_ or not time:
        return jsonify({"error": "All fields required"}), 400
    db = get_db()
    cursor = db.cursor()
    cursor.execute(
        "INSERT INTO reminders (user_id, title, type, time, frequency) VALUES (%s, %s, %s, %s, %s)",
        (user_id, title, type_, time, frequency)
    )
    db.commit()
    cursor.close()
    db.close()
    return jsonify({"message": "Reminder added"})
# --- Update Reminder ---
@app.route("/reminders/<int:reminder_id>", methods=["PUT"])
def update_reminder(reminder_id):
    data = request.json
    title = data.get("title")
    type_ = data.get("type")
    time = data.get("time")
    frequency = data.get("frequency", "once")
    if not title or not type_ or not time:
        return jsonify({"error": "All fields required"}), 400
    db = get_db()
    cursor = db.cursor()
    cursor.execute(
        "UPDATE reminders SET title=%s, type=%s, time=%s, frequency=%s WHERE id=%s",
        (title, type_, time, frequency, reminder_id)
    )
    db.commit()
    cursor.close()
    db.close()
    return jsonify({"message": "Reminder updated"})
# --- Delete Reminder ---
@app.route("/reminders/<int:reminder_id>", methods=["DELETE"])
def delete_reminder(reminder_id):
    db = get_db()
    cursor = db.cursor()
    cursor.execute("DELETE FROM reminders WHERE id=%s", (reminder_id,))
    db.commit()
    cursor.close()
    db.close()
    return jsonify({"message": "Reminder deleted"})
# --- Get Reminders for User ---
@app.route("/reminders/<int:user_id>", methods=["GET"])
def get_reminders(user_id):
    db = get_db()
    cursor = db.cursor(dictionary=True)
    cursor.execute(
        "SELECT id, title, type, time, frequency FROM reminders WHERE user_id=%s",
        (user_id,)
    )
    reminders = cursor.fetchall()
    # Ensure all time fields are strings
    for r in reminders:
        if isinstance(r.get('time'), (str, type(None))):
            continue
        r['time'] = str(r['time'])
    cursor.close()
    db.close()
    return jsonify(reminders)


# --- Messaging / Chat ---
@app.route("/messages", methods=["POST"])
def send_message():
    data = request.json
    sender_id = data.get("sender_id")
    receiver_id = data.get("receiver_id")
    message = data.get("message")
    if not sender_id or not receiver_id or not message:
        return jsonify({"error": "All fields required"}), 400
    db = get_db()
    cursor = db.cursor()
    cursor.execute(
        "INSERT INTO messages (sender_id, receiver_id, message) VALUES (%s, %s, %s)",
        (sender_id, receiver_id, message)
    )
    # Notification for receiver (doctor or patient)
    # Get patient name if sender is patient and receiver is doctor
    sender_name = get_patient_name(sender_id)
    receiver_role = None
    c2 = db.cursor(dictionary=True)
    c2.execute("SELECT role FROM users WHERE id=%s", (receiver_id,))
    row = c2.fetchone()
    if row:
        receiver_role = row['role']
    notif_title = "New Message"
    notif_body = message
    if receiver_role == "doctor":
        notif_title = f"New message from {sender_name}"
        notif_body = f"{sender_name}: {message}"
    cursor.execute(
        "INSERT INTO notifications (user_id, type, title, body) VALUES (%s, %s, %s, %s)",
        (receiver_id, 'message', notif_title, notif_body)
    )
    db.commit()
    c2.close()
    cursor.close()
    db.close()
    return jsonify({"message": "Message sent"})

@app.route("/messages/<int:user1_id>/<int:user2_id>", methods=["GET"])
def get_messages(user1_id, user2_id):
    db = get_db()
    cursor = db.cursor(dictionary=True)
    cursor.execute(
        """
        SELECT sender_id, receiver_id, message, timestamp 
        FROM messages 
        WHERE (sender_id=%s AND receiver_id=%s) OR (sender_id=%s AND receiver_id=%s)
        ORDER BY timestamp DESC LIMIT 40
        """,
        (user1_id, user2_id, user2_id, user1_id)
    )
    msgs = cursor.fetchall()
    cursor.close()
    db.close()
    # Return in chronological order
    return jsonify(list(reversed(msgs)))

# --- Articles ---
@app.route("/articles", methods=["POST"])
def add_article():
    data = request.json
    doctor_id = data.get("doctor_id")
    title = data.get("title")
    content = data.get("content")
    if not doctor_id or not title or not content:
        return jsonify({"error": "All fields required"}), 400
    db = get_db()
    cursor = db.cursor()
    cursor.execute(
        "INSERT INTO articles (doctor_id, title, content) VALUES (%s, %s, %s)",
        (doctor_id, title, content)
    )
    db.commit()
    cursor.close()
    db.close()
    return jsonify({"message": "Article posted"})

@app.route("/articles", methods=["GET"])
def get_articles():
    db = get_db()
    cursor = db.cursor(dictionary=True)
    cursor.execute(
        "SELECT articles.id, articles.title, articles.content, articles.timestamp, users.name as doctor_name FROM articles JOIN users ON articles.doctor_id=users.id ORDER BY articles.timestamp DESC"
    )
    articles = cursor.fetchall()
    cursor.close()
    db.close()
    return jsonify(articles)

# --- Challenges ---
@app.route("/challenges", methods=["POST"])
def create_challenge():
    data = request.json
    creator_id = data.get("creator_id")
    title = data.get("title")
    description = data.get("description")
    start_date = data.get("start_date")
    end_date = data.get("end_date")
    if not creator_id or not title or not description or not start_date or not end_date:
        return jsonify({"error": "All fields required"}), 400
    db = get_db()
    cursor = db.cursor()
    cursor.execute(
        "INSERT INTO challenges (creator_id, title, description, start_date, end_date) VALUES (%s, %s, %s, %s, %s)",
        (creator_id, title, description, start_date, end_date)
    )
    db.commit()
    cursor.close()
    db.close()
    return jsonify({"message": "Challenge created"})

@app.route("/challenges/join", methods=["POST"])
def join_challenge():
    data = request.json
    challenge_id = data.get("challenge_id")
    user_id = data.get("user_id")
    if not challenge_id or not user_id:
        return jsonify({"error": "All fields required"}), 400
    db = get_db()
    cursor = db.cursor()
    cursor.execute(
        "INSERT IGNORE INTO challenge_participants (challenge_id, user_id) VALUES (%s, %s)",
        (challenge_id, user_id)
    )
    db.commit()
    cursor.close()
    db.close()
    return jsonify({"message": "Joined challenge"})
# --- Add this endpoint for leaving a challenge ---
@app.route("/challenges/leave", methods=["POST"])
def leave_challenge():
    data = request.json
    challenge_id = data.get("challenge_id")
    user_id = data.get("user_id")
    if not challenge_id or not user_id:
        return jsonify({"error": "All fields required"}), 400
    db = get_db()
    cursor = db.cursor()
    cursor.execute(
        "DELETE FROM challenge_participants WHERE challenge_id=%s AND user_id=%s",
        (challenge_id, user_id)
    )
    db.commit()
    cursor.close()
    db.close()
    return jsonify({"message": "Left challenge"})

@app.route("/challenges", methods=["GET"])
def get_challenges():
    db = get_db()
    cursor = db.cursor(dictionary=True)
    cursor.execute(
        "SELECT challenges.*, users.name as creator_name FROM challenges JOIN users ON challenges.creator_id=users.id ORDER BY start_date DESC"
    )
    challenges = cursor.fetchall()
    cursor.close()
    db.close()
    return jsonify(challenges)

@app.route("/challenges/user/<int:user_id>", methods=["GET"])
def get_user_challenges(user_id):
    db = get_db()
    cursor = db.cursor(dictionary=True)
    cursor.execute("""
        SELECT c.*, u.name as creator_name 
        FROM challenge_participants cp
        JOIN challenges c ON cp.challenge_id = c.id
        JOIN users u ON c.creator_id = u.id
        WHERE cp.user_id = %s
        ORDER BY c.start_date DESC
    """, (user_id,))
    challenges = cursor.fetchall()
    cursor.close()
    db.close()
    return jsonify(challenges)

# --- FAQ ---
@app.route("/faqs", methods=["POST"])
def add_faq():
    data = request.json
    question = data.get("question")
    answer = data.get("answer", None)
    doctor_id = data.get("doctor_id", None)
    if not question:
        return jsonify({"error": "Question required"}), 400
    db = get_db()
    cursor = db.cursor()
    cursor.execute(
        "INSERT INTO faqs (question, answer, doctor_id) VALUES (%s, %s, %s)",
        (question, answer, doctor_id)
    )
    db.commit()
    cursor.close()
    db.close()
    return jsonify({"message": "FAQ submitted"})

@app.route("/faqs/answer/<int:faq_id>", methods=["POST"])
def answer_faq(faq_id):
    data = request.json
    answer = data.get("answer")
    doctor_id = data.get("doctor_id")
    if not answer or not doctor_id:
        return jsonify({"error": "Answer and doctor_id required"}), 400
    db = get_db()
    cursor = db.cursor()
    cursor.execute(
        "UPDATE faqs SET answer=%s, doctor_id=%s WHERE id=%s",
        (answer, doctor_id, faq_id)
    )
    db.commit()
    cursor.close()
    db.close()
    return jsonify({"message": "FAQ answered"})

@app.route("/faqs", methods=["GET"])
def get_faqs():
    db = get_db()
    cursor = db.cursor(dictionary=True)
    cursor.execute("""
        SELECT faqs.id, faqs.question, faqs.answer, faqs.timestamp, users.name as doctor_name
        FROM faqs LEFT JOIN users ON faqs.doctor_id = users.id
        ORDER BY faqs.timestamp DESC
    """)
    faqs = cursor.fetchall()
    cursor.close()
    db.close()
    return jsonify(faqs)
@app.route("/glucose/graph/<int:user_id>", methods=["GET"])
def get_glucose_for_graph(user_id):
    db = get_db()
    cursor = db.cursor(dictionary=True)
    cursor.execute(
        "SELECT timestamp, glucose_level, context, category FROM glucose_logs WHERE user_id=%s ORDER BY timestamp ASC LIMIT 100",
        (user_id,)
    )
    logs = cursor.fetchall()
    cursor.close()
    db.close()
    return jsonify(logs)
# --- Physical Activity: Add Activity ---
@app.route("/activities", methods=["POST"])
def add_activity():
    data = request.json
    user_id = data.get("user_id")
    activity_type = data.get("activity_type")
    duration = data.get("duration_minutes")
    calories = data.get("calories_burned")
    notes = data.get("notes", "")
    if not user_id or not activity_type:
        return jsonify({"error": "user_id and activity_type required"}), 400
    db = get_db()
    cur = db.cursor()
    cur.execute(
        "INSERT INTO physical_activities (user_id, activity_type, duration_minutes, calories_burned, notes) VALUES (%s, %s, %s, %s, %s)",
        (user_id, activity_type, duration, calories, notes)
    )
    db.commit()
    cur.close()
    db.close()
    return jsonify({"message": "Activity added"})
@app.route("/activities/<int:activity_id>", methods=["DELETE"])
def delete_activity(activity_id):
    db = get_db()
    cursor = db.cursor()
    cursor.execute("DELETE FROM physical_activities WHERE id=%s", (activity_id,))
    db.commit()
    cursor.close()
    db.close()
    return jsonify({"message": "Activity deleted"})

# --- Physical Activity: Get User Activities ---
@app.route("/activities/<int:user_id>", methods=["GET"])
def get_activities(user_id):
    db = get_db()
    cur = db.cursor(dictionary=True)
    cur.execute(
        "SELECT * FROM physical_activities WHERE user_id=%s ORDER BY timestamp DESC LIMIT 30",
        (user_id,)
    )
    activities = cur.fetchall()
    cur.close()
    db.close()
    return jsonify(activities)
# --- Appointments API ---

@app.route("/appointments", methods=["POST"])
def create_appointment():
    data = request.json
    doctor_id = data.get("doctor_id")
    patient_id = data.get("patient_id")
    appointment_time = data.get("appointment_time")
    notes = data.get("notes", "")
    if not (doctor_id and patient_id and appointment_time):
        return jsonify({"error": "doctor_id, patient_id, appointment_time required"}), 400
    db = get_db()
    c = db.cursor()
    c.execute(
        "INSERT INTO appointments (doctor_id, patient_id, appointment_time, notes) VALUES (%s, %s, %s, %s)",
        (doctor_id, patient_id, appointment_time, notes)
    )
    # --- NOTIFICATION LOGIC ---
    notif_title = "New Appointment"
    notif_body = "You have a new appointment scheduled."
    c.execute(
        "INSERT INTO notifications (user_id, type, title, body) VALUES (%s, %s, %s, %s)",
        (patient_id, 'appointment', notif_title, notif_body)
    )
    db.commit()
    c.close()
    db.close()
    return jsonify({"message": "Appointment scheduled"})

@app.route("/appointments/<int:appointment_id>", methods=["PUT"])
def update_appointment(appointment_id):
    data = request.json
    appointment_time = data.get("appointment_time")
    notes = data.get("notes", "")
    status = data.get("status")
    db = get_db()
    c = db.cursor()
    c.execute(
        "UPDATE appointments SET appointment_time=%s, notes=%s, status=%s WHERE id=%s",
        (appointment_time, notes, status, appointment_id)
    )
    c.execute("SELECT patient_id, doctor_id FROM appointments WHERE id=%s", (appointment_id,))
    row = c.fetchone()
    if row:
        patient_id, doctor_id = row
        patient_name = get_patient_name(patient_id)
        # Notify patient
        notif_title = "Appointment Updated"
        notif_body = "Your appointment was updated."
        c.execute(
            "INSERT INTO notifications (user_id, type, title, body) VALUES (%s, %s, %s, %s)",
            (patient_id, 'appointment', notif_title, notif_body)
        )
        # If patient rescheduled, notify doctor as well
        if status and status.lower() == "rescheduled":
            doc_notif_title = f"{patient_name} rescheduled an appointment"
            doc_notif_body = f"{patient_name} has rescheduled their appointment. Please review."
            c.execute(
                "INSERT INTO notifications (user_id, type, title, body) VALUES (%s, %s, %s, %s)",
                (doctor_id, 'appointment', doc_notif_title, doc_notif_body)
            )
    db.commit()
    c.close()
    db.close()
    return jsonify({"message": "Appointment updated"})
@app.route("/appointments/<int:appointment_id>", methods=["DELETE"])
def delete_appointment(appointment_id):
    db = get_db()
    c = db.cursor()
    c.execute("SELECT patient_id, doctor_id FROM appointments WHERE id=%s", (appointment_id,))
    row = c.fetchone()
    if row:
        patient_id, doctor_id = row
        patient_name = get_patient_name(patient_id)
        notif_title = "Appointment Cancelled"
        notif_body = "Your appointment was cancelled."
        c.execute(
            "INSERT INTO notifications (user_id, type, title, body) VALUES (%s, %s, %s, %s)",
            (patient_id, 'appointment', notif_title, notif_body)
        )
        # Notify doctor as well
        doc_notif_title = f"{patient_name} cancelled an appointment"
        doc_notif_body = f"{patient_name} has cancelled their appointment."
        c.execute(
            "INSERT INTO notifications (user_id, type, title, body) VALUES (%s, %s, %s, %s)",
            (doctor_id, 'appointment', doc_notif_title, doc_notif_body)
        )
    c.execute("DELETE FROM appointments WHERE id=%s", (appointment_id,))
    db.commit()
    c.close()
    db.close()
    return jsonify({"message": "Appointment cancelled"})
@app.route("/appointments/<int:doctor_id>", methods=["GET"])
def get_appointments(doctor_id):
    db = get_db()
    c = db.cursor(dictionary=True)
    c.execute("""
        SELECT a.*, u.name as patient_name, u.email as patient_email
        FROM appointments a
        JOIN users u ON a.patient_id = u.id
        WHERE a.doctor_id = %s
        ORDER BY a.appointment_time ASC
    """, (doctor_id,))
    appointments = c.fetchall()
    c.close()
    db.close()
    return jsonify(appointments)
@app.route("/appointments/patient/<int:patient_id>", methods=["GET"])
def get_patient_appointments(patient_id):
    db = get_db()
    c = db.cursor(dictionary=True)
    c.execute("""
        SELECT a.*, u.name as doctor_name, u.email as doctor_email
        FROM appointments a
        JOIN users u ON a.doctor_id = u.id
        WHERE a.patient_id = %s
        ORDER BY a.appointment_time ASC
    """, (patient_id,))
    appointments = c.fetchall()
    c.close()
    db.close()
    return jsonify(appointments)
# --- Notifications API ---

@app.route("/notifications/<int:user_id>", methods=["GET"])
def get_notifications(user_id):
    db = get_db()
    cur = db.cursor(dictionary=True)
    cur.execute(
        "SELECT * FROM notifications WHERE user_id=%s ORDER BY created_at DESC LIMIT 30",
        (user_id,)
    )
    notifications = cur.fetchall()
    cur.close()
    db.close()
    return jsonify(notifications)

@app.route("/notifications/mark_read/<int:user_id>", methods=["PUT"])
def mark_notifications_read(user_id):
    db = get_db()
    cur = db.cursor()
    cur.execute("UPDATE notifications SET read=1 WHERE user_id=%s", (user_id,))
    db.commit()
    cur.close()
    db.close()
    return jsonify({"message": "All notifications marked as read"})

if __name__ == "__main__":
    app.run(host="0.0.0.0")