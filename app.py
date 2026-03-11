import sqlite3
from flask import Flask, request, jsonify
from flask_cors import CORS
import smtplib
from email.message import EmailMessage
import os
import pdfplumber
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity
from email.mime.text import MIMEText
import json 


app = Flask(__name__)
CORS(app, resources={r"/*": {"origins": "*"}})

DB_PATH = os.path.join('..', 'database', 'users.db')
UPLOAD_FOLDER = 'uploads'

if not os.path.exists(UPLOAD_FOLDER): os.makedirs(UPLOAD_FOLDER)
if not os.path.exists('../database'): os.makedirs('../database')

def init_db():
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    cursor.execute('''CREATE TABLE IF NOT EXISTS users 
                      (id INTEGER PRIMARY KEY AUTOINCREMENT, 
                       username TEXT, email TEXT UNIQUE, 
                       password TEXT, role TEXT)''')
    conn.commit()
    conn.close()

init_db()

def init_job_db():
    conn = sqlite3.connect(DB_PATH) 
    cursor = conn.cursor()
    
    
    cursor.execute('''CREATE TABLE IF NOT EXISTS jobs 
                      (id INTEGER PRIMARY KEY AUTOINCREMENT, 
                       title TEXT, 
                       skills TEXT, 
                       experience INTEGER, 
                       location TEXT, 
                       threshold INTEGER)''')
    conn.commit()
    conn.close()


init_job_db()

def init_app_db():
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    cursor.execute('''CREATE TABLE IF NOT EXISTS applications 
                      (id INTEGER PRIMARY KEY AUTOINCREMENT, 
                       email TEXT, 
                       job_title TEXT, 
                       score REAL, 
                       status TEXT)''')
    conn.commit()
    conn.close()

init_app_db()

def send_email(target_email, job_results):
    sender = "accitrack03@gmail.com"
    password = "veoy cwtd ekek yqjv"

    subject = "Application Result - ParsePort AI"
    
    table_content = ""
    for res in job_results:
        color = "green" if res['status'] == "Shortlisted" else "red"
        table_content += f"<tr><td>{res['title']}</td><td style='color:{color}'>{res['status']}</td><td>{res['score']}%</td></tr>"

    html_body = f"""
    <html>
        <body>
            <h2>Application Feedback</h2>
            <p>Hi, your resume has been analyzed by our AI for the following positions:</p>
            <table border="1" cellpadding="10" style="border-collapse: collapse;">
                <tr style="background-color: #f2f2f2;"><th>Job Role</th><th>Status</th><th>Match Score</th></tr>
                {table_content}
            </table>
            <br>
            <p>Thank you for using ParsePort!</p>
        </body>
    </html>
    """

    msg = MIMEText(html_body, 'html')
    msg['Subject'] = subject
    msg['From'] = sender
    msg['To'] = target_email

    with smtplib.SMTP_SSL('smtp.gmail.com', 465) as server:
        server.login(sender, password)
        server.sendmail(sender, target_email, msg.as_string())

@app.route('/add_job', methods=['POST'])
def add_job():
    data = request.json
    print("Received Job Data:", data)
    try:
        conn = sqlite3.connect(DB_PATH)
        cursor = conn.cursor()
        cursor.execute("""
            INSERT INTO jobs (title, skills, experience, location, threshold) 
            VALUES (?, ?, ?, ?, ?)
        """, (data['title'], data['skills'], data['experience'], data['location'], data['threshold']))
        conn.commit()
        conn.close()
        return jsonify({"message": "Job posted successfully!"}), 201
    except Exception as e:
        print("Error:", str(e))
        return jsonify({"message": str(e)}), 400
    finally: conn.close()


def extract_text_from_pdf(path):
    with pdfplumber.open(path) as pdf:
        text = ""
        for page in pdf.pages:
            text += page.extract_text()
        return text


def calculate_score(resume_text, job_skills):
    documents = [resume_text, job_skills]
    count_vectorizer = TfidfVectorizer()
    sparse_matrix = count_vectorizer.fit_transform(documents)
    
    
    similarity_matrix = cosine_similarity(sparse_matrix)
    score = similarity_matrix[0][1] * 100 
    return round(score, 2)

