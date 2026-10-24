# ==============================================================================
# Resume Doctor — Local Server & Gemini API Backend Proxy
# ==============================================================================
$port = 8080
$listener = New-Object System.Net.HttpListener
$prefix = "http://localhost:$port/"
$listener.Prefixes.Add($prefix)

try {
    $listener.Start()
    Write-Output "RESUME_DOCTOR_SERVER_READY: http://localhost:$port/"
} catch {
    $port = 3000
    $prefix = "http://localhost:$port/"
    $listener = New-Object System.Net.HttpListener
    $listener.Prefixes.Add($prefix)
    $listener.Start()
    Write-Output "RESUME_DOCTOR_SERVER_READY: http://localhost:$port/"
}

$baseDir = Split-Path -Parent $MyInvocation.MyCommand.Path

function Send-JsonResponse($response, $statusCode, $obj) {
    $json = ConvertTo-Json -InputObject $obj -Depth 10 -Compress
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($json)
    $response.StatusCode = $statusCode
    $response.ContentType = "application/json; charset=utf-8"
    $response.ContentLength64 = $bytes.Length
    $response.OutputStream.Write($bytes, 0, $bytes.Length)
    $response.OutputStream.Close()
}

while ($listener.IsListening) {
    try {
        $context = $listener.GetContext()
        $request = $context.Request
        $response = $context.Response

        # CORS Headers
        $response.AddHeader("Access-Control-Allow-Origin", "*")
        $response.AddHeader("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        $response.AddHeader("Access-Control-Allow-Headers", "Content-Type, x-gemini-api-key, Authorization")

        # Handle Preflight OPTIONS
        if ($request.HttpMethod -eq "OPTIONS") {
            $response.StatusCode = 200
            $response.OutputStream.Close()
            continue
        }

        $urlPath = $request.Url.LocalPath

        # ----------------------------------------------------------------------
        # Backend API Proxy: /api/analyze
        # ----------------------------------------------------------------------
        if ($urlPath -eq "/api/analyze" -and $request.HttpMethod -eq "POST") {
            $reader = New-Object System.IO.StreamReader($request.InputStream, $request.ContentEncoding)
            $bodyText = $reader.ReadToEnd()
            $body = $null
            try {
                $body = ConvertFrom-Json $bodyText
            } catch {
                Send-JsonResponse $response 400 @{ error = "Invalid JSON request payload." }
                continue
            }

            # Retrieve API key: 1) Header, 2) Environment Variable
            $apiKey = $request.Headers["x-gemini-api-key"]
            if ([string]::IsNullOrWhiteSpace($apiKey)) {
                $apiKey = $env:GEMINI_API_KEY
            }

            if ([string]::IsNullOrWhiteSpace($apiKey)) {
                Send-JsonResponse $response 400 @{
                    error = "No API key provided. Set `$env:GEMINI_API_KEY on the server or enter your API key in Settings."
                }
                continue
            }

            $model = if ($body.model) { $body.model } else { "gemini-2.0-flash" }
            $prompt = $body.prompt

            if ([string]::IsNullOrWhiteSpace($prompt)) {
                Send-JsonResponse $response 400 @{ error = "Missing 'prompt' in request body." }
                continue
            }

            # Construct Gemini API Request
            $geminiEndpoint = "https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${apiKey}"

            $parts = New-Object System.Collections.ArrayList
            if ($body.imageBase64) {
                $mime = if ($body.imageMime) { $body.imageMime } else { "image/jpeg" }
                [void]$parts.Add(@{
                    inlineData = @{
                        mimeType = $mime
                        data = $body.imageBase64
                    }
                })
            }
            [void]$parts.Add(@{ text = $prompt })

            $genConfig = @{ temperature = 0.2 }
            if ($model.StartsWith("gemini")) {
                $genConfig["responseMimeType"] = "application/json"
            }

            $payload = @{
                contents = @( @{ parts = $parts } )
                generationConfig = $genConfig
            }
            $payloadJson = ConvertTo-Json -InputObject $payload -Depth 10

            try {
                $webReq = [System.Net.HttpWebRequest]::Create($geminiEndpoint)
                $webReq.Method = "POST"
                $webReq.ContentType = "application/json"
                $webReq.Timeout = 45000 # 45s timeout
                
                $pBytes = [System.Text.Encoding]::UTF8.GetBytes($payloadJson)
                $webReq.ContentLength = $pBytes.Length
                $reqStream = $webReq.GetRequestStream()
                $reqStream.Write($pBytes, 0, $pBytes.Length)
                $reqStream.Close()

                $webResp = $webReq.GetResponse()
                $respStream = $webResp.GetResponseStream()
                $respReader = New-Object System.IO.StreamReader($respStream)
                $geminiRaw = $respReader.ReadToEnd()
                $respReader.Close()
                $webResp.Close()

                $geminiData = ConvertFrom-Json $geminiRaw
                $candidateText = $geminiData.candidates[0].content.parts[0].text

                Send-JsonResponse $response 200 @{
                    success = $true
                    model = $model
                    rawText = $candidateText
                }
            } catch [System.Net.WebException] {
                $webEx = $_.Exception
                $status = 500
                $msg = $webEx.Message
                if ($webEx.Response) {
                    $errResp = $webEx.Response
                    $status = [int]$errResp.StatusCode
                    $errStream = $errResp.GetResponseStream()
                    $errReader = New-Object System.IO.StreamReader($errStream)
                    $errBody = $errReader.ReadToEnd()
                    $errReader.Close()

                    try {
                        $parsedErr = ConvertFrom-Json $errBody
                        if ($parsedErr.error.message) {
                            $msg = $parsedErr.error.message
                        }
                    } catch {}
                }

                if ($status -eq 429) {
                    $msg = "Gemini API rate limit reached (429). Please wait a few seconds or switch to Built-in Engine."
                } elseif ($status -eq 400 -or $status -eq 403) {
                    $msg = "API Key Error ($status): $msg"
                }

                Send-JsonResponse $response $status @{
                    error = $msg
                    statusCode = $status
                }
            } catch {
                Send-JsonResponse $response 500 @{ error = $_.Exception.Message }
            }
            continue
        }

        # ----------------------------------------------------------------------
        # Backend API: /api/test-key
        # ----------------------------------------------------------------------
        if ($urlPath -eq "/api/test-key" -and $request.HttpMethod -eq "POST") {
            $apiKey = $request.Headers["x-gemini-api-key"]
            if ([string]::IsNullOrWhiteSpace($apiKey)) {
                $apiKey = $env:GEMINI_API_KEY
            }

            if ([string]::IsNullOrWhiteSpace($apiKey)) {
                Send-JsonResponse $response 400 @{ error = "No API key provided." }
                continue
            }

            $testUrl = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=${apiKey}"
            try {
                $webReq = [System.Net.HttpWebRequest]::Create($testUrl)
                $webReq.Method = "POST"
                $webReq.ContentType = "application/json"
                $webReq.Timeout = 10000
                $testBody = '{"contents":[{"parts":[{"text":"ping"}]}]}'
                $b = [System.Text.Encoding]::UTF8.GetBytes($testBody)
                $webReq.ContentLength = $b.Length
                $s = $webReq.GetRequestStream()
                $s.Write($b, 0, $b.Length)
                $s.Close()
                $r = $webReq.GetResponse()
                $r.Close()
                Send-JsonResponse $response 200 @{ success = $true; message = "API Key is valid!" }
            } catch [System.Net.WebException] {
                $status = 500
                $msg = $_.Exception.Message
                if ($_.Exception.Response) {
                    $status = [int]$_.Exception.Response.StatusCode
                    $s = $_.Exception.Response.GetResponseStream()
                    $sr = New-Object System.IO.StreamReader($s)
                    $msg = $sr.ReadToEnd()
                    $sr.Close()
                }
                Send-JsonResponse $response $status @{ error = $msg; statusCode = $status }
            } catch {
                Send-JsonResponse $response 500 @{ error = $_.Exception.Message }
            }
            continue
        }

        # ----------------------------------------------------------------------
        # Static Files Serving
        # ----------------------------------------------------------------------
        if ($urlPath -eq "/" -or [string]::IsNullOrWhiteSpace($urlPath)) {
            $urlPath = "/index.html"
        }

        $cleanPath = $urlPath.TrimStart('/').Replace('/', '\')
        $filePath = Join-Path $baseDir $cleanPath

        if (Test-Path $filePath -PathType Leaf) {
            $bytes = [System.IO.File]::ReadAllBytes($filePath)
            if ($filePath.EndsWith(".html")) {
                $response.ContentType = "text/html; charset=utf-8"
            } elseif ($filePath.EndsWith(".js")) {
                $response.ContentType = "application/javascript; charset=utf-8"
            } elseif ($filePath.EndsWith(".css")) {
                $response.ContentType = "text/css; charset=utf-8"
            } elseif ($filePath.EndsWith(".txt") -or $filePath.EndsWith(".md")) {
                $response.ContentType = "text/plain; charset=utf-8"
            } elseif ($filePath.EndsWith(".svg")) {
                $response.ContentType = "image/svg+xml"
            } elseif ($filePath.EndsWith(".zip")) {
                $response.ContentType = "application/zip"
            }
            $response.ContentLength64 = $bytes.Length
            $response.OutputStream.Write($bytes, 0, $bytes.Length)
        } else {
            $response.StatusCode = 404
            $errBytes = [System.Text.Encoding]::UTF8.GetBytes("File Not Found")
            $response.ContentLength64 = $errBytes.Length
            $response.OutputStream.Write($errBytes, 0, $errBytes.Length)
        }
        $response.OutputStream.Close()
    } catch {
        # continue loop
    }
}
