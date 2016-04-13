# DBSelfService
This project provides a web-based front end using CakePHP for self-service creation and deletion of SQL Server databases as a DevOps proof-of-concept.

This project is basically broken into three parts:
1. A CakePHP Web front-end, that allows users to request new databases be created and older databases be deleted
2. A PowerShell script that actually implements the requested work
3. A Database and tables that hold information about the databases and operations requested

The database contains a table dbfifoqueue that serves as a "poor-man's queue" - requests are added to the table and picked off in order by a PowerShell script running as a Windows scheduled task. This decouples the operations performing the work, which can take a significant amount of time in some cases, from the web-based GUI. This is very similar to the queue-based load leveling design pattern.

The basic DB creation workflow is as follows:
1. A user navigates to the web page, and clicks the Create a New Database button
2. The user enters the required data (Database Name, and Purpose). For simplicity's sake, the database server is currently hard-coded
3. The user clicks Create Database, which inserts two rows into the database - one for our database table, and one into a queue table used by our PowerShell script
4. A Windows scheduled task kicks off every minute, running a PowerShell script to look for work in the dbfifoqueue table. If work is found, the script executes the work as requested and creates the database
5. The user receives an email notifying them that the database has been created as requested

The DB deletion workflow works almost exactly the same, except the PowerShell script deletes the database.

### Requirements
1. A server running SQL Server
2. A server running IIS with Windows Authentication, URL Rewrite, and PHP 5.6+

### Implementing
1. Download the code, and extract into your web server's webroot
2. Make sure the tmp and logs folders are writable by your IIS process identity
3. Create the database and tables by running the createDatabase.sql script
4. Update the config/app.php script with your database information (lines 219-255) - specifically the host, username, password, and database lines
5. Update the processQueue.ps1 PowerShell script with your database, domain, and email information (lines 1-5)
6. Update the src/Template/Dbs/add.ctp file with your database server name (line 6). This hardcodes the databases to be created on a single server for simplicity's sake
7. Use the "DBA - Process DB Self-Service Queue_CreateJob.xml" script to create the Windows Scheduled Task that will run the PowerShell script every minute. Ensure that the user you configure the Scheduled Task to execute under has the dbcreator and securityadmin roles on your SQL Server, since that user will be performing the user-requested actions.
