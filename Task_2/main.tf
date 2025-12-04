provider "aws"{
  region = "ap-southeast-2" # Sydney
}

locals{
  name_prefix = "Shivpoojan_Tiwari" 
}
data "aws_vpc" "default"{
  default = true
}
resource "aws_security_group" "resume_sg" {
  name        = "${local.name_prefix}_Resume_SG"
  description = "Allow HTTP and SSH only"
  vpc_id      = data.aws_vpc.default.id
  ingress {
    description = "Allow HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "Allow SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = { Name = "${local.name_prefix}_Resume_SG" }
}
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}
resource "aws_instance" "resume_server" {
  ami           = data.aws_ami.amazon_linux_2023.id
  instance_type = "t2.micro" 
  
  vpc_security_group_ids = [aws_security_group.resume_sg.id]
  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install nginx -y
              systemctl start nginx
              systemctl enable nginx
              
              # Create a simple Resume HTML file
              cat <<EOT > /usr/share/nginx/html/index.html
            
             <!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width,initial-scale=1" />
  <title>Dynamic Resume — Priyanshu</title>
  <style>
    :root{--bg:#f4f4f9;--card:#fff;--accent:#16a085;--muted:#666}
    *{box-sizing:border-box}
    body{font-family:Segoe UI, Tahoma, Geneva, Verdana, sans-serif;margin:0;background:var(--bg);color:#222}
    .app{max-width:1100px;margin:32px auto;padding:20px;display:grid;grid-template-columns:360px 1fr;gap:20px}
    .panel{background:var(--card);padding:18px;border-radius:10px;box-shadow:0 6px 18px rgba(10,10,20,0.06)}
    h2{margin:0 0 12px 0;color:var(--accent)}
    label{display:block;font-weight:600;margin:10px 0 6px;color:var(--muted)}
    input[type=text],input[type=email],textarea,select{width:100%;padding:10px;border-radius:6px;border:1px solid #e6e8ea;font-size:14px}
    textarea{min-height:96px;resize:vertical}
    .small{font-size:13px;color:#888}
    .preview{padding:32px}
    .resume{max-width:800px;margin:0 auto;background:var(--card);padding:28px;border-radius:8px}
    h1{font-size:26px;margin:0;color:#263544}
    h3{margin:6px 0 12px;font-weight:400;color:var(--accent)}
    .label{font-weight:700;color:#555;margin-bottom:6px}
    .tags{margin-top:6px}
    .tag{display:inline-block;background:#e0f2f1;color:#00695c;padding:6px 10px;border-radius:4px;margin:4px 6px 0 0;font-size:0.95em}
    .controls{display:flex;gap:8px;flex-wrap:wrap;margin-top:12px}
    button{padding:8px 12px;border-radius:8px;border:0;background:var(--accent);color:#fff;font-weight:600;cursor:pointer}
    button.secondary{background:#4b5962}
    .two-col{display:flex;gap:12px}
    .meta{font-size:14px;color:#444;margin-top:8px}
    footer{font-size:13px;color:#888;margin-top:18px;text-align:center}
    @media (max-width:900px){.app{grid-template-columns:1fr;max-width:760px;padding:12px}}
  </style>
</head>
<body>
  <div class="app">
    <div class="panel" id="editor">
      <h2>Resume Editor</h2>

      <label for="name">Full name</label>
      <input id="name" type="text" placeholder="Priyanshu Rajput" />

      <label for="title">Title / Headline</label>
      <input id="title" type="text" placeholder="Cloud Trainee & DevOps Enthusiast" />

      <label for="email">Email</label>
      <input id="email" type="email" placeholder="priyanshu854395@gmail.com" />

      <label for="skills">Skills (comma separated)</label>
      <input id="skills" type="text" placeholder="AWS Cloud, Terraform, Linux, Java, Cybersecurity" />

      <label for="summary">Professional summary</label>
      <textarea id="summary" placeholder="Short summary about you"></textarea>

      <label for="hosted">Footer / hosted note</label>
      <input id="hosted" type="text" placeholder="Hosted on AWS EC2 (t2.micro) | Deployed with Terraform" />

      <div class="controls">
        <button id="save">Save (local)</button>
        <button id="reset" class="secondary">Reset sample</button>
        <button id="clear" class="secondary">Clear</button>
        <button id="exportJson">Export JSON</button>
        <button id="importJson" class="secondary">Import JSON</button>
        <button id="downloadHtml">Download HTML</button>
        <button id="printPdf">Print / Save as PDF</button>
      </div>

      <p class="small">Changes update the preview on the right instantly. Data is stored in your browser (localStorage).</p>

      <input id="fileInput" type="file" accept="application/json" style="display:none" />
    </div>

    <div class="panel preview">
      <h2>Live Preview</h2>
      <div class="resume" id="resume">
        <header>
          <h1 id="pv-name">Priyanshu Rajput</h1>
          <h3 id="pv-title">Cloud Trainee & DevOps Enthusiast</h3>
        </header>
        <hr />
        <section>
          <p class="label">Contact Info:</p>
          <p id="pv-email">✉ priyanshu854395@gmail.com</p>
        </section>

        <section style="margin-top:12px">
          <p class="label">Technical Skills:</p>
          <div class="tags" id="pv-skills"></div>
        </section>

        <section style="margin-top:12px">
          <p class="label">Professional Summary:</p>
          <p id="pv-summary">Aspiring Cloud Practitioner with a strong foundation in AWS infrastructure, Infrastructure as Code (IaC), and secure system design. Passionate about automation, cloud-native solutions, and building resilient, scalable architectures.</p>
        </section>

        <footer id="pv-hosted" style="margin-top:18px;color:#888;text-align:center">Hosted on AWS EC2 (t2.micro) | Deployed with Terraform</footer>
      </div>

      <footer>Tip: use "Download HTML" to save a standalone copy you can host anywhere.</footer>
    </div>
  </div>

  <script>
    // --- Utilities ---
    const $ = id => document.getElementById(id);

    const sample = {
      name: 'Priyanshu Rajput',
      title: 'Cloud Trainee & DevOps Enthusiast',
      email: 'priyanshu854395@gmail.com',
      skills: 'AWS Cloud, Terraform, Linux Administration, Java Programming, Cybersecurity',
      summary: 'Aspiring Cloud Practitioner with a strong foundation in AWS infrastructure, Infrastructure as Code (IaC), and secure system design. Passionate about automation, cloud-native solutions, and building resilient, scalable architectures.',
      hosted: 'Hosted on AWS EC2 (t2.micro) | Deployed with Terraform'
    };

    // Elements
    const fields = ['name','title','email','skills','summary','hosted'];
    const inputs = {};
    fields.forEach(f => inputs[f] = $(f));

    // Preview elements
    const pv = { name: $('pv-name'), title: $('pv-title'), email: $('pv-email'), skills: $('pv-skills'), summary: $('pv-summary'), hosted: $('pv-hosted') };

    // Load saved or sample
    function loadData(){
      const raw = localStorage.getItem('dynamicResume:shiv');
      let data = raw ? JSON.parse(raw) : sample;
      fields.forEach(f => inputs[f].value = data[f] || '');
      renderPreview();
    }

    function saveData(){
      const data = {};
      fields.forEach(f => data[f] = inputs[f].value.trim());
      localStorage.setItem('dynamicResume:shiv', JSON.stringify(data));
      alert('Saved locally in your browser.');
    }

    function renderPreview(){
      pv.name.textContent = inputs.name.value || 'Your name';
      pv.title.textContent = inputs.title.value || '';
      pv.email.textContent = inputs.email.value ? '✉ ' + inputs.email.value : '';
      pv.summary.textContent = inputs.summary.value || '';
      pv.hosted.textContent = inputs.hosted.value || '';

      // Skills as tags
      pv.skills.innerHTML = '';
      const raw = inputs.skills.value || '';
      const list = raw.split(',').map(s => s.trim()).filter(Boolean);
      if(list.length === 0){ pv.skills.innerHTML = '<span class="small">No skills added</span>'; return; }
      list.forEach(sk => {
        const sp = document.createElement('span');
        sp.className = 'tag'; sp.textContent = sk; pv.skills.appendChild(sp);
      });
    }

    // Attach live updates
    fields.forEach(f => inputs[f].addEventListener('input', renderPreview));

    // Buttons
    $('save').addEventListener('click', saveData);
    $('reset').addEventListener('click', () => { if(confirm('Reset to sample content?')){ localStorage.removeItem('dynamicResume:shiv'); loadData(); }});
    $('clear').addEventListener('click', () => { if(confirm('Clear all fields?')){ fields.forEach(f => inputs[f].value=''); renderPreview(); }});

    // Export JSON
    $('exportJson').addEventListener('click', () => {
      const data = {};
      fields.forEach(f => data[f] = inputs[f].value.trim());
      const blob = new Blob([JSON.stringify(data, null, 2)], {type:'application/json'});
      const url = URL.createObjectURL(blob);
      const a = document.createElement('a'); a.href = url; a.download = 'resume-data.json'; document.body.appendChild(a); a.click(); a.remove(); URL.revokeObjectURL(url);
    });

    // Import JSON
    $('importJson').addEventListener('click', () => $('fileInput').click());
    $('fileInput').addEventListener('change', (e) => {
      const f = e.target.files[0]; if(!f) return;
      const reader = new FileReader();
      reader.onload = ev => {
        try{
          const data = JSON.parse(ev.target.result);
          fields.forEach(ff => inputs[ff].value = data[ff] || '');
          renderPreview();
          alert('Imported successfully');
        }catch(err){ alert('Invalid JSON file'); }
      };
      reader.readAsText(f);
      e.target.value = '';
    });

    // Download standalone HTML
    $('downloadHtml').addEventListener('click', () => {
      const html = `<!doctype html>\n<html><head><meta charset=\"utf-8\"><meta name=\"viewport\" content=\"width=device-width,initial-scale=1\">`+
        `<title>${escapeHtml(inputs.name.value || 'Resume')}</title><style>body{font-family:Segoe UI, Tahoma, Geneva, Verdana, sans-serif;background:${'#f4f4f9'};color:#222;padding:20px}.resume{max-width:800px;margin:0 auto;background:#fff;padding:28px;border-radius:8px}h1{font-size:26px}h3{color:${'#16a085'};font-weight:400}</style></head><body>`+
        document.getElementById('resume').outerHTML + `</body></html>`;
      const blob = new Blob([html], {type:'text/html'});
      const url = URL.createObjectURL(blob);
      const a = document.createElement('a'); a.href = url; a.download = (inputs.name.value||'resume') + '.html'; document.body.appendChild(a); a.click(); a.remove(); URL.revokeObjectURL(url);
    });

    // Print
    $('printPdf').addEventListener('click', () => { window.print(); });

    // Small helper
    function escapeHtml(s){ return (s||'').replace(/[&<>\"']/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":"&#39;"})[c]); }

    // Init
    loadData();
  </script>
</body>
</html>

              EOT
              EOF

  tags = { Name = "${local.name_prefix}_Resume_App" }
}
output "website_url" {
  value = "http://${aws_instance.resume_server.public_ip}"
}