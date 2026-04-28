import { Router } from "express";

const router = Router();

const PAGE_SHELL = (title: string, body: string) => `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>${title} — Tatva Academy</title>
  <style>
    *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
    body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif; color: #1a1a1a; line-height: 1.7; background: #fafafa; }
    a { color: #6b4226; }
    header { background: #fff; border-bottom: 1px solid #e5e5e5; padding: 1rem 2rem; display: flex; align-items: center; gap: 0.75rem; }
    header .logo { font-size: 1.25rem; font-weight: 700; color: #6b4226; letter-spacing: 0.04em; text-decoration: none; }
    main { max-width: 720px; margin: 2.5rem auto; padding: 2.5rem; background: #fff; border-radius: 12px; box-shadow: 0 1px 3px rgba(0,0,0,0.06); }
    h1 { font-size: 1.75rem; margin-bottom: 0.25rem; color: #1a1a1a; }
    .subtitle { color: #666; font-size: 0.9rem; margin-bottom: 2rem; }
    h2 { font-size: 1.15rem; margin-top: 2rem; margin-bottom: 0.5rem; color: #333; }
    p, li { font-size: 0.95rem; color: #444; }
    ul { padding-left: 1.25rem; margin-bottom: 1rem; }
    li { margin-bottom: 0.35rem; }
    p { margin-bottom: 1rem; }
    footer { text-align: center; padding: 2rem; color: #999; font-size: 0.8rem; }

    .contact-grid { display: grid; gap: 2rem; margin: 2rem 0; }
    .contact-card { display: flex; align-items: flex-start; gap: 1rem; }
    .contact-card .icon { width: 48px; height: 48px; background: #f5f0eb; border-radius: 10px; display: flex; align-items: center; justify-content: center; flex-shrink: 0; font-size: 1.3rem; }
    .contact-card .label { font-size: 0.75rem; font-weight: 600; letter-spacing: 0.08em; color: #888; text-transform: uppercase; }
    .contact-card .value { font-size: 1.1rem; font-weight: 600; color: #1a1a1a; }
    .contact-card a { color: #1a1a1a; text-decoration: underline; text-underline-offset: 2px; }

    .form-group { margin-bottom: 1.25rem; }
    .form-group label { display: block; font-size: 0.85rem; font-weight: 600; margin-bottom: 0.35rem; color: #333; }
    .form-group input, .form-group textarea, .form-group select { width: 100%; padding: 0.65rem 0.85rem; border: 1px solid #ddd; border-radius: 8px; font-size: 0.95rem; font-family: inherit; background: #fafafa; transition: border-color 0.2s; }
    .form-group input:focus, .form-group textarea:focus, .form-group select:focus { outline: none; border-color: #6b4226; background: #fff; }
    .form-group textarea { resize: vertical; min-height: 120px; }
    .btn { display: inline-block; padding: 0.7rem 2rem; background: #6b4226; color: #fff; border: none; border-radius: 8px; font-size: 0.95rem; font-weight: 600; cursor: pointer; transition: background 0.2s; }
    .btn:hover { background: #8b5a3a; }
    .btn:disabled { opacity: 0.6; cursor: not-allowed; }
    .success-msg { background: #eaf7ec; color: #256b2e; padding: 1rem; border-radius: 8px; margin-bottom: 1.5rem; display: none; }
    .error-msg { background: #fde8e8; color: #9b1c1c; padding: 1rem; border-radius: 8px; margin-bottom: 1.5rem; display: none; }
    hr { border: none; border-top: 1px solid #eee; margin: 2.5rem 0; }
  </style>
</head>
<body>
  <header>
    <a href="https://www.tatva.academy" class="logo">TATVA ACADEMY</a>
  </header>
  ${body}
  <footer>&copy; ${new Date().getFullYear()} Tatva Academy. All Rights Reserved.</footer>
</body>
</html>`;

