# Deployment Guide - Productivity MCP Server

This guide covers deploying the Go MCP server to production on various platforms.

## Pre-Deployment Checklist

- [ ] Supabase project created and configured
- [ ] Supabase credentials obtained
- [ ] Claude API key obtained
- [ ] Environment variables documented
- [ ] Binary tested locally
- [ ] Docker image built and tested (if using Docker)

## Deployment Options

### Option 1: Railway (Recommended - Easiest)

Railway is the easiest way to deploy the MCP server with automatic scaling and monitoring.

#### Steps:

1. **Push to GitHub**
   ```bash
   git init
   git add .
   git commit -m "Initial commit"
   git remote add origin https://github.com/yourusername/productivity-mcp-server.git
   git push -u origin main
   ```

2. **Connect to Railway**
   - Go to [railway.app](https://railway.app)
   - Click "New Project"
   - Select "Deploy from GitHub"
   - Choose your repository
   - Authorize Railway to access GitHub

3. **Configure Environment Variables**
   - In Railway dashboard, go to Variables
   - Add the following:
     ```
     SUPABASE_URL=https://your-project.supabase.co
     SUPABASE_ANON_KEY=your-anon-key
     CLAUDE_API_KEY=sk-ant-your-api-key
     PORT=8000
     GIN_MODE=release
     ```

4. **Deploy**
   - Railway automatically detects Go project
   - Sets build command: `go build -o server .`
   - Sets start command: `./server`
   - Click "Deploy"

5. **Get Your URL**
   - Once deployed, Railway provides a public URL
   - Use this URL to connect Claude to your MCP server

### Option 2: Render

Render offers free tier with automatic deployments.

#### Steps:

1. **Push to GitHub** (same as Railway)

2. **Create Web Service**
   - Go to [render.com](https://render.com)
   - Click "New +"
   - Select "Web Service"
   - Connect your GitHub repository

3. **Configure**
   - **Name**: `productivity-mcp-server`
   - **Environment**: `Go`
   - **Build Command**: `go build -o server .`
   - **Start Command**: `./server`
   - **Plan**: Free (or Starter for production)

4. **Add Environment Variables**
   - In the "Environment" section, add:
     ```
     SUPABASE_URL=https://your-project.supabase.co
     SUPABASE_ANON_KEY=your-anon-key
     CLAUDE_API_KEY=sk-ant-your-api-key
     GIN_MODE=release
     ```

5. **Deploy**
   - Click "Create Web Service"
   - Render automatically deploys on every push to main

### Option 3: Fly.io

Fly.io offers global deployment with edge computing.

#### Steps:

1. **Install Fly CLI**
   ```bash
   curl -L https://fly.io/install.sh | sh
   ```

2. **Login to Fly**
   ```bash
   flyctl auth login
   ```

3. **Launch App**
   ```bash
   flyctl launch
   ```
   - Choose app name
   - Choose region (closest to your users)
   - Skip database setup

4. **Set Environment Variables**
   ```bash
   flyctl secrets set SUPABASE_URL="https://your-project.supabase.co"
   flyctl secrets set SUPABASE_ANON_KEY="your-anon-key"
   flyctl secrets set CLAUDE_API_KEY="sk-ant-your-api-key"
   flyctl secrets set GIN_MODE="release"
   ```

5. **Deploy**
   ```bash
   flyctl deploy
   ```

6. **Get URL**
   ```bash
   flyctl info
   ```

### Option 4: Docker + Your Own Server

For maximum control, deploy Docker to your own VPS.

#### Steps:

1. **Build Docker Image**
   ```bash
   docker build -t productivity-mcp-server:latest .
   ```

2. **Push to Docker Registry**
   ```bash
   docker tag productivity-mcp-server:latest yourusername/productivity-mcp-server:latest
   docker push yourusername/productivity-mcp-server:latest
   ```

3. **On Your VPS**
   ```bash
   docker run -d \
     --name productivity-mcp \
     -p 8000:8000 \
     -e SUPABASE_URL="https://your-project.supabase.co" \
     -e SUPABASE_ANON_KEY="your-anon-key" \
     -e CLAUDE_API_KEY="sk-ant-your-api-key" \
     -e GIN_MODE="release" \
     yourusername/productivity-mcp-server:latest
   ```

4. **Set Up Reverse Proxy (Nginx)**
   ```nginx
   server {
       listen 80;
       server_name api.productivity.example.com;

       location / {
           proxy_pass http://localhost:8000;
           proxy_set_header Host $host;
           proxy_set_header X-Real-IP $remote_addr;
           proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
           proxy_set_header X-Forwarded-Proto $scheme;
       }
   }
   ```

5. **Enable HTTPS (Let's Encrypt)**
   ```bash
   certbot --nginx -d api.productivity.example.com
   ```

### Option 5: AWS Lambda (Serverless)

For ultra-low cost with minimal traffic.

#### Steps:

1. **Build for Lambda**
   ```bash
   GOOS=linux GOARCH=amd64 go build -o bootstrap .
   zip function.zip bootstrap
   ```

2. **Create Lambda Function**
   - Go to AWS Lambda console
   - Create new function
   - Upload `function.zip`
   - Set handler to `bootstrap`

3. **Add API Gateway**
   - Create API Gateway trigger
   - Configure routes to forward to Lambda

4. **Set Environment Variables**
   - In Lambda configuration, add environment variables

## Post-Deployment

### 1. Test the Deployment

```bash
curl https://your-deployed-server/health
```

Should return:
```json
{
  "status": "ok",
  "service": "productivity-mcp-server"
}
```

### 2. Test MCP Endpoints

```bash
curl -X POST https://your-deployed-server/mcp/initialize
```

### 3. Connect Claude

**Claude Desktop:**
1. Go to Settings → Developer
2. Add MCP Server:
```json
{
  "mcpServers": {
    "productivity": {
      "command": "curl",
      "args": ["https://your-deployed-server/mcp/initialize"],
      "env": {}
    }
  }
}
```

**Claude iOS:**
- Add server URL in settings

**Web Claude:**
- Add server URL in settings

### 4. Monitor Deployment

#### Railway
- Dashboard shows logs and metrics
- Automatic scaling based on traffic
- Alerts for errors

#### Render
- Logs available in dashboard
- Email alerts for failures
- Automatic restarts on crash

#### Fly.io
```bash
flyctl logs
flyctl status
flyctl metrics
```

## Scaling Considerations

### For Small Teams (< 100 users)
- Railway/Render free tier is sufficient
- Single instance handles thousands of requests/day
- 11MB binary uses minimal resources

### For Growing Teams (100-1000 users)
- Upgrade to paid tier
- Enable auto-scaling
- Add monitoring and alerting
- Consider database connection pooling

### For Enterprise (1000+ users)
- Deploy to multiple regions
- Use load balancing
- Implement caching (Redis)
- Add comprehensive logging (DataDog, New Relic)
- Set up CI/CD pipeline

## Security Best Practices

1. **Environment Variables**
   - Never commit secrets to git
   - Use platform-specific secret management
   - Rotate API keys regularly

2. **HTTPS**
   - Always use HTTPS in production
   - Use Let's Encrypt for free certificates
   - Set HSTS headers

3. **CORS**
   - Restrict CORS origins in production
   - Update `middleware/cors.go` to limit allowed origins

4. **Rate Limiting**
   - Implement rate limiting for API endpoints
   - Prevent abuse and DDoS attacks

5. **Logging**
   - Log all requests and errors
   - Monitor for suspicious activity
   - Set up alerts for errors

## Troubleshooting Deployment

### Server won't start
```bash
# Check logs
flyctl logs  # Fly.io
# or check Railway/Render dashboard

# Common issues:
# - Missing environment variables
# - Port already in use
# - Database connection failed
```

### High latency
```bash
# Check server metrics
# - CPU usage
# - Memory usage
# - Database query times

# Solutions:
# - Upgrade to larger instance
# - Add caching
# - Optimize database queries
```

### Connection refused
```bash
# Verify server is running
curl https://your-server/health

# Check firewall rules
# Verify domain DNS is correct
```

## Updating Deployment

### Railway/Render
- Automatic on git push to main
- No manual steps needed

### Fly.io
```bash
git push
flyctl deploy
```

### Docker
```bash
docker build -t productivity-mcp-server:latest .
docker push yourusername/productivity-mcp-server:latest
# On server: docker pull and restart
```

## Cost Estimates (Monthly)

| Platform | Free Tier | Starter | Pro |
|----------|-----------|---------|-----|
| Railway | $5 credit | $5+ | Custom |
| Render | Free | $7+ | Custom |
| Fly.io | Free | $3+ | Custom |
| AWS Lambda | 1M requests | Pay per use | Custom |

## Next Steps

1. Choose a deployment platform
2. Follow the steps for your chosen platform
3. Test the deployment
4. Connect Claude to your server
5. Monitor logs and metrics
6. Set up alerts for errors

For questions or issues, check the troubleshooting section or open an issue on GitHub.
