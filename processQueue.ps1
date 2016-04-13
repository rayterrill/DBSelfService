$dbServer='DBSERVERNAME'
$dbDatabase='DBManagement'
$domainPrefix = "DOMAINPREFIX\\"
$fromEmail = "MYDBATEAM@MYCOMPANY.COM"
$smtpServer = "MYSMTPSERVER.MYCOMPANY.COM"

function getEmailAddress ($username) {
	$username = $username -ireplace $domainPrefix, ""
	$emailAddress = Get-ADUser $username -Properties mail | Select-Object -ExpandProperty mail
	return $emailAddress
}

function dequeueData {
   $connectionString = "Server=$dbServer;Database=$dbDatabase;Integrated Security=True;"
   $connection = New-Object System.Data.SqlClient.SqlConnection
   $connection.ConnectionString = $connectionString
   $connection.Open()
   
   $command = $connection.CreateCommand()
   $command.CommandText = "dequeueFifo"
   $command.CommandType = [System.Data.CommandType]'StoredProcedure'
   $outParameter1 = new-object System.Data.SqlClient.SqlParameter
   $outParameter1.ParameterName = "@operation";
   $outParameter1.Direction = [System.Data.ParameterDirection]'Output'
   $outParameter1.Size = 10
   $outParameter2 = new-object System.Data.SqlClient.SqlParameter
   $outParameter2.ParameterName = "@databaseName";
   $outParameter2.Direction = [System.Data.ParameterDirection]'Output'
   $outParameter2.Size = 10
   $outParameter3 = new-object System.Data.SqlClient.SqlParameter
   $outParameter3.ParameterName = "@username";
   $outParameter3.Direction = [System.Data.ParameterDirection]'Output'
   $outParameter3.Size = 50
   $command.Parameters.Add($outParameter1) | Out-Null
   $command.Parameters.Add($outParameter2) | Out-Null
   $command.Parameters.Add($outParameter3) | Out-Null
   
   $result = $command.ExecuteNonQuery()
   $operation = $command.Parameters["@operation"].Value
   $databaseName = $command.Parameters["@databaseName"].Value
   $username = $command.Parameters["@username"].Value
   $connection.Close()
   
   return $operation,$databaseName,$username
}

function sendUserEmail($error, $databaseName, $operation, $emailAddress) {
   if ($error -eq 0) {
      $subject = "DBSelfService - SUCCESS [$($operation)] on [$($databaseName)]"
      $message = "Operation to perform $($operation) on database $($databaseName) was successful!"
      
      if ($operation -eq 'CREATE') {
         $message = $message + "<br /><br />You new database is live on $($dbServer).<br /><br />By default, your AD account has dbo permissions to this new database."
      }
   } else {
      $subject = "DBSelfService - FAILED [$($operation)] on [$($databaseName)]"
      $message = "Operation to perform $($operation) on database $($databaseName) was NOT successful!"
   }
   
   Send-MailMessage -from $fromEmail -to $emailAddress -subject $subject -body $message -smtpServer $smtpServer -BodyAsHtml
}

function grantUserDboPermission($databaseName, $username) {
   $sql = "select * from sys.syslogins where name = '$($username)'"
   $login = Invoke-SQLCMD -Query $sql -ServerInstance $dbServer
   
   if (!$login) {
      Write-Debug "Login does not exist. Creating..."
      $sql = "CREATE LOGIN [$($username)] FROM WINDOWS;"
      
      Push-Location
      Invoke-SQLCMD -Query $sql -ServerInstance $dbServer
      Pop-Location
   }
   
   $sql = "CREATE USER [$($username)] FOR LOGIN [$($username)]"
   Invoke-SQLCMD -Query $sql -ServerInstance $dbServer -Database $databaseName
   $sql = "ALTER ROLE db_owner ADD MEMBER [$($username)];"
   Invoke-SQLCMD -Query $sql -ServerInstance $dbServer -Database $databaseName
}

function performDatabaseOperation($databaseName,$operation,$username) {
   if ($operation -eq 'CREATE') {
      $sql = "CREATE DATABASE $($databaseName)"
   } elseif ($operation -eq 'DELETE') {
      $sql = "ALTER DATABASE $($databaseName) SET SINGLE_USER WITH ROLLBACK IMMEDIATE; DROP DATABASE $($databaseName);"
   }
   
   Push-Location
   $error = 0
   try {
      Invoke-SQLCMD -Query $sql -ServerInstance $dbServer
      if ($operation -eq 'CREATE') {
         grantUserDboPermission -DatabaseName $databaseName -Username $username
      }
   } catch {
      $error = 1
   }
   Pop-Location
   
   $emailAddress = getEmailAddress -Username $username
   if ($emailAddress -ne '') {
      sendUserEmail -Error $error -DatabaseName $databaseName -Operation $operation -EmailAddress $emailAddress
   }
}

$operation,$databaseName,$username = dequeueData
if ($operation.GetType().Name -ne 'DBNull') {
   performDatabaseOperation -DatabaseName $databaseName -Operation $operation -Username $username
} else {
   Write-Host "Nothing to do."
}
