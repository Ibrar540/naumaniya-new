# Test Authentication API Endpoints

$baseUrl = "https://naumaniya-new.vercel.app"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Testing Authentication API" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Test 1: Health Check
Write-Host "Test 1: Health Check..." -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "$baseUrl/health" -Method Get
    Write-Host "✅ Health check passed" -ForegroundColor Green
    Write-Host "Response: $($response | ConvertTo-Json)" -ForegroundColor Gray
} catch {
    Write-Host "❌ Health check failed: $_" -ForegroundColor Red
}
Write-Host ""

# Test 2: Signup
Write-Host "Test 2: User Signup..." -ForegroundColor Yellow
$signupData = @{
    name = "testuser_$(Get-Random -Maximum 9999)"
    password = "test123456"
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri "$baseUrl/auth/signup" -Method Post -Body $signupData -ContentType "application/json"
    Write-Host "✅ Signup successful" -ForegroundColor Green
    Write-Host "User: $($response.user.name)" -ForegroundColor Gray
    Write-Host "Role: $($response.user.role)" -ForegroundColor Gray
    $token = $response.token
    Write-Host "Token: $($token.Substring(0, 20))..." -ForegroundColor Gray
} catch {
    Write-Host "❌ Signup failed: $_" -ForegroundColor Red
    $token = $null
}
Write-Host ""

# Test 3: Login with default admin
Write-Host "Test 3: Admin Login..." -ForegroundColor Yellow
$loginData = @{
    name = "admin"
    password = "admin123"
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri "$baseUrl/auth/login" -Method Post -Body $loginData -ContentType "application/json"
    Write-Host "✅ Login successful" -ForegroundColor Green
    Write-Host "User: $($response.user.name)" -ForegroundColor Gray
    Write-Host "Role: $($response.user.role)" -ForegroundColor Gray
    $adminToken = $response.token
    Write-Host "Token: $($adminToken.Substring(0, 20))..." -ForegroundColor Gray
} catch {
    Write-Host "❌ Login failed: $_" -ForegroundColor Red
    Write-Host "Note: Make sure database schema is applied!" -ForegroundColor Yellow
    $adminToken = $null
}
Write-Host ""

# Test 4: Get current user (if we have a token)
if ($token) {
    Write-Host "Test 4: Get Current User..." -ForegroundColor Yellow
    try {
        $headers = @{
            "Authorization" = "Bearer $token"
        }
        $response = Invoke-RestMethod -Uri "$baseUrl/auth/me" -Method Get -Headers $headers
        Write-Host "✅ Get user successful" -ForegroundColor Green
        Write-Host "User: $($response.user | ConvertTo-Json)" -ForegroundColor Gray
    } catch {
        Write-Host "❌ Get user failed: $_" -ForegroundColor Red
    }
    Write-Host ""
}

# Test 5: Protected AI Query (if we have a token)
if ($token) {
    Write-Host "Test 5: Protected AI Query..." -ForegroundColor Yellow
    $queryData = @{
        message = "Total income of masjid in 2026"
    } | ConvertTo-Json
    
    try {
        $headers = @{
            "Authorization" = "Bearer $token"
            "Content-Type" = "application/json"
        }
        $response = Invoke-RestMethod -Uri "$baseUrl/ai-query" -Method Post -Body $queryData -Headers $headers
        Write-Host "✅ AI Query successful" -ForegroundColor Green
        Write-Host "Response: $($response.content)" -ForegroundColor Gray
    } catch {
        Write-Host "❌ AI Query failed: $_" -ForegroundColor Red
    }
    Write-Host ""
}

# Test 6: Admin endpoints (if we have admin token)
if ($adminToken) {
    Write-Host "Test 6: Get All Users (Admin)..." -ForegroundColor Yellow
    try {
        $headers = @{
            "Authorization" = "Bearer $adminToken"
        }
        $response = Invoke-RestMethod -Uri "$baseUrl/auth/admin/users" -Method Get -Headers $headers
        Write-Host "✅ Get users successful" -ForegroundColor Green
        Write-Host "Total users: $($response.users.Count)" -ForegroundColor Gray
    } catch {
        Write-Host "❌ Get users failed: $_" -ForegroundColor Red
    }
    Write-Host ""
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Testing Complete!" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "1. If tests failed, check Vercel deployment logs" -ForegroundColor White
Write-Host "2. Ensure database schema is applied in Neon" -ForegroundColor White
Write-Host "3. Set JWT_SECRET environment variable in Vercel" -ForegroundColor White
Write-Host "4. Change default admin password!" -ForegroundColor White
Write-Host ""
