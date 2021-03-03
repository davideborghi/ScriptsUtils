node {
	try {
		def branch="Dev"	// nome del branch, Dev
		def tagName="0.0" 					// versione di default
		
		stage('Preparation') { // for display purposes
			
			final scmVars = checkout(scm)
			echo "scmVars: ${scmVars}"
			echo "scmVars.GIT_COMMIT: ${scmVars.GIT_COMMIT}"
			echo "scmVars.GIT_PREVIOUS_SUCCESSFUL_COMMIT: ${scmVars.GIT_PREVIOUS_SUCCESSFUL_COMMIT}"
			echo "scmVars.GIT_BRANCH: ${scmVars.GIT_BRANCH}"
			
		  // Get some code from a GitHub repository
		  git branch: branch, credentialsId: 'Jenkins_Gitlab', url: 'http://fsg-tor1-92.altran.it/sw-hub/isp/timesheet.git'
		  tagName = powershell(returnStdout: true, script: '''
			$tag = git tag --sort=version:refname
			$tag[-1]
			''').trim()
		  echo tagName
		  echo env.BUILD_TAG
		  
	  }
		stage('Build_&_Code_Analisys') {
			
			
            def sqScannerMsBuildHome = tool 'SonarQube-Scanner'
			def sonarExclusions="timesheet.APP/app/lib/**,timesheet.APP/app/assets/**,timesheet.APP/app/Pages/shared/lyncService.js,timesheet.APP/app/Pages/shared/directives.js"
			bat """
            cd  timesheet.API
			git checkout dev
            dir
			${sqScannerMsBuildHome}\\SonarQube.Scanner.MSBuild.exe begin /k:timesheet /d:sonar.exclusions=${sonarExclusions}
            \"${tool 'MSBuild'}\" timesheet.API.sln /p:Configuration=FSG63CI /p:Platform=\"Any CPU\" /p:ProductVersion=${tagName}
			${sqScannerMsBuildHome}\\SonarQube.Scanner.MSBuild.exe end
            """
			
		}
		stage('Testing'){
			
			bat """			
			cd timesheet.API/timesheet.API.Tests/bin/FSG63CI/
			\"${tool 'MSTest'}\" timesheet.API.Tests.dll
			"""
			
		}
		stage('DeployngWeb') {
			
			bat """
			cd timesheet.APP
			npm install"""
			bat """
			cd timesheet.APP
			npm run gulp build-app""" 
			//ricordati di modificare il csproj inserendo la cartella site cosi
			//<ItemGroup>
				//<Folder Include="Site\**" />
  			//</ItemGroup>
  			// per includere tutti i file copiati
			bat "\"${tool 'MSBuild'}\" ./timesheet.API/timesheet.API/timesheet.API.csproj /p:Configuration=FSG63CI /p:PublishProfile=FSG63CI.pubxml  /p:DeployOnBuild=true"
			
		}
		stage('DeployDB'){			
			final scmVars = checkout(scm)
			echo "scmVars: ${scmVars}"
			echo "scmVars.GIT_COMMIT: ${scmVars.GIT_COMMIT}"
			echo "scmVars.GIT_PREVIOUS_SUCCESSFUL_COMMIT: ${scmVars.GIT_PREVIOUS_SUCCESSFUL_COMMIT}"
			echo "scmVars.GIT_BRANCH: ${scmVars.GIT_BRANCH}"
			def dbServer="FSG-TOR1-76\\DB_FACTORY_12" 
			powershell (returnStdout: true, script: """./JenkinsCIDB.ps1 -startCommitID ${scmVars.GIT_PREVIOUS_SUCCESSFUL_COMMIT}""")
			def fileName = "DiffScript.sql"
			bat "IF EXIST DiffScript.sql sqlcmd -d STDB0_BDT -U stdb0_app -P stdb0_app -S FSG-TOR1-76\\DB_FACTORY_12 -i ./DiffScript.sql"
			echo "sposta file  DiffScript.sql in \"${JENKINS_HOME}/jobs/${JOB_NAME}/builds/${BUILD_NUMBER}/archive/${fileName}\""
            def destFolder = "$JENKINS_HOME/jobs/$JOB_NAME/builds/$BUILD_NUMBER/archive"
            bat "md \"${destFolder}\" 2> nul"
			
            bat "IF EXIST DiffScript.sql move DiffScript.sql \"${destFolder}/${fileName}\""
		}
		notify("SUCCESSFUL")
	} catch(e) {
		notify("ERROR")
		throw e
	}
}

def notify(String buildStatus) {
    def mailRecipients = "davide.borghi@altran.it,antonella.touscoz@altran.it,giuseppe.zara@altran.it"
    emailext body:'''<a href="http://fsg-tor1-63:88/TimesheetFBA/Site/">Link applicazione Timesheet</a> ${SCRIPT, template="groovy_html.template"}''', 
             subject: "${buildStatus}: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]'",
             to: "${mailRecipients}"
}