@app.route('/apply_bulk', methods=['POST'])
def apply_bulk():
    try:
        email = request.form.get('email')
        job_ids = json.loads(request.form.get('job_ids'))
        resume_file = request.files['resume']
        
        resume_path = os.path.join(UPLOAD_FOLDER, resume_file.filename)
        resume_file.save(resume_path)

        resume_text = extract_text_from_pdf(resume_path)
        print("Resume text extracted successfully!")

        results = []
        conn = sqlite3.connect(DB_PATH)
        cursor = conn.cursor()

        for j_id in job_ids:
            cursor.execute("SELECT title, skills, threshold FROM jobs WHERE id = ?", (j_id,))
            job = cursor.fetchone()
            
            if job:
                job_title, job_skills, threshold = job
                score = calculate_score(resume_text, job_skills)
                status = "Shortlisted" if score >= threshold else "Not Selected"
                results.append({"title": job_title, "status": status, "score": score})
                
                cursor.execute("""
                    INSERT INTO applications (email, job_title, score, status) 
                    VALUES (?, ?, ?, ?)
                """, (email, job_title, score, status))
                # ---------------------------------

        conn.commit() 
        conn.close()

        send_email(email, results)
        return jsonify({"message": "Processed Successfully", "results": results}), 200

    except Exception as e:
        print("Backend Error Details:", str(e)) 
        return jsonify({"message": "Error occurred", "details": str(e)}), 500
    
@app.route('/get_jobs', methods=['GET'])
def get_jobs():
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM jobs")
    jobs = [{"id": r[0], "title": r[1], "skills": r[2], "experience": r[3], "location": r[4], "threshold": r[5]} for r in cursor.fetchall()]
    conn.close()
    return jsonify(jobs)

@app.route('/delete_job/<int:id>', methods=['DELETE'])
def delete_job(id):
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    cursor.execute("DELETE FROM jobs WHERE id=?", (id,))
    conn.commit()
    conn.close()
    return jsonify({"message": "Deleted"})

@app.route('/signup', methods=['POST'])
def signup():
    data = request.json
    print("Recieved Data : ",data)
    try:
        conn = sqlite3.connect(DB_PATH)
        cursor = conn.cursor()
        cursor.execute("INSERT INTO users (username, email, password, role) VALUES (?, ?, ?, ?)", 
                       (data['username'], data['email'], data['password'], data['role']))
        conn.commit()
        return jsonify({"message": "Success"}), 201
    except sqlite3.IntegrityError:
        return jsonify({"message": "Email already exists!"}), 400
    finally: conn.close()

@app.route('/login', methods=['POST'])
def login():
    data = request.json
    print(f"Login attempt: {data}")
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    cursor.execute("SELECT role FROM users WHERE email=? AND password=?", (data['email'], data['password']))
    user = cursor.fetchone()
    conn.close()
    if user: return jsonify({"message": "Success", "role": user[0]}), 200
    return jsonify({"message": "Invalid Credentials"}), 401

@app.route('/get_stats', methods=['GET'])
def get_stats():
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    
    cursor.execute("SELECT COUNT(*) FROM jobs")
    total_jobs = cursor.fetchone()[0]
    
   
    try:
        cursor.execute("SELECT COUNT(*) FROM applications")
        total_applicants = cursor.fetchone()[0]
    except:
        total_applicants = 0
        
    conn.close()
    return jsonify({
        "total_jobs": total_jobs,
        "total_applicants": total_applicants
    })


@app.route('/get_applications', methods=['GET'])
def get_applications():
    try:
        conn = sqlite3.connect(DB_PATH)
        cursor = conn.cursor()
        cursor.execute("SELECT id, email, job_title, score, status FROM applications ORDER BY score DESC")
        rows = cursor.fetchall()
        
        apps = []
        for r in rows:
            apps.append({
                "id": r[0],
                "email": r[1],
                "job": r[2],
                "score": r[3],
                "status": r[4]
            })
            
        conn.close()
        return jsonify(apps), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/parse', methods=['POST'])
def parse_resume():
    return jsonify({"status": "Shortlisted", "score": "85%"})
if __name__ == '__main__':
    init_db()      
    init_job_db()  
    init_app_db()  
    port = int(os.environ.get("PORT", 5000))
    app.run(host='0.0.0.0', port=port)