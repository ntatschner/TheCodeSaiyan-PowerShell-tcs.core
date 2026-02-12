BeforeAll {
	$TestPath = Split-Path -Parent -Path $PSScriptRoot

	$FunctionFileName = (Split-Path -Leaf $PSCommandPath ) -replace '\.Tests\.', '.'

	# You can use this Variable to call your function via it's name or ignore/remove as required
	$FunctionName = $FunctionFileName.Replace('.ps1', '')
	
	. $(Join-Path -Path $TestPath -ChildPath $FunctionFileName)
}
Describe -Name "Performing basic validation test on function $FunctionFileName" {
	It "Should return result on success" {
		$result = Invoke-WithRetry -ScriptBlock { "hello" }
		$result | Should -Be "hello"
	}

	It "Should retry on failure" {
		$script:counter = 0
		$result = Invoke-WithRetry -ScriptBlock {
			$script:counter++
			if ($script:counter -lt 3) {
				throw "Transient failure"
			}
			"success"
		} -MaxRetries 5 -DelaySeconds 0
		$result | Should -Be "success"
		$script:counter | Should -Be 3
	}

	It "Should throw after max retries exhausted" {
		{
			Invoke-WithRetry -ScriptBlock {
				throw "Permanent failure"
			} -MaxRetries 2 -DelaySeconds 0
		} | Should -Throw
	}

	It "Should apply delay between retries with BackoffMultiplier without error" {
		$script:counter = 0
		{
			Invoke-WithRetry -ScriptBlock {
				$script:counter++
				if ($script:counter -lt 2) {
					throw "Transient"
				}
				"done"
			} -MaxRetries 3 -DelaySeconds 0 -BackoffMultiplier 2
		} | Should -Not -Throw
	}
}

Describe -Tags 'PSSA' -Name 'Testing against PSScriptAnalyzer rules' {
	BeforeAll {
		$ScriptAnalyzerSettings = Get-Content -Path (Join-Path -Path (Get-Location) -ChildPath 'PSScriptAnalyzerSettings.psd1') | Out-String | Invoke-Expression
		$AnalyzerIssues = Invoke-ScriptAnalyzer -Path "$TestPath\$FunctionFileName" -Settings $ScriptAnalyzerSettings
		$ScriptAnalyzerRuleNames = Get-ScriptAnalyzerRule | Select-Object -ExpandProperty RuleName
	}

	foreach ($Rule in $ScriptAnalyzerRuleNames) {
		if ($ScriptAnalyzerSettings.excluderules -notcontains $Rule) {
			It "Function $FunctionFileName should pass $Rule" {
				$Failures = $AnalyzerIssues | Where-Object -Property RuleName -EQ -Value $rule
				($Failures | Measure-Object).Count | Should -Be 0
			}
		}
		else {
			# We still want it in the tests, but since it doesn't actually get tested we will skip
			It "Function $FunctionFileName should pass $Rule" -Skip {
				$Failures = $AnalyzerIssues | Where-Object -Property RuleName -EQ -Value $rule
				($Failures | Measure-Object).Count | Should -Be 0
			}
		}
	}
}
