#Requires -Version 7.2

Function Out-Markdown
{
	[Alias('ConvertFrom-Markdown')]
	[OutputType([String[]])]
	Param(
		[Alias('Content')]
		[Parameter(Mandatory, Position=0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
		[String[]] $InputObject,

		[UInt] $DelimiterWidth = 70
	)

	# Handle code blocks.
	$InputObject = (Format-CodeBlocks $InputObject -DelimiterWidth $DelimiterWidth)
	
	# Handle headers
	$InputObject = (Format-Headers $InputObject)

	# Handle images
	$InputObject = (Format-Images $InputObject -DelimiterWidth $DelimiterWidth)

	# Handle <hr> HTML tags.
	$InputObject = (Format-HorizontalLine $InputObject -DelimiterWidth $DelimiterWidth)

	# Handle links
	$InputObject = $InputObject -Replace "\[([^\]]+)\]\(([^\)]+)\)","`e[4m`$1`e[24m <`$2>"

	# Handle code
	$InputObject = $InputObject -Replace "``([^``]+)``", "`e[7m`$1`e[27m"

	# Handle bold text
	$InputObject = $InputObject -Replace "\*\*([^\r\n]+)\*\*", "`e[1m`$1`e[22m" `
								-Replace "__([^\r\n]+)__",     "`e[1m`$1`e[22m"
	
	# Handle italic text
	$InputObject = $InputObject -Replace "\*([^\r\n\*]+)\*", "`e[4m`$1`e[24m" `
								-Replace "_([^\r\n_]+)_",    "`e[4m`$1`e[24m"

	Return $InputObject
}

Function Format-CodeBlocks
{
	[CmdletBinding()]
	[OutputType([String[]])]
	Param(
		[Parameter(Mandatory, Position=0)]
		[AllowNull()]
		[String[]] $InputObject,

		[UInt] $DelimiterWidth = 70
	)

	$retval      = [String[]]@()
	$codeBlockOn = $false
	$lineNum     = 1
	$languageTag = ''
	ForEach ($line in ($InputObject -Split "\r?\n"))
	{
		Write-Debug "LINE IN: $line"
		If (-Not $codeBlockOn  -and  $line -Match "``{3,4}([^\s]*)")
		{
			$line = $null

			# If we specified a language tag for this code block,
			# then present it to the user as a header.
			$languageTag = (${Matches}?[1]).Trim()

			If ($null -ne $languageTag -and $languageTag.Length -gt 0)
			{
				$line = '───' + `
					$('─' * ($DelimiterWidth - $languageTag.Length - 8)) `
					+ "┤$languageTag├───"
			}
			Else
			{
				$line = $('─' * $DelimiterWidth)
			}
			$codeBlockOn = $true
			$lineNum = 1
		}
		ElseIf ($CodeBlockOn -and ($line -eq '```' -or $line -eq '````'))
		{
			$line = $('─' * $DelimiterWidth)
			$codeBlockOn = $false
			$languageTag = ''
		}
		ElseIf ($CodeBlockOn) {
			$line = "$lineNum`t$line"
			$lineNum++
		}

		Write-Debug "LINEOUT: $line"
		$retval += $line
	}

	Return ($retval -Join "`r`n")
}

Function Format-Headers
{
	[CmdletBinding()]
	[OutputType([String[]])]
	Param(
		[Parameter(Mandatory, Position=0)]
		[AllowNull()]
		[String[]] $InputObject
	)

	$retval = [String[]]@()

	ForEach ($line in ($InputObject -Split "\r?\n"))
	{
		If ($line -Match "^#{1,6}\s")
		{
			$line = "`e[1m$line`e[22m"
		}
		$retval += $line
	}

	Return ($retval -Join "`r`n")
}

Function Format-Images
{
	[CmdletBinding()]
	[OutputType([String[]])]
	Param(
		[Parameter(Mandatory, Position=0)]
		[AllowNull()]
		[String[]] $InputObject,

		[UInt] $DelimiterWidth = 70
	)

	$retval = [String[]]@()

	ForEach ($line in ($InputObject -Split "\r?\n"))
	{
		# "!\[(.*)]\((.*)(?:\s+`"(.*)`")?\)"
		If ($line -Match "!\[(.*)\]\(([^\s]+)(?:\s+`"(.*)`")?\)")
		{
			Write-Debug "Found image: ALT=$($Matches[1])"
			Write-Debug "Found image: URL=$($Matches[2])"
			Write-Debug "Found image: TIP=$(${Matches}?[3])"			
			$altText = ($Matches[1]).Trim()
			$url     = ($Matches[2]).Trim()
			$tooltip = (${Matches}?[3]).Trim()

			$retval += "───┤Image├───$('─' * ($DelimiterWidth - 13))"
			$retval += $altText
			$retval += "<$url>"
			If ($tooltip) {
				$retval += "($tooltip)"
			}
			$retval += ('─' * $DelimiterWidth)
		}
		Else
		{
			$retval += $line
		}
	}

	Return ($retval -Join "`r`n")
}

Function Format-HorizontalLine
{
	[OutputType([String[]])]
	Param(
		[Parameter(Mandatory, Position=0)]
		[AllowNull()]
		[String[]] $InputObject,

		[UInt] $DelimiterWidth = 70
	)

	$retval = [String[]]@()

	ForEach ($line in ($InputObject -Split "\r?\n"))
	{
		If ($line -Match "<hr\s*(?:width=`"(\d+)%`")?/?>")
		{
			$width = (${Matches}?[1]) ?? 100
			$width /= 100
			$retval += ('─' * ($DelimiterWidth * $width))
		}
		Else
		{
			$retval += $line
		}
	}

	Return ($retval -Join "`r`n")
}