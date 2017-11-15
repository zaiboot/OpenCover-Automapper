cls
# Generate code coverage report using OpenCore and ReportGenerator
# Put this script to Visual Studio solution folder.

# You may need to run this from VS "Package Manager Console" on one of your test projects:
# nuget install OpenCover -OutputDirectory packages
# nuget install ReportGenerator -OutputDirectory packages
# nuget install coveralls.net -OutputDirectory packages     # optional

Function GetFilter($inclusive, $exclusive) {
    $filters = ""
    foreach ($i in $inclusive) {
        $filters +="+[$i]* "
    }

    foreach ($i in $exclusive) {
        $filters +="-[$i]* "
    }
    $filters +="-[*Moq*]*"
    return $filters;
}



# CONFIGURATION
$TestProjectsGlobbing = @(,'*Tests.csproj')

$mstestPath = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2017\Community\Common7\IDE\MSTest.exe"
$dotnetPath = "$env:ProgramFiles\dotnet\dotnet.exe"
$netcoreapp = 'netcoreapp2.0'

$NamespaceInclusiveFilters = @(,'*') # asterix means inlude all namespaces (which pdb found)
$BuildNamespaceExclusiveFilters = $true # For core - test project's default namespace; For classic - namespaces where test project's types defined

$testClassicProjects=$false
$testCoreProjects   =$true
$debugMode          =$false

$toolsFolder = "C:\tools"
$classicProjectOutput = "bin\Debug"
$coreProjectOutput = "bin\Debug\$netcoreapp"

$testsResultsFolder = 'TestsResults'

$excludeGlobbingFromFolders =  @('.git', '.vscode', '.sonarlint', '.vs', 'docs', $toolsFolder, $testsResultsFolder) # optimization: do not search in those Solution subfolders for test projects

#left it empty if you are not using coveralls (publish report online, integrate it with GitHub. more https://coveralls.io/)
$env:COVERALLS_REPO_TOKEN = ""

# STEP 1. Get Solution Folder
$SolutionFolderPath = $PSScriptRoot #or enter it manually there

If ($SolutionFolderPath -eq '') {
    $SolutionFolderPath = 'D:\cot\Vse'
    #throw "Rut it as script from the VS solution's root folder, this will point the location of the solution."
}

# STEP 2. Get OpenCover, ReportGenerator, Coveralls pathes
$openCoverPath       = Get-ChildItem -Path "$toolsFolder" -Filter 'Opencover*'       -Directory | % { "$($_.FullName)\tools\OpenCover.Console.exe" }
$reportGeneratorPath = Get-ChildItem -Path "$toolsFolder" -Filter 'ReportGenerator*' -Directory | % { "$($_.FullName)\tools\ReportGenerator.exe"   }
$coverallsPath       = Get-ChildItem -Path "$toolsFolder" -Filter 'coveralls.net.*'  -Directory | % { "$($_.FullName)\tools\csmacnz.Coveralls.exe" }

# STEP 3. create TestResults folder
$testsResultsFolderPath = "$SolutionFolderPath\$testsResultsFolder"
If (Test-Path "$testsResultsFolderPath") { Remove-Item "$testsResultsFolderPath" -Recurse}
New-Item -ItemType Directory -Force -Path $testsResultsFolderPath | Out-Null

$openCoverOutputFilePath         = "$testsResultsFolderPath\opencoverOutput.xml"
$reportGeneratorOutputFolderPath = "$testsResultsFolderPath\report"


# STEP 5. find projects
$ClassicProjects =  @();
$CoreProjects = @();
Get-ChildItem "$SolutionFolderPath" -Directory -Exclude $excludeGlobbingFromFolders | %{
    Get-ChildItem  $_ -Recurse | %{
       foreach($i in $TestProjectsGlobbing){
          If ($_.FullName -ilike $i){
              $projFolder = $_.Directory.FullName
              $sdk = Select-XML -path $_.FullName -xpath "/*[local-name() = 'Project']/@Sdk"
              $assemblyNameProject = Select-XML -path $_.FullName -xpath "/*[local-name() = 'Project']/*[local-name() = 'PropertyGroup']/*[local-name() = 'AssemblyName']"
              $assemblyName = If (!$assemblyNameProject.Node.InnerText) { $_.BaseName  } Else { $assemblyNameProject.Node.InnerText}
              If ($sdk.Node.Value -eq "Microsoft.NET.Sdk"){
                 $assemblyPath = "$projFolder\$coreProjectOutput\$assemblyName.dll"
                 $CoreProjects += , @($_.FullName, $assemblyPath);
                 # TODO: Check that test csproj contains "/PropertyGroup/DebugType/text()=full" and "/PropertyGroup/DebugSymbols/text()=True"
              }
              Else{
                 $assemblyPath = "$projFolder\$classicProjectOutput\$assemblyName.dll"
                 $ClassicProjects+= , @($_.FullName, $assemblyPath);
              }
          }
       }
    }
}

If ($testCoreProjects){
    #This is required to
    "dotnet build  /p:DebugType=Full"
    dotnet build  /p:DebugType=Full
    Foreach($j in $CoreProjects){
        $testDll = $j[1]
        $projFilePath = $j[0]
        $rootNamespace = Select-XML -path $projFilePath -xpath "/*[local-name() = 'Project']/*[local-name() = 'PropertyGroup']/*[local-name() = 'RootNamespace']"
        $namespaces = @()
        If ($BuildNamespaceExclusiveFilters){
            $namespaces = (, $rootNamespace)
        }
        $filters = GetFilter -in  $NamespaceInclusiveFilters -out $namespaces
        # TODO: parsing the project file we can get TargetFramework
        $targetargs = "test --no-build -f $netcoreapp -c Debug --verbosity normal $projFilePath "

        echo "OpenCover.Console.exe -oldStyle -mergeoutput -excludebyattribute:*.ExcludeFromCoverage* -register:user -mergebyhash -skipautoprops -target:$dotnetPath -targetargs:$targetargs -filter:$filters -output:$openCoverOutputFilePath"

        & $openCoverPath -oldStyle -mergeoutput -register:user -mergebyhash -skipautoprops "-target:$dotnetPath" "-targetargs:$targetargs" "-filter:$filters" "-output:$openCoverOutputFilePath" -excludebyattribute:*.ExcludeFromCodeCoverage*
    }
}

# Execute ReportGenerator

& $reportGeneratorPath "-reports:$openCoverOutputFilePath" "-targetdir:$reportGeneratorOutputFolderPath"

If ( Test-Path env:COVERALLS_REPO_TOKEN) {
    If ($env:COVERALLS_REPO_TOKEN -ne "") {
        & $coverallsPath --opencover -i $openCoverOutputFilePath
    }
}

# STEP 9. Open report in a browser
If (Test-Path "$reportGeneratorOutputFolderPath\index.htm"){
    Invoke-Item "$reportGeneratorOutputFolderPath\index.htm"
}

# TODO: integrate with https://www.appveyor.com/ ??
