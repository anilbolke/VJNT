<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>VJNT वर्ग व्यवस्थापन प्रणाली - मुख्यपृष्ठ</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800&display=swap" rel="stylesheet">
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            line-height: 1.6;
            color: #333;
            overflow-x: hidden;
        }

        /* Header Section */
        .header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 2rem 0;
            box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
        }

        .header-content {
            max-width: 1200px;
            margin: 0 auto;
            padding: 0 20px;
            display: flex;
            align-items: center;
            justify-content: space-between;
            flex-wrap: wrap;
        }

        .logo-section {
            display: flex;
            align-items: center;
            gap: 20px;
            flex: 1;
        }

        .logo-section img {
            max-height: 80px;
            width: auto;
            background: white;
            padding: 10px;
            border-radius: 10px;
            box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
        }

        .header-text h1 {
            font-size: 2.2rem;
            font-weight: 800;
            margin-bottom: 0.5rem;
            text-shadow: 2px 2px 4px rgba(0, 0, 0, 0.2);
        }

        .header-text p {
            font-size: 1.1rem;
            font-weight: 300;
            opacity: 0.95;
        }

        .login-btn {
            background: white;
            color: #667eea;
            padding: 12px 30px;
            border-radius: 25px;
            text-decoration: none;
            font-weight: 600;
            transition: all 0.3s ease;
            box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
        }

        .login-btn:hover {
            transform: translateY(-2px);
            box-shadow: 0 6px 12px rgba(0, 0, 0, 0.2);
        }

        /* Hero Section */
        .hero {
            background: linear-gradient(135deg, #f5f7fa 0%, #c3cfe2 100%);
            padding: 4rem 20px;
            text-align: center;
        }

        .hero h2 {
            font-size: 2.5rem;
            color: #2d3748;
            margin-bottom: 1rem;
            font-weight: 700;
        }

        .hero p {
            font-size: 1.2rem;
            color: #4a5568;
            max-width: 800px;
            margin: 0 auto;
        }

        /* Container */
        .container {
            max-width: 1200px;
            margin: 0 auto;
            padding: 0 20px;
        }

        /* Section Styling */
        .section {
            padding: 4rem 20px;
        }

        .section-title {
            font-size: 2rem;
            font-weight: 700;
            color: #2d3748;
            margin-bottom: 2rem;
            text-align: center;
            position: relative;
            padding-bottom: 1rem;
        }

        .section-title::after {
            content: '';
            position: absolute;
            bottom: 0;
            left: 50%;
            transform: translateX(-50%);
            width: 80px;
            height: 4px;
            background: linear-gradient(90deg, #667eea, #764ba2);
            border-radius: 2px;
        }

        /* Features Grid */
        .features-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
            gap: 2rem;
            margin-top: 3rem;
        }

        .feature-card {
            background: white;
            padding: 2rem;
            border-radius: 12px;
            box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
            transition: all 0.3s ease;
            border-top: 4px solid #667eea;
        }

        .feature-card:hover {
            transform: translateY(-5px);
            box-shadow: 0 8px 15px rgba(0, 0, 0, 0.15);
        }

        .feature-icon {
            font-size: 3rem;
            margin-bottom: 1rem;
        }

        .feature-card h3 {
            font-size: 1.3rem;
            color: #2d3748;
            margin-bottom: 1rem;
            font-weight: 600;
        }

        .feature-card p {
            color: #4a5568;
            line-height: 1.6;
        }

        /* Module Section */
        .modules-list {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(350px, 1fr));
            gap: 1.5rem;
            margin-top: 2rem;
        }

        .module-item {
            background: white;
            padding: 1.5rem;
            border-radius: 10px;
            box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
            border-left: 4px solid #764ba2;
            transition: all 0.3s ease;
        }

        .module-item:hover {
            box-shadow: 0 4px 8px rgba(0, 0, 0, 0.15);
            transform: translateX(5px);
        }

        .module-item h4 {
            color: #667eea;
            font-size: 1.2rem;
            margin-bottom: 0.5rem;
            font-weight: 600;
        }

        .module-item ul {
            list-style: none;
            padding-left: 0;
        }

        .module-item li {
            padding: 0.3rem 0;
            color: #4a5568;
            position: relative;
            padding-left: 20px;
        }

        .module-item li::before {
            content: '✓';
            position: absolute;
            left: 0;
            color: #667eea;
            font-weight: bold;
        }

        /* Team Section */
        .team-section {
            background: linear-gradient(135deg, #f5f7fa 0%, #c3cfe2 100%);
        }

        .team-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 2rem;
            margin-top: 3rem;
        }

        .team-member {
            background: white;
            border-radius: 12px;
            overflow: hidden;
            box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
            transition: all 0.3s ease;
            text-align: center;
        }

        .team-member:hover {
            transform: translateY(-10px);
            box-shadow: 0 8px 20px rgba(0, 0, 0, 0.15);
        }

        .team-member-img {
            width: 100%;
            height: 300px;
            object-fit: cover;
            border-bottom: 4px solid #667eea;
        }

        .team-member-info {
            padding: 1.5rem;
        }

        .team-member-info h3 {
            font-size: 1.3rem;
            color: #2d3748;
            margin-bottom: 0.5rem;
            font-weight: 600;
        }

        .team-member-info p {
            color: #667eea;
            font-weight: 500;
            font-size: 0.95rem;
        }

        /* Stats Section */
        .stats-section {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
        }

        .stats-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 2rem;
            margin-top: 2rem;
        }

        .stat-card {
            text-align: center;
            padding: 2rem;
            background: rgba(255, 255, 255, 0.1);
            border-radius: 12px;
            backdrop-filter: blur(10px);
        }

        .stat-number {
            font-size: 3rem;
            font-weight: 800;
            margin-bottom: 0.5rem;
        }

        .stat-label {
            font-size: 1.1rem;
            font-weight: 300;
            opacity: 0.9;
        }

        /* Technology Stack */
        .tech-stack {
            display: flex;
            flex-wrap: wrap;
            gap: 1rem;
            justify-content: center;
            margin-top: 2rem;
        }

        .tech-badge {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 0.75rem 1.5rem;
            border-radius: 25px;
            font-weight: 500;
            box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
        }

        /* Footer */
        .footer {
            background: #2d3748;
            color: white;
            padding: 2rem 20px;
            text-align: center;
        }

        .footer p {
            opacity: 0.8;
        }

        /* Responsive */
        @media (max-width: 768px) {
            .header-text h1 {
                font-size: 1.5rem;
            }

            .hero h2 {
                font-size: 1.8rem;
            }

            .logo-section {
                justify-content: center;
                margin-bottom: 1rem;
            }

            .login-btn {
                margin-top: 1rem;
            }
        }
    </style>
