

**📗 HackerSenpai (Student App)**
---------------------------------

> The official student companion app to access assigned courses and videos, securely and track progress.

### **🔧 Features**

*   🔐 Firebase login (mail & password created by admin)
    
*   *   First login stores a unique device ID
        
    *   Prevents future logins from unauthorized devices
        
*   *   Name and Student ID
        
    *   List of assigned subjects/courses
        
*   *   Lists chapters inside each course
        
    *   Lists videos inside each chapter
        
*   *   Plays **Google Drive** videos using a secure embedded player
        
    *   Displays **dynamic watermark** overlay
        
    *   Prevents screen recording and screenshots
        
*   *   Playlist-style layout
        
    *   Navigation across chapters & videos
        
    *   Mark video as “Completed” to track progress
        

### **🔐 Login Behavior**

*   On first login, unique\_device\_id is stored in /users/{user\_id}
    
*   On future logins, login is allowed **only** from the same device
    
*   Unauthorized logins show a blocking error
    

### **🔒 Privacy Features**

*   Rooted device? App blocks usage
    
*   Screen recording? App shows black screen
    
*   Screenshots? Disabled via flutter\_windowmanager
    

### **🧠 Technologies Used**

*   flutter
    
*   firebase\_core
    
*   firebase\_auth
    
*   cloud\_firestore
    
*   device\_info\_plus
    
*   flutter\_windowmanager
    
*   provider (for state management)
    

**📱 Installation**
-------------------

1.  Clone both repos
    
2.  Run flutter pub get
    
3.  Configure Firebase projects
    
4.  Run on a real device (root check & security features won’t work on emulators)
    

**🛡️ Security Notes**
----------------------

*   Student access is locked per device
    
*   App exits if rooted
    
*   Screen content is protected
    
*   YouTube videos are not recommended for watermark control (use GDrive or Firebase Storage)
    

**📦 Future Enhancements (Optional)**
-------------------------------------

*   Notifications for new video releases
    
*   Real-time progress tracking
    
*   Quiz integration
    
*   Offline video caching (for Firebase Storage)
    
*   Admin analytics dashboard
    

**🧑‍💻 Developed By**
----------------------

**Rahul Babu M P**

Cybersecurity enthusiast | Flutter Developer

[Portfolio](https://rahulbabump.online) | [GitHub](https://github.com/rahulthewhitehat) | [LinkedIn](https://linkedin.com/in/rahulthewhitehat)

