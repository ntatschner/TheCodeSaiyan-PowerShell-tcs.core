BeforeAll {
	$TestPath = Split-Path -Parent -Path $PSScriptRoot

	$FunctionFileName = (Split-Path -Leaf $PSCommandPath ) -replace '\.Tests\.', '.'

	# You can use this Variable to call your function via it's name or ignore/remove as required
	$FunctionName = $FunctionFileName.Replace('.ps1', '')
	
	. $(Join-Path -Path $TestPath -ChildPath $FunctionFileName)
	. $(Join-Path -Path $TestPath -ChildPath 'Protect-ConfigValue.ps1')
}
Describe -Name "Performing basic validation test on function $FunctionFileName" {
	It "Should decrypt to original value" {
		$original = "RoundTripTestValue"
		$encrypted = Protect-ConfigValue -Value $original
		$decrypted = Unprotect-ConfigValue -EncryptedValue $encrypted
		$decrypted | Should -Be $original
	}

	It "Should return a string" {
		$encrypted = Protect-ConfigValue -Value "TypeCheckValue"
		$result = Unprotect-ConfigValue -EncryptedValue $encrypted
		$result | Should -BeOfType [string]
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
