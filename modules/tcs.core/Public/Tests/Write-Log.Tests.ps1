BeforeAll {
	$TestPath = Split-Path -Parent -Path $PSScriptRoot

	$FunctionFileName = (Split-Path -Leaf $PSCommandPath ) -replace '\.Tests\.', '.'

	# You can use this Variable to call your function via it's name or ignore/remove as required
	$FunctionName = $FunctionFileName.Replace('.ps1', '')
	
	. $(Join-Path -Path $TestPath -ChildPath $FunctionFileName)
}
Describe -Name "Performing basic validation test on function $FunctionFileName" {
	It "Should format message with timestamp and level" {
		$tempFile = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath "write-log-test-$(New-Guid).log"
		try {
			Write-Log -Message "Test message" -Level Info -LogPath $tempFile -NoConsole
			$content = Get-Content -Path $tempFile -Raw
			$content | Should -Match '^\[.+\]\[Info\] Test message'
		}
		finally {
			if (Test-Path $tempFile) { Remove-Item $tempFile -Force }
		}
	}

	It "Should write to file when LogPath specified" {
		$tempFile = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath "write-log-test-$(New-Guid).log"
		try {
			Write-Log -Message "File test" -LogPath $tempFile -NoConsole
			Test-Path $tempFile | Should -BeTrue
			$content = Get-Content -Path $tempFile
			$content | Should -Not -BeNullOrEmpty
		}
		finally {
			if (Test-Path $tempFile) { Remove-Item $tempFile -Force }
		}
	}

	It "Should include component prefix when specified" {
		$tempFile = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath "write-log-test-$(New-Guid).log"
		try {
			Write-Log -Message "Component test" -Component "MyModule" -LogPath $tempFile -NoConsole
			$content = Get-Content -Path $tempFile -Raw
			$content | Should -Match '\[MyModule\]'
		}
		finally {
			if (Test-Path $tempFile) { Remove-Item $tempFile -Force }
		}
	}

	It "Should handle pipeline input" {
		$tempFile = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath "write-log-test-$(New-Guid).log"
		try {
			"Message1", "Message2", "Message3" | Write-Log -LogPath $tempFile -NoConsole
			$lines = Get-Content -Path $tempFile
			$lines.Count | Should -Be 3
			$lines[0] | Should -Match 'Message1'
			$lines[1] | Should -Match 'Message2'
			$lines[2] | Should -Match 'Message3'
		}
		finally {
			if (Test-Path $tempFile) { Remove-Item $tempFile -Force }
		}
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
