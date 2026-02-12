BeforeAll {
	$TestPath = Split-Path -Parent -Path $PSScriptRoot

	$FunctionFileName = (Split-Path -Leaf $PSCommandPath ) -replace '\.Tests\.', '.'

	# You can use this Variable to call your function via it's name or ignore/remove as required
	$FunctionName = $FunctionFileName.Replace('.ps1', '')
	
	. $(Join-Path -Path $TestPath -ChildPath $FunctionFileName)
}
Describe -Name "Performing basic validation test on function $FunctionFileName" {
	It "Should convert PSCustomObject to hashtable" {
		$obj = [PSCustomObject]@{ Name = "Test"; Value = 42 }
		$result = ConvertTo-HashTable -InputObject $obj
		$result | Should -BeOfType [hashtable]
		$result.Keys | Should -Contain 'Name'
		$result.Keys | Should -Contain 'Value'
		$result['Name'] | Should -Be 'Test'
		$result['Value'] | Should -Be 42
	}

	It "Should handle nested objects with -Recurse" {
		$obj = [PSCustomObject]@{
			Name  = "Parent"
			Child = [PSCustomObject]@{ ChildName = "Nested" }
		}
		$result = ConvertTo-HashTable -InputObject $obj -Recurse
		$result | Should -BeOfType [hashtable]
		$result['Child'] | Should -BeOfType [hashtable]
		$result['Child']['ChildName'] | Should -Be 'Nested'
	}

	It "Should exclude empty values with -ExcludeEmpty" {
		$obj = [PSCustomObject]@{ A = "hello"; B = $null; C = "" }
		$result = ConvertTo-HashTable -InputObject $obj -ExcludeEmpty
		$result.Keys | Should -Contain 'A'
		$result.Keys | Should -Not -Contain 'B'
		$result.Keys | Should -Not -Contain 'C'
	}

	It "Should support pipeline input" {
		$obj = [PSCustomObject]@{ Foo = "Bar" }
		$result = $obj | ConvertTo-HashTable
		$result | Should -BeOfType [hashtable]
		$result['Foo'] | Should -Be 'Bar'
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
