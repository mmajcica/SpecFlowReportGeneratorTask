[CmdletBinding()]
param()

Trace-VstsEnteringInvocation $MyInvocation

try
{
    # Set the working directory.
    $reportType = Get-VstsInput -Name reportType -Require
    $projectFile = Get-VstsInput -Name projectFile -Require
    $xmlTestResult = Get-VstsInput -Name xmlTestResult
    $testOutput = Get-VstsInput -Name testOutput
    $testResult = Get-VstsInput -Name testResult
    $binFolder = Get-VstsInput -Name binFolder
    $xsltFile = Get-VstsInput -Name xsltFile
    $out = Get-VstsInput -Name out

    Assert-VstsPath -LiteralPath $projectFile -PathType Leaf

    $specflow = "$PSScriptRoot\ps_modules\2.3.1\specflow.exe"

    if (-not $out)
    {
        if ($env:Agent_JobName -eq "Build")
        {
            $out = Join-Path $env:AGENT_BUILDDIRECTORY "TestResult.html"
        }
        else
        {
            $out = Join-Path $env:AGENT_RELEASEDIRECTORY "TestResult.html"
        }
    }
    else
    {
        if (-not (Test-Path $out -PathType Leaf -IsValid))
        {
            throw "File specified for Output File is not a valid file name."
        }

        if (-not (Test-Path $out -PathType Container))
        {
            New-Item -ItemType Directory -Force -Path (Split-Path $out) | Out-Null
        }
    }

    $sArgs = ,$reportType
    $sArgs += """$projectFile"""

    switch ($reportType)
    {
        "mstestexecutionreport"
            {
                if ($testResult)
                {
                    $trxs = Find-VstsFiles -LegacyPattern $testResult

                    if (-not $trxs)
                    {
                        throw "No trx files was found using search pattern '$testResult'."
                    }

                    if ($trxs.Count > 1)
                    {
                        Write-Warning "More than one trx file found. Only the first in list will be used."
                    }

                    # Find-Files returns an array in case of multiple objects, a single item in case single item is found.
                    if ($trxs -is [System.Array])
                    {
                        $trx = $trxs[0]
                    }
                    else
                    {
                        $trx = $trxs
                    }

                    $sArgs += "/testResult:""$trx"""
                }
            }
        "nunitexecutionreport"
            {
                if ($xmlTestResult)
                {
                    $sArgs += "/xmlTestResult:""$xmlTestResult"""
                }

                if ($testOutput)
                {
                    $sArgs += "/testOutput:""$testOutput"""
                }
            }
        "stepdefinitionreport"
            {
                if ($binFolder)
                {
                    $sArgs += "/binFolder:""$binFolder"""
                }
            }
    }

    if ($xsltFile)
    {
        $sArgs += "/xsltFile:""$xsltFile"""
    }

    $sArgs += "/out:""$out"""

    $sArgs = $sArgs -join " "

    Invoke-VstsTool -FileName $specflow -Arguments $sArgs -RequireExitCodeZero
}
finally
{
    Trace-VstsLeavingInvocation $MyInvocation
}