router.get("/privacy-policy", (_req, res) => {
  const body = `
  <main>
    <h1>Privacy Policy</h1>
    <p class="subtitle">Last updated: April 28, 2026</p>

    <p>Tatva Academy ("we," "us," or "our") operates the Tatva School App and related services. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our mobile application and web services.</p>

    <h2>1. Information We Collect</h2>
    <p>We may collect the following types of information:</p>
    <ul>
      <li><strong>Account Information:</strong> Name, email address, phone number, and role (e.g., teacher, parent, student) provided during registration.</li>
      <li><strong>Profile Information:</strong> Profile photos, class assignments, and preferences you set within the app.</li>
      <li><strong>Academic Data:</strong> Attendance records, grades, homework submissions, schedules, and behavioral notes managed through the app.</li>
      <li><strong>Communications:</strong> Messages sent through the app's messaging system.</li>
      <li><strong>Device Information:</strong> Device type, operating system, app version, and push notification tokens.</li>
      <li><strong>Usage Data:</strong> How you interact with the app, including features accessed and time spent.</li>
    </ul>

    <h2>2. How We Use Your Information</h2>
    <p>We use the collected information to:</p>
    <ul>
      <li>Provide, maintain, and improve the Tatva School App and its features.</li>
      <li>Facilitate communication between teachers, parents, and school administration.</li>
      <li>Send important notifications such as announcements, schedule changes, and homework updates.</li>
      <li>Manage attendance, grades, and academic progress tracking.</li>
      <li>Ensure security and prevent unauthorized access to accounts.</li>
      <li>Comply with legal obligations.</li>
    </ul>

    <h2>3. Information Sharing</h2>
    <p>We do not sell your personal information. We may share information only in the following circumstances:</p>
    <ul>
      <li><strong>Within the School Community:</strong> Teachers, parents, and administrators may access relevant academic and communication data as permitted by their roles.</li>
      <li><strong>Service Providers:</strong> We use trusted third-party services (e.g., Firebase by Google, cloud hosting) to operate the app. These providers process data on our behalf under strict confidentiality agreements.</li>
      <li><strong>Legal Requirements:</strong> We may disclose information if required by law or to protect the rights and safety of our users and the school community.</li>
    </ul>

    <h2>4. Data Storage and Security</h2>
    <p>Your data is stored securely using Google Cloud Platform and Firebase infrastructure. We implement industry-standard security measures including encryption in transit, access controls, and regular security reviews. However, no method of electronic storage is 100% secure, and we cannot guarantee absolute security.</p>

    <h2>5. Data Retention</h2>
    <p>We retain your information for as long as your account is active or as needed to provide services. When an account is deactivated, we will delete or anonymize personal data within a reasonable period, unless retention is required by law.</p>

    <h2>6. Your Rights</h2>
    <p>You have the right to:</p>
    <ul>
      <li>Access the personal information we hold about you.</li>
      <li>Request correction of inaccurate data.</li>
      <li>Request deletion of your account and associated data.</li>
      <li>Opt out of non-essential notifications.</li>
    </ul>
    <p>To exercise any of these rights, contact us at <a href="mailto:namaste@tatva.academy">namaste@tatva.academy</a>.</p>

    <h2>7. Third-Party Services</h2>
    <p>The app may integrate with third-party services such as Firebase Authentication, Cloud Firestore, and Firebase Cloud Messaging. These services have their own privacy policies, and we encourage you to review them.</p>

    <h2>8. Changes to This Policy</h2>
    <p>We may update this Privacy Policy from time to time. We will notify you of any material changes through the app or via email. Continued use of the app after changes constitutes acceptance of the updated policy.</p>

    <h2>9. Contact Us</h2>
    <p>If you have questions or concerns about this Privacy Policy, please contact us:</p>
    <ul>
      <li><strong>Email:</strong> <a href="mailto:namaste@tatva.academy">namaste@tatva.academy</a></li>
      <li><strong>Phone:</strong> +1 (737) 732-3286</li>
      <li><strong>Address:</strong> 12825 Burnet Rd, Austin, TX 78727</li>
    </ul>
  </main>`;

  res.send(PAGE_SHELL("Privacy Policy", body));
});

router.get("/support", (_req, res) => {
  const body = `
  <main>
    <h1>Get in Touch</h1>
    <p class="subtitle">We'd love to hear from you. Reach out with any questions, feedback, or concerns.</p>

    <div class="contact-grid">
      <div class="contact-card">
        <div class="icon">&#9993;</div>
        <div>
          <div class="label">Address</div>
          <div class="value">12825 Burnet Rd, Austin, TX 78727</div>
        </div>
      </div>
      <div class="contact-card">
        <div class="icon">&#9993;</div>
        <div>
          <div class="label">Email</div>
          <div class="value"><a href="mailto:namaste@tatva.academy">namaste@tatva.academy</a></div>
        </div>
      </div>
      <div class="contact-card">
        <div class="icon">&#9742;</div>
        <div>
          <div class="label">Phone</div>
          <div class="value"><a href="tel:+17377323286">+1 (737) 732-3286</a></div>
        </div>
      </div>
    </div>

    <hr>

    <h2>Send Us a Message</h2>
    <div id="success" class="success-msg">Your message has been sent. We'll get back to you soon!</div>
    <div id="error" class="error-msg">Something went wrong. Please try again or email us directly.</div>

    <form id="supportForm">
      <div class="form-group">
        <label for="name">Your Name</label>
        <input type="text" id="name" name="name" required placeholder="Full name">
      </div>
      <div class="form-group">
        <label for="email">Email Address</label>
        <input type="email" id="email" name="email" required placeholder="you@example.com">
      </div>
      <div class="form-group">
        <label for="subject">Subject</label>
        <select id="subject" name="subject" required>
          <option value="">Select a topic</option>
          <option value="general">General Inquiry</option>
          <option value="account">Account Issue</option>
          <option value="bug">Bug Report</option>
          <option value="feedback">Feedback</option>
          <option value="other">Other</option>
        </select>
      </div>
      <div class="form-group">
        <label for="message">Message</label>
        <textarea id="message" name="message" required placeholder="How can we help?"></textarea>
      </div>
      <button type="submit" class="btn" id="submitBtn">Send Message</button>
    </form>
  </main>

  <script>
    document.getElementById('supportForm').addEventListener('submit', async function(e) {
      e.preventDefault();
      const btn = document.getElementById('submitBtn');
      const success = document.getElementById('success');
      const error = document.getElementById('error');
      success.style.display = 'none';
      error.style.display = 'none';
      btn.disabled = true;
      btn.textContent = 'Sending...';

      try {
        const res = await fetch('/api/support', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            name: document.getElementById('name').value,
            email: document.getElementById('email').value,
            subject: document.getElementById('subject').value,
            message: document.getElementById('message').value,
          }),
        });
        if (!res.ok) throw new Error('Failed');
        success.style.display = 'block';
        this.reset();
      } catch {
        error.style.display = 'block';
      } finally {
        btn.disabled = false;
        btn.textContent = 'Send Message';
      }
    });
  </script>`;

  res.send(PAGE_SHELL("Support", body));
});

router.post("/support", async (req, res) => {
  const { name, email, subject, message } = req.body;
  if (!name || !email || !subject || !message) {
    res.status(400).json({ error: "All fields are required" });
    return;
  }

  const admin = await import("firebase-admin");
  const db = admin.default.firestore();
  await db.collection("support_requests").add({
    name,
    email,
    subject,
    message,
    createdAt: admin.default.firestore.FieldValue.serverTimestamp(),
  });

  res.json({ success: true });
});

export default router;
