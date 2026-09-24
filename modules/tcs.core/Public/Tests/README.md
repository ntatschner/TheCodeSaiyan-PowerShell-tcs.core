# tcs.core Public/Tests

Pester 5 tests, one `<Function>.Tests.ps1` per public function. Tests import the module and
set `TCS_CONFIG_ROOT` to `$TestDrive` so the real user profile is never touched.