</head>
<body>
    <!-- Header -->
    <header class="header">
        <div class="header-content">
            <div class="logo-section">
               <img src="<%= request.getContextPath() %>/Document/GATEE LOGO.png?v=2" alt="GATEE Logo"> 
                <div class="header-text">
                    <h1>GATEE PORTAL</h1>
                    <p>गुणवत्तापूर्ण शिक्षणाची नवीन दिशा</p>
                </div>
            </div>
            <a href="login.jsp" class="login-btn">लॉगिन पोर्टल</a>
        </div>
    </header>

    <!-- Team Section -->
    <section class="section team-section">
        <div class="container">
            <!-- <h2 class="section-title">नेतृत्व आणि पाठिंबा</h2>
            <p style="text-align: center; max-width: 800px; margin: 0 auto 2rem; color: #4a5568; font-size: 1.1rem;">
                या उपक्रमाला महाराष्ट्र शासनाच्या प्रतिष्ठित नेतृत्वाचा पाठिंबा आहे
            </p> -->
            <div class="team-grid">
                <div class="team-member">
                    <img src="Document/cm_devendra_fadnavis.jpg" alt="Devendra Fadnavis" class="team-member-img">
                    <div class="team-member-info">
                        <h3>मा. देवेंद्र फडणवीस</h3>
                        <p>महाराष्ट्राचे मुख्यमंत्री</p>
                    </div>
                </div>
                <div class="team-member">
                    <img src="Document/dcm_eknath_shinde.jpg" alt="Eknath Shinde" class="team-member-img">
                    <div class="team-member-info">
                        <h3>मा. एकनाथ शिंदे</h3>
                        <p>उपमुख्यमंत्री</p>
                    </div>
                </div>
                <div class="team-member">
                    <img src="Document/dcm_ajit_pawar.jpg" alt="Ajit Pawar" class="team-member-img">
                    <div class="team-member-info">
                        <h3>मा. अजित पवार</h3>
                        <p>उपमुख्यमंत्री</p>
                    </div>
                </div>
                <div class="team-member">
                    <img src="Document/minister_atul_save.jpg" alt="Atul Save" class="team-member-img">
                    <div class="team-member-info">
                        <h3>मा. अतुल सावे</h3>
                        <p>मंत्री</p>
                    </div>
                </div>
            </div>
        </div>
    </section>

    <!-- Hero Section -->
    <section class="hero">
        <div class="container">
            <h2>तंत्रज्ञानाद्वारे शिक्षणाला सशक्त करणे</h2>
            <p>महाराष्ट्रातील शाळा, जिल्हे आणि विभागांमध्ये विद्यार्थी डेटा व्यवस्थापन, शैक्षणिक प्रगती ट्रॅकिंग आणि संप्रेषण सुलभ करण्यासाठी एक सर्वसमावेशक डिजिटल प्लॅटफॉर्म.</p>
        </div>
    </section>

    <!-- About Section -->
    <section class="section">
        <div class="container">
            <h2 class="section-title">प्रकल्पाबद्दल</h2>
            <div class="features-grid">
                <div class="feature-card">
                    <div class="feature-icon">🎯</div>
                    <h3>ध्येय</h3>
                    <p>नाविन्यपूर्ण डिजिटल उपायांद्वारे VJNT विद्यार्थ्यांसाठी शैक्षणिक प्रशासन सुव्यवस्थित करणे आणि शिकण्याचे परिणाम सुधारणे.</p>
                </div>
                <div class="feature-card">
                    <div class="feature-icon">👁️</div>
                    <h3>दृष्टी</h3>
                    <p>चांगल्या शैक्षणिक प्रशासनासाठी विद्यार्थी, शिक्षक, शाळा आणि प्रशासकांना जोडणारी एकात्मिक प्रणाली तयार करणे.</p>
                </div>
                <div class="feature-card">
                    <div class="feature-icon">⚡</div>
                    <h3>प्रभाव</h3>
                    <p>संपूर्ण शैक्षणिक नेटवर्कवर रिअल-टाइम निरीक्षण, डेटा-आधारित निर्णय आणि कार्यक्षम संसाधन वाटप.</p>
                </div>
            </div>
        </div>
    </section>

    <!-- Features Section -->
    <section class="section" style="background: #f8f9fa;">
        <div class="container">
            <h2 class="section-title">मुख्य वैशिष्ट्ये</h2>
            <div class="modules-list">
                <div class="module-item">
                    <h4>📊 बहु-स्तरीय डॅशबोर्ड प्रणाली</h4>
                    <ul>
                        <li>शाळा समन्वयक डॅशबोर्ड</li>
                        <li>जिल्हा समन्वयक डॅशबोर्ड</li>
                        <li>विभाग प्रमुख डॅशबोर्ड</li>
                        <li>डेटा प्रशासक डॅशबोर्ड</li>
                        <li>रिअल-टाइम विश्लेषण आणि अहवाल</li>
                    </ul>
                </div>
                <div class="module-item">
                    <h4>👨‍🎓 विद्यार्थी व्यवस्थापन</h4>
                    <ul>
                        <li>सर्वसमावेशक विद्यार्थी प्रोफाइल</li>
                        <li>टप्प्याटप्प्याने प्रगती ट्रॅकिंग</li>
                        <li>FLN (मूलभूत साक्षरता आणि संख्या ज्ञान)</li>
                        <li>क्रियाकलाप आणि मूल्यांकन निरीक्षण</li>
                        <li>विद्यार्थी स्तर वितरण विश्लेषण</li>
                    </ul>
                </div>
                <div class="module-item">
                    <h4>👨‍🏫 शिक्षक व्यवस्थापन</h4>
                    <ul>
                        <li>शिक्षक नियुक्ती प्रणाली</li>
                        <li>शिक्षक तपशील आणि प्रमाणपत्रे</li>
                        <li>जिल्हा-स्तरीय शिक्षक अहवाल</li>
                        <li>कामगिरी ट्रॅकिंग</li>
                        <li>क्रियाकलाप मंजुरी</li>
                    </ul>
                </div>
                <div class="module-item">
                    <h4>🏫 शाळा प्रशासन</h4>
                    <ul>
                        <li>शाळा संपर्क व्यवस्थापन</li>
                        <li>बहु-वापरकर्ता खाते प्रणाली</li>
                        <li>टप्पा मंजुरी कार्यप्रवाह</li>
                        <li>मुख्याध्यापक मंजुरी प्रणाली</li>
                        <li>शाळा-स्तरीय क्रियाकलाप विश्लेषण</li>
                    </ul>
                </div>
                <div class="module-item">
                    <h4>📱 पालक मेळावा एकत्रीकरण</h4>
                    <ul>
                        <li>पालक बैठक व्यवस्थापन</li>
                        <li>फोटो गॅलरी आणि प्रदर्शन</li>
                        <li>मंजुरी कार्यप्रवाह</li>
                        <li>स्थिती ट्रॅकिंग</li>
                        <li>बहु-स्तरीय समन्वय</li>
                    </ul>
                </div>
                
                <div class="module-item">
                    <h4>📈 प्रगत विश्लेषण</h4>
                    <ul>
                        <li>विभाग टप्पा तुलना</li>
                        <li>टप्प्यानिहाय विषय आकडेवारी</li>
                        <li>विद्यार्थी स्तर तपशील आणि वितरण</li>
                        <li>क्रियाकलाप विश्लेषण अहवाल</li>
                        <li>सर्वसमावेशक अहवाल निर्मिती</li>
                    </ul>
                </div>
                <div class="module-item">
                    <h4>🔐 सुरक्षा आणि प्रवेश नियंत्रण</h4>
                    <ul>
                        <li>भूमिका-आधारित प्रवेश नियंत्रण (RBAC)</li>
                        <li>सुरक्षित प्रमाणीकरण</li>
                        <li>पासवर्ड व्यवस्थापन</li>
                        <li>खाते अनलॉक प्रणाली</li>
                        <li>जिल्हा प्रमाणपत्र व्यवस्थापन</li>
                    </ul>
                </div>
                <div class="module-item">
                    <h4>🔔 सूचना प्रणाली</h4>
                    <ul>
                        <li>लक्ष्यित सूचना</li>
                        <li>प्राधान्य-आधारित इशारे</li>
                        <li>बहु-स्तरीय प्रसारण</li>
                        <li>कालबाह्यता व्यवस्थापन</li>
                        <li>रिअल-टाइम अपडेट्स</li>
                    </ul>
                </div>
                <div class="module-item">
                    <h4>📄 अहवाल व्यवस्थापन</h4>
                    <ul>
                        <li>अहवाल विनंती प्रणाली</li>
                        <li>मंजुरी कार्यप्रवाह</li>
                        <li>PDF निर्मिती</li>
                        <li>सर्वसमावेशक विद्यार्थी अहवाल</li>
                        <li>निर्यात आणि डाउनलोड पर्याय</li>
                    </ul>
                </div>
                <div class="module-item">
                    <h4>🌐 बहु-भाषा समर्थन</h4>
                    <ul>
                        <li>इंग्रजी इंटरफेस</li>
                        <li>मराठी इंटरफेस</li>
                        <li>भाषा-विशिष्ट सामग्री</li>
                        <li>प्रादेशिक अनुकूलन</li>
                        <li>द्विभाषिक दस्तऐवजीकरण</li>
                    </ul>
                </div>
                <div class="module-item">
                    <h4>⚙️ प्रशासकीय साधने</h4>
                    <ul>
                        <li>वापरकर्ता व्यवस्थापन प्रणाली</li>
                        <li>शाळा अपलोड कार्यक्षमता</li>
                        <li>प्रोफाइल व्यवस्थापन</li>
                        <li>प्रमाणपत्रे सेटअप</li>
                        <li>प्रणाली संरचना</li>
                    </ul>
                </div>
            </div>
        </div>
    </section>

    

   

    <!-- Call to Action -->
    <section class="section" style="text-align: center; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white;">
        <div class="container">
            <h2 style="color: white; margin-bottom: 1.5rem;">सुरुवात करण्यास तयार आहात?</h2>
            <p style="font-size: 1.2rem; margin-bottom: 2rem; opacity: 0.95;">शैक्षणिक डेटा व्यवस्थापित करण्यासाठी आणि विद्यार्थी प्रगती ट्रॅक करण्यासाठी पोर्टलवर प्रवेश करा.</p>
            <a href="login.jsp" class="login-btn" style="display: inline-block;">पोर्टल प्रवेश</a>
        </div>
    </section>

    <!-- Footer -->
    <footer class="footer">
        <div class="container">
            <p>&copy; <%= java.time.Year.now().getValue() %> VJNT वर्ग व्यवस्थापन प्रणाली. सर्व हक्क राखीव.</p>
            <p>GATEE पोर्टल द्वारे समर्थित | महाराष्ट्र शासन उपक्रम</p>
        </div>
    </footer>
</body>
</html>
